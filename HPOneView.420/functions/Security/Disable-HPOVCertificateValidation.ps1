function Disable-HPOVCertificateValidation
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
		
	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

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
		
		$_uri = $ApplianceCertificateValidatorUri.Clone()
		
		$_Action = 'disable certificate revocation checking'

		Write-Warning 'Communication to devices and servers whose certificates are not checked for revocation is insecure and is subject to man-in-the-middle (MITM) attack. It is strongly recommended that certificate revocation check is not turned off as it poses a serious security risk to the environment.'

		Write-Warning "Diabling certificate revocation checking will require a reboot of the appliance.  Please ensure that other users are not in the middle of operations before continuing."

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			# Need to validate if two-factor authentication is enabled, as certificate validation cannot be disabled
			Try
			{

				"[{0}] Getting current appliance global authentication configuration to check for two-factor auth setting." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				$_ApplianceTwoFactorConfiguration = Send-HPOVRequest -Uri $AuthnSettingsUri -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($_ApplianceTwoFactorConfiguration.twoFactorAuthenticationEnabled)
			{

				"[{0}] Two-factor auth is configured.  Building ErrorRecord." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ExceptionMessage = 'Certificate validation or revocation cannot be disabled as two-factor authentication is enabled.  Turn off two-factor authentication to disable certificate validation or revocation.'
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AuthGlobalSettingException InvalidCertValidationSetting InvalidOperation 'DisableCertVerification' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			elseif ($PSCmdlet.ShouldProcess($_appliance.Name, $_Action)) 
			{

				"[{0}] Two-factor auth is not configured." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] {1} on appliance '{2}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Action, $_appliance.Name | Write-Verbose

				# Get current configuration from appliance
				Try
				{

					$_CurrentCertValidationConfig = Send-HPOVRequest -Uri $_uri -Hostname $_appliance.name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				$_CurrentCertValidationConfig.certValidationConfig.'global.validateCertificate' = $false
				$_CurrentCertValidationConfig.okToReboot = $true

				Try
				{
					
					$_Resp = Send-HPOVRequest -Uri $_uri -Method PUT -Body $_CurrentCertValidationConfig -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				Write-Warning ('Appliance {0} is now rebooting.' -f $_appliance.Name)

			}

			elseif ($PSBoundParameters['WhatIf'])
			{

				"[{0}] WhatIf Parameter was passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
