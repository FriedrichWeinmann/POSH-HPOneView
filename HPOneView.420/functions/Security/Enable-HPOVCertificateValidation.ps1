function Enable-HPOVCertificateValidation
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
		
	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Bool]$CheckForSelfSignedExpiry,

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

		$_Action = 'enable certificate validation'

		if ($PSBoundParameters['CheckForSelfSignedExpiry'])
		{

			Write-Warning 'If you enable expiry checking, while establishing a connection to external devices or servers associated with self-signed certificates, certificate expiry check will be performed and communication with any device that has an expired self-signed certificate will fail.'

			$_Action += ' and check for expiration of self-signed certificates'
		
		}

		Write-Warning "Enabling certificate validation will require a reboot of the appliance.  Please ensure that other users are not in the middle of operations before continuing."

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			if ($PSCmdlet.ShouldProcess($_appliance.Name, $_Action)) 
			{

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

				$_CurrentCertValidationConfig.certValidationConfig.'global.validateCertificate' = $true
				$_CurrentCertValidationConfig.okToReboot = $true

				if ($PSBoundParameters['CheckForSelfSignedExpiry'])
				{
		
					$_CurrentCertValidationConfig.certValidationConfig.'global.enableExpiryCheckForSelfSignedLeafAtConnect' = $true
					
				}

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
