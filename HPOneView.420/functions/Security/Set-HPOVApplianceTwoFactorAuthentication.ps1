function Set-HPOVApplianceTwoFactorAuthentication
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
		
	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[bool]$SmartCardLoginOnly,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[bool]$EnableEmergencyLocalLogin,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateSet ('ApplianceConsoleOnly', 'NetworkAndApplianceConsole')]
		[string]$EmergencyLoginAllowType,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Array]$SubjectAlternativeNamePatterns,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[String]$SubjectPatterns,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Array]$ValidationOids = @(@{"1.3.6.1.4.1.311.20.2.2" = "Smart Card Logon"; "1.3.6.1.5.5.7.3.2" = "Client Authentication"}),

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateSet ('Subject', 'SubjectAlternativeName', 'Issuer', 'Manual')]
		[String]$DirectoryDomainType = 'Subject',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[String]$DirectoryDomain = 'DC=(.*)',

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
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
		
	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Try
			{

				"[{0}] Getting Global Auth settings from appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_CurrentAuthn2FAConfig = Send-HPOVRequest -Uri $AuthnSettingsUri -Hostname $_appliance.Name

				$_Current2FALoginCertConfig = Send-HPOVRequest -Uri $Authn2FALoginCertificateConfigUri -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

            "[{0}] 2FA is enabled on the appliance: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_CurrentAuthn2FAConfig.twoFactorAuthenticationEnabled.ToString() | Write-Verbose

			if (-not $_CurrentAuthn2FAConfig.twoFactorAuthenticationEnabled)
			{

				"[{0}] Will enable 2FA on the appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_CurrentAuthn2FAConfig.twoFactorAuthenticationEnabled = $true

			}

			switch ($PSBoundParameters.Keys)
			{

				'SmartCardLoginOnly'
				{

					if ($SmartCardLoginOnly)
					{

						if ($PSCmdlet.ShouldProcess($_appliance.Name, 'enforce two factor authentication only')) 
						{
		
							"[{0}] Will enable 2FA on the appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							
							$_CurrentAuthn2FAConfig.twoFactorAuthenticationEnabled = $true
							$_CurrentAuthn2FAConfig.allowLocalLogin                = $false
		
						}

					}

					else
					{

						"[{0}] Disabling strict 2FA on the appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_CurrentAuthn2FAConfig.twoFactorAuthenticationEnabled = $false

					}					

				}

				'EnableEmergencyLocalLogin'
				{

					if ($EnableEmergencyLocalLogin)
					{

						"[{0}] Enable Emergency Local Login on the appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						
						$_CurrentAuthn2FAConfig.emergencyLocalLoginEnabled = $true

					}

					else
					{

						"[{0}] Disable Emergency Local Login on the appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						
						$_CurrentAuthn2FAConfig.emergencyLocalLoginEnabled = $false

					}					

				}

				'EmergencyLoginAllowType'
				{

					switch ($EmergencyLoginAllowType)
					{

						'APPLIANCECONSOLEONLY'
						{

							"[{0}] Enable Emergency Local Login via console only on the appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							
							$_CurrentAuthn2FAConfig.emergencyLocalLoginType = $TwoFactorLocalLoginTypeEnum['APPLIANCECONSOLEONLY']

						}

						'NETWORKANDAPPLIANCECONSOLE'
						{

							"[{0}] Enable Emergency Local Login via console only on the appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							
							$_CurrentAuthn2FAConfig.emergencyLocalLoginType = $TwoFactorLocalLoginTypeEnum['NETWORKANDAPPLIANCECONSOLE']

						}

					}

				}

				'SubjectAlternativeNamePatterns'
				{

					"[{0}] Setting SAN pattern values on the appliance to {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [String]::Join(', ', $SubjectAlternativeNamePatterns.ToArray()) | Write-Verbose

					$_Current2FALoginCertConfig.subjectAlternateNamePatterns = [String]::Join(', ', $SubjectAlternativeNamePatterns.ToArray())

				}

				'SubjectPatterns'
				{

					"[{0}] Setting SAN pattern values on the appliance to {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [String]::Join(', ', $SubjectPatterns.ToArray()) | Write-Verbose

					$_Current2FALoginCertConfig.subjectPatterns = [String]::Join(', ', $SubjectPatterns.ToArray())

				}

				'DirectoryDomainType'
				{

					"[{0}] Setting DirectoryDomainType on the appliance to {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $DirectoryDomainType | Write-Verbose

					$_Current2FALoginCertConfig.certificateDomainIdentifier = $DirectoryDomainType

				}

				'ValidationOids'
				{

					$_ValidationOids = New-Object System.Collections.ArrayList

					ForEach ($e in $ValidationOids)
					{

						[void]$_ValidationOids.Add($e)
						
					}

					"[{0}] Setting ValidationOids on the appliance to {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [String]::Join(', ', $_ValidationOids.ToArray()) | Write-Verbose
					
					$_Current2FALoginCertConfig.validationOids = $_ValidationOids

				}

				'DirectoryDomain'
				{

					"[{0}] Setting Directory Domain Identifier Pattern on the appliance to {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $DirectoryDomain | Write-Verbose

					$_Current2FALoginCertConfig.certificateDomainIdentifierPattern = $DirectoryDomain

				}

			}

			# Update Appliance Authn Glboal Settings

			Try
			{

				Send-HPOVRequest -Uri $AuthnSettingsUri -Method PUT -Body $_CurrentAuthn2FAConfig -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# Update LoginCertificateConfigDto
			
			Try
			{

				Send-HPOVRequest -Uri $Authn2FALoginCertificateConfigUri -Method PUT -Body $_Current2FALoginCertConfig -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)
				
			}

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
