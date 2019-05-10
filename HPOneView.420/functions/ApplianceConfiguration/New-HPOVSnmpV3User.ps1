function New-HPOVSnmpV3User
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[Parameter (Mandatory, ParameterSetName = "ApplianceSnmpUser")]
		[ValidateNotNullOrEmpty()]
		[string]$Username,

		[Parameter (Mandatory, ParameterSetName = "ApplianceSnmpUser")]
		[Switch]$ApplianceSnmpUser,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "ApplianceSnmpUser")]
		[ValidateSet ("None", "AuthOnly","AuthAndPriv")]
		[ValidateNotNullOrEmpty()]
		[string]$SecurityLevel = "None",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "ApplianceSnmpUser")]
		[ValidateSet ('none', "MD5", "SHA", 'SHA1', 'SHA256', 'SHA384', 'SHA512')]	
		[ValidateNotNullOrEmpty()]
		[string]$AuthProtocol = 'none',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "ApplianceSnmpUser")]
		[ValidateNotNullOrEmpty()]
		[SecureString]$AuthPassword,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "ApplianceSnmpUser")]
		[ValidateSet ('none', "des56", '3des', 'aes128', 'aes192', 'aes256')]	
		[ValidateNotNullOrEmpty()]
		[string]$PrivProtocol = 'none',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "ApplianceSnmpUser")]
		[ValidateNotNullOrEmpty()]
		[SecureString]$PrivPassword,

		[Parameter (Mandatory = $False, ParameterSetName = "ApplianceSnmpUser")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($PSCmdlet.ParameterSetName -eq 'ApplianceSnmpUser') 
		{

			"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if (-not($ApplianceConnection) -and -not(${Global:ConnectedSessions}))
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command again."
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

		$_CredentialsCol = New-Object System.Collections.ArrayList

		if ($SecurityLevel -eq "AuthOnly" -and 
			($AuthPassword)) 
		{

			# Generate Terminateing error
			$ExceptionMessage = "The -SecurityLevel Parameter was set to 'AuthOnly', but did not include -AuthPassword Parameter.  An AuthPassword is required."
			$ErrorRecord = New-ErrorRecord HPOneView.SanManagerResourceException MissingRequiredParameters InvalidArgument 'SecurityLevel' Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($SecurityLevel -eq "AuthAndPriv" -and (
			-not $AuthPassword -or 
			-not $PrivPassword )) 
		{

			# Generate Terminateing error
			$ExceptionMessage = "The -SecurityLevel Parameter was set to 'AuthAndPriv', but did not include -AuthPassword and/or -PrivPassword Parameters."
			$ErrorRecord = New-ErrorRecord HPOneView.SanManagerResourceException MissingRequiredParameters InvalidArgument 'SecurityLevel' Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
		}

	}

	Process
	{

		if ($PSBoundParameters['AuthPassword'])
		{

			$_DecryptAuthPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AuthPassword))

		}

		if ($PSBoundParameters['PrivPassword'])
		{

			$_DecryptPrivPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PrivPassword))

		}

		if (-not $ApplianceSnmpUser)
		{

			if ($SecurityLevel -ne "None")
			{

				if ($PSBoundParameters['AuthPassword'])
				{

					'[{0}] Adding Auth Password' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_DecryptAuthPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AuthPassword))
					$_AuthPasswordConnectionAttributes = New-Object HPOneView.Library.GenericAttributes('SnmpV3AuthorizationPassword', $_DecryptAuthPassword, 'SecuritySensitive')

					[void]$_CredentialsCol.Add($_AuthPasswordConnectionAttributes)

				}

				if ($PSBoundParameters['PrivPassword'])
				{

					'[{0}] Adding Privacy Password' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_DecryptPrivPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PrivPassword))
					$_PrivPasswordConnectionAttributes = New-Object HPOneView.Library.GenericAttributes('SnmpV3PrivacyPassword', $_DecryptAuthPassword, 'SecuritySensitive')

					[void]$_CredentialsCol.Add($_PrivPasswordConnectionAttributes)

				}

			}

			else
			{

				'[{0}] Creating an SNMPv3 user without authentication or privacy password.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			
            New-Object HPOneView.Networking.SnmpV3User ($Username, $_CredentialsCol, $SnmpAuthProtocolEnum[$AuthProtocol], $SnmpPrivProtocolEnum[$PrivProtocol])
			
		}

		else
		{

			$_NewSnmpV3User = New-Object HPOneView.Appliance.SnmpV3User ($Username, 
																		 $Snmpv3UserAuthLevelEnum[$SecurityLevel], 
																		 $SnmpAuthProtocolEnum[$AuthProtocol],
																		 $_DecryptAuthPassword,
																		 $ApplianceSnmpV3PrivProtocolEnum[$PrivProtocol],
																		 $_DecryptPrivPassword)

			ForEach ($_appliance in $ApplianceConnection)
			{

				'[{0}] Adding SNMPv3 User to: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

				Try
				{

					$_resp = Send-HPOVRequest -Uri $ApplianceSnmpV3UsersUri -Method POST -Body $_NewSnmpV3User -Hostname $_appliance

					$_SnmpV3User = New-Object HPOneView.Appliance.SnmpV3User ($_resp.userName, 
																			  $_resp.securityLevel, 
																			  $_resp.authenticationProtocol,
																			  $null,
																			  $_resp.privacyProtocol,
																			  $null,
																			  $_resp.id,
																			  $_resp.uri)

					$_SnmpV3User | Add-Member -NotePropertyName ApplianceConnection -NotePropertyValue $_resp.ApplianceConnection

					$_SnmpV3User

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

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
