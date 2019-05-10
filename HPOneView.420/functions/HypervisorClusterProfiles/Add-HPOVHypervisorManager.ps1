function Add-HPOVHypervisorManager
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Alias('Name', 'ComputerName')]
		[String]$Hostname,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$DisplayName = "",

		[Parameter (ParameterSetName = 'Default', Mandatory)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateRange(1, 65535)]
		[Int]$Port = 443,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$TrustLeafCertificate,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.ScopeCollection]$Scope,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = ($ConnectedSessions | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection) -and -not($ConnectedSessions))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command agian."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif ($ApplianceConnection -is [System.Collections.IEnumerable] -and $ApplianceConnection -isnot [System.String])
		{

			For ([int]$c = 0; $c -gt $ApplianceConnection.Count; $c++)
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

			if ($PSBoundParameters['TrustLeafCertificate'])
			{

				"[{0}] Caller provide the -TrustLeafCertificate switch.  Adding SSL certificate to appliance trust store." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Getting SSL certificate." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# This is not an async task operation
				Try
				{

					$_uri = '{0}/{1}' -f $RetrieveHttpsCertRemoteUri, $Hostname

					$_DeviceCertificate = Send-HPOVRequest -Uri $_uri -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				$_DeviceCertificateToImport = NewObject -CertificateToImport
				$_DeviceCertificateToImport.certificateDetails[0].base64Data = $_DeviceCertificate.certificateDetails.base64Data
				$_DeviceCertificateToImport.certificateDetails[0].aliasName  = $_DeviceCertificate.certificateDetails.commonName

				Try
				{
					
					"[{0}] Adding SSL certificate to appliance trust store." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_uri = '{0}' -f $ApplianceTrustedSslHostStoreUri

					$_TaskResults = Send-HPOVRequest -Uri $_uri -Method POST -Body $_DeviceCertificateToImport -Hostname $_appliance | Wait-HPOVTaskComplete

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($_TaskResults.taskErrors)
				{

					"[{0}] Task errors adding SSL certificate." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					if ($_TaskResults.taskErrors.errorCode -eq '409' -and $_TaskResults.taskErrors.message -match 'The certificate already exists for the alias')
					{

						"[{0}] Certificate already exists." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					}

					else
					{
						
						$ErrorRecord = New-ErrorRecord InvalidOperationException $_TaskResults.taskErrors.errorCode InvalidResult 'Hostname' -Message $_TaskResults.taskErrors.message
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

			}

			$_Uri = $HypervisorManagersUri.Clone()

			$_NewClusterProfileManager = NewObject -ClusterProfileManager
			$_NewClusterProfileManager.name = $Hostname

			if ($PSBoundParameters['DisplayName'])
			{

				$_NewClusterProfileManager.displayName = $DisplayName

			}

			else
			{

				$_NewClusterProfileManager.displayName = $Hostname

			}
			
			$_NewClusterProfileManager.username    = $Credential.UserName
			$_NewClusterProfileManager.password    = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

			if ($PSBoundParameters['Scope'])
			{

				ForEach ($_Scope in $Scope)
				{

					"[{0}] Adding to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

					[void]$_NewClusterProfileManager.initialScopeUris.Add($_Scope.Uri)

				}

			}

			Try
			{
			
				$_resp = Send-HPOVRequest -Uri $_Uri -Method POST -Body $_NewClusterProfileManager -Hostname $_appliance
			
			}
			
			Catch
			{
			
				$PSCmdlet.ThrowTerminatingError($_)
			
			}

			# Wait for task to get into Starting stage
			Try
			{

				$_resp = Wait-HPOVTaskStart $_resp

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
				
			# Check to see if the task errored, which should be in the Task Validation stage
			if ($_resp.taskState -ne "Running" -and $_resp.taskState -eq "Error" -and $_resp.stateReason -eq "ValidationError") 
			{

				"[{0}] Task error found {1} {2} " -f $MyInvocation.InvocationName.ToString().ToUpper(), $resp.taskState, $resp.stateReason | Write-Verbose

				if ($_resp.taskErrors | Where-Object { $_.errorCode -eq "HYPERVISOR_MANAGER_SECURE_CONNECTION_FAILED" })
				{

					$ExceptionMessage = 'The leaf certificate for {0} is untrusted by the appliance.  Either provide the -TrustLeafCertificate parameter or manually add the certificate using the Add-HPOVApplianceTrustedCertificate Cmdlet.' -f $Hostname
					$ErrorRecord = New-ErrorRecord InvalidOperationException UntrustedLeafCertificate InvalidResult 'Hostname' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				}

				elseif ($_resp.taskErrors)
				{

					$_errorMessage = $_resp.taskErrors

					$ErrorRecord = New-ErrorRecord InvalidOperationException $_errorMessage.errorCode InvalidResult 'Hostname' -Message ($_errorMessage.details + " " + $_errorMessage.message) 

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			if ($Async)
			{

				$_resp

			}

			else
			{
			
				$_resp | Wait-HPOVTaskComplete
			
			}

		}

	}

	end
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
