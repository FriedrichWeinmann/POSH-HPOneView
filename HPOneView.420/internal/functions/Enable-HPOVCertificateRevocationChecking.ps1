function Enable-HPOVCertificateRevocationChecking
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
		
	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Bool]$SkipRevocationCheck,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Bool]$AllowExpiredCRLs,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Bool]$NotifyExpiredMissingCRLs,

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

		$_Action = 'enable certificate revocation checking'

		if ($PSBoundParameters['SkipRevocationCheck'])
		{

			Write-Warning 'SkipRevocationCheck:  If you have existing CA certificates associated with expired certificate revocation lists (CRL), any communication with devices or remote servers that have certificates authorized by those CAs will fail until new CRLs are uploaded for all of those CA certificates.'
			$_SkipAction = if ($SkipRevocationCheck) { 'enable' } else { 'disable' }
			$_Action += ', {0} skip CRL revocation check' -f $_SkipAction
		
		}

		if ($PSBoundParameters['AllowExpiredCRLs'])
		{

			Write-Warning 'AllowExpiredCRLs:  If you have existing CA certificates associated with expired certificate revocation lists (CRL), any communication with devices or remote servers that have certificates authorized by those CAs will fail until new CRLs are uploaded for all of those CA certificates.'

			$_AllowExpiredCRLsAction = if ($AllowExpiredCRLs) { 'enable' } else { 'disable' }
			$_Action += ', {0} skip CRL revocation check' -f $_AllowExpiredCRLsAction

		}

		if ($PSBoundParameters['NotifyExpiredMissingCRLs'])
		{

			Write-Warning 'NotifyExpiredMissingCRLs:  Changing notify missing or expired CRLs security setting require rebooting the appliance.'

			$_AllowNotifyExpiredCRLsAction = if ($NotifyExpiredMissingCRLs) { 'enable' } else { 'disable' }
			$_Action += ', {0} notify missing or expired CRLs' -f $_AllowNotifyExpiredCRLsAction

		}

		Write-Warning "Enabling certificate revocation checking will require a reboot of the appliance.  Please ensure that other users are not in the middle of operations before continuing."

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

				$_CurrentCertValidationConfig.certValidationConfig.'global.checkCertificateRevocation' = $true

				if ($PSBoundParameters['SkipRevocationCheck'])
				{
		
					$_CurrentCertValidationConfig.certValidationConfig.'global.checkCertificateRevocation' = $SkipRevocationCheck
					
				}

				if ($PSBoundParameters['AllowExpiredCRLs'])
				{
		
					$_CurrentCertValidationConfig.certValidationConfig.'global.allow.noCRL' = $AllowExpiredCRLs
					
				}

				if ($PSBoundParameters['NotifyExpiredMissingCRLs'])
				{
		
					$_CurrentCertValidationConfig.certValidationConfig.'global.allow.invalidCRL' = $NotifyExpiredMissingCRLs
					
				}

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
