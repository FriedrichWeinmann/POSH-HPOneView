function Set-HPOVUserPassword 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Alias ('CurrentPassword')]
		[String]$Current,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Alias ('NewPassword')]
		[String]$New,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose
		
		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection) -and -not(${Global:ConnectedSessions}))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command agian."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif ($ApplianceConnection -is [System.Collections.IEnumerable] -and $ApplianceConnection -isnot [System.String])
		{


			For ([int]$c = 0; $c -lt $ApplianceConnection.Count; $c++) 
			{

				Try 
				{
			
					$ApplianceConnection[$c] = Test-HPOVAuth $ApplianceConnection[$c]

				}

				Catch [HPOneview.Appliance.AuthSessionException] 
				{

					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError $ApplianceConnection[$c].Name -Message $_.Exception.Message -InnerException $_.Exception
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				Catch 
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}


			}

		}

		else
		{

			Try 
			{
			
				$ApplianceConnection = Test-HPOVAuth $ApplianceConnection

			}

			Catch [HPOneview.Appliance.AuthSessionException] 
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError 'ApplianceConnection' -Message $_.Exception.Message -InnerException $_.Exception
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		# Prompt user for current password if not provided
		if (-not($PSBoundParameters['Current'])) 
		{ 
		
			$Current                  = Read-Host -AsSecureString "Current"
			$_decryptCurrentPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Current))

		}

		else 
		{ 
			
			$_decryptCurrentPassword = $Current 
		
		}

		# Prompt user for new password if not provided
		if (-not($PSBoundParameters['New'])) 
		{ 
		
			Do 
			{

				$New                 = Read-Host -AsSecureString "New"
				$_CompareNewPassword = Read-Host -AsSecureString "Re-type New"
				
				# Compare provided password matches
				$_decryptNewPassword        = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($New))
				$_decryptcompareNewPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_CompareNewPassword))

				if (-not ($_decryptNewPassword -eq $_decryptcompareNewPassword))
				{

					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.PasswordMismatchException NewPasswordsDoNotMatch InvalidResult 'New' -Message "The new password values do not match. Please check the value and try again."
					$PSCmdlet.WriteError($ErrorRecord)

				}

				if (-not ($_decryptNewPassword.length -ge 8) -or -not ($_decryptcompareNewPassword -ge 8)) 
				{
				
					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.PasswordMismatchException NewPasswordLengthTooShort InvalidResult 'New' -Message "The new password value do not meet the minimum character length of 8 characters. Please try again."
					$PSCmdlet.WriteError($ErrorRecord)

				}

			} Until ($_decryptNewPassword -eq $_decryptcompareNewPassword -and $_decryptNewPassword.length -ge 8)

		}

		else 
		{

			$_decryptNewPassword = $New

		}

		$_UserStatus = New-Object System.Collections.ArrayList

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			if ($_appliance.AuthLoginDomain -ne 'LOCAL')
			{

				$_message     = "The user account Auth Provider, {0}, is not the local appliance.  HPE OneView does not support updating an LDAP User Account password." -f $_appliance.AuthLoginDomain
				$_errorrecord = New-ErrorRecord HPOneView.Appliance.UserResourceException UserNotFound ObjectNotFound 'UserName' -Message $_message
				$PSCmdlet.WriteError($_errorrecord)

			}

			else
			{

				$_UpdatePassword                 = NewObject -UpdateUserPassword
				$_UpdatePassword.currentPassword = $_decryptCurrentPassword
				$_UpdatePassword.password        = $_decryptNewPassword
				$_UpdatePassword.userName        = $_appliance.UserName

				Try
				{

					$_resp = Send-HPOVRequest $ApplianceUserAccountsUri PUT $_UpdatePassword -Hostname $_appliance

					if ($_resp.category -eq 'users')
					{

						$_resp.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.User')

					}

					[void]$_UserStatus.Add($_resp)

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

		}     

	}

	End 
	{

		Return $_UserStatus

	}

}
