function Remove-HPOVLdapServer
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'PSCredential')]
		[Alias ('Directory')]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'PSCredential')]
		[ValidateNotNullorEmpty()]
		[Alias ('Name')]
		[String]$DirectoryServerName,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('u','user')]
		[String]$Username,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('p','pass')]
		[Object]$Password,

		[Parameter (Mandatory, ParameterSetName = "PSCredential")]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential,

		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = 'PSCredential')]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection

	)

	Begin 
	{

		if ($PSBoundParameters['Username'])
		{

			Write-Warning "The -Username parameter will be deprecated in a future release. Please transition to using the -Credental Parameter."
			
		}

		if ($PSBoundParameters['Password'])
		{

			Write-Warning "The -Username parameter will be deprecated in a future release. Please transition to using the -Credental Parameter."

		}

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $InputObject) 
		{

			$PipelineINput = $true

		}

		else
		{

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

		}

		if (-not($PSBoundParameters['Password']) -and $PSBoundParameters['Username'])
		{

			do 
			{
				
				$securepass   = Read-Host 'Password' -AsSecureString
				$securepass2  = Read-Host 'Confirm Password' -AsSecureString
				$_DecryptPassword  = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepass))
				$_DecryptPassword2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepass2))

				if ($_DecryptPassword -ne $_DecryptPassword2)
				{

					Write-Host "Passwords do not match!" -BackgroundColor Red

				}

			} until ($_DecryptPassword -eq $_DecryptPassword2)
			
		}

		elseif ($Password -is [SecureString])
		{

			$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

		}

		elseif ($PSBoundParameters['Password'])
		{

			$_DecryptPassword = $Password

		}

		elseif ($PSBoundParameters['Credential'])
		{

			$Username = $Credential.Username
			$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

		}

		else
		{

			$ExceptionMessage = 'Please provide valid credentials using either -Username/-Password or -Credential parameters.'
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.LdapAuthenticationException NoValidCredentialParameters AuthenticationError "ApplianceConnection" -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}
		
	}

	Process 
	{

		if ($PipelineInput -or $InputObject -is [PSCustomObject]) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		"[{0}] LdapDirectory Object provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($InputObject | Format-List *) | Write-Verbose

		If ('users' -contains $InputObject.category)
		{

			If (-not($InputObject.ApplianceConnection))
			{

				$ExceptionMessage = "The InputObject parameter value resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else
		{

			$ExceptionMessage = "The Group object resource is not an expected category type [{0}].  The allowed resource category type is 'users'.  Please check the object provided and try again." -f $InputObject.category
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Add credentials to object
		if ($InputObject.directoryBindingType -eq $LdapDirectoryAccountBindTypeEnum['USERACCOUNT'])
		{

			$InputObject.credential = @{ userName = $Username; password = $_DecryptPassword }

		}

		else
		{

			$InputObject.credential.userName = $Username
			$InputObject.credential.password = $_DecryptPassword

		}	

		$PromptMessage = "remove directory server '{0}'" -f $DirectoryServerName

		if ($PSCmdlet.ShouldProcess($InputObject.ApplianceConnection.Name,$PromptMessage)) 
		{

			"[{0}] Removing Directory Server '{1}' from LDAP Directory '{2}'." -f $MyInvocation.InvocationName.ToString().ToUpper(),$DirectoryServerName, $InputObject.name | Write-Verbose

			Try
			{

				[Array]$InputObject.directoryServers = $InputObject.directoryServers | Where-Object directoryServerIpAddress -ne $DirectoryServerName
				
				$_resp = Send-HPOVRequest -Uri $InputObject.Uri -Method PUT -Body $InputObject -Hostname $InputObject.ApplianceConnection.Name

				$_resp.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AuthDirectory")

				$_resp

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		elseif ($PSBoundParameters['WhatIf'])
		{

			"[{0}] -WhatIf Parameter was passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
