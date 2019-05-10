function Add-HPOVPowerDevice 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (SupportsShouldProcess, ConfirmImpact = "High")]
	Param 
	(

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Hostname,
		 
		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$Username,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Object]$Password,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential,

		[Parameter (Mandatory = $false)]
		[Switch]$Async,

		[Parameter (Mandatory = $false)]
		[Switch]$TrustLeafCertificate,

		[Parameter (Mandatory = $false)]
		[switch]$Force,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

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

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection) -and -not(${Global:ConnectedSessions}))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif ($ApplianceConnection -is [System.Collections.IEnumerable] -and $ApplianceConnection -isnot [System.String])
		{

			if  ($ApplianceConnection.Count -gt 1)
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException MultipleApplianceConnections InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter contains multiple Appliance Connections.  This CMDLET only supports 1 Appliance Connection in the ApplianceConnect Parameter value.  Please correct this and try again.'
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}


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

		$colStatus = New-Object System.Collections.ArrayList

	}

	Process 
	{

		# Locate the Enclosure Group specified
		"[{0}] - Starting" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if ($PSBoundParameters['TrustLeafCertificate'])
		{

			"[{0}] Caller provide the -TrustLeafCertificate switch.  Adding SSL certificate to appliance trust store." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Getting SSL certificate." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# This is not an async task operation
			Try
			{

				$_uri = '{0}/{1}' -f $RetrieveHttpsCertRemoteUri, $Hostname

				$_DeviceCertificate = Send-HPOVRequest -Uri $_uri -Hostname $ApplianceConnection

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

				$_TaskResults = Send-HPOVRequest -Uri $_uri -Method POST -Body $_DeviceCertificateToImport -Hostname $ApplianceConnection | Wait-HPOVTaskComplete

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

		$_import = NewObject -PowerDeliveryDeviceAdd
		
		$_import.hostname = $Hostname
		$_import.username = $Username
		$_import.password = $_DecryptPassword
		$_import.force    = $Force.IsPresent

		"[{0}] - Sending request to add iPDU." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Try
		{

			$_resp = Send-HPOVRequest -Uri $PowerDevicesDiscoveryUri -Method POST -Body $_import -Hostname $ApplianceConnection

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
			
		"[{0}] Task response: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_resp.taskState, $_resp.erroCode | Write-Verbose

		# Check to see if the task errored, which should be in the Task Validation stage
		if ($_resp.taskState -ne "Running" -and $_resp.taskState -eq "Error" -and $_resp.stateReason -eq "ValidationError") 
		{

			"[{0}] Task error found {1} {2} " -f $MyInvocation.InvocationName.ToString().ToUpper(), $resp.taskState, $resp.stateReason | Write-Verbose

			if ($_resp.taskErrors | Where-Object { $_.errorCode -eq "CERTIFICATE_UNTRUSTED" })
			{

				$ExceptionMessage = 'The leaf certificate for {0} is untrusted by the appliance.  Either provide the -TrustLeafCertificate parameter or manually add the certificate using the Add-HPOVApplianceTrustedCertificate Cmdlet.' -f $Hostname
				$ErrorRecord = New-ErrorRecord InvalidOperationException UntrustedLeafCertificate InvalidResult 'Hostname' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			}

			if ($_resp.taskerrors | Where-Object { $_.errorCode -eq "PDD_IPDU_TRAPRECEIVERACCOUNT_TAKEN" }) 
			{
						
				$_errorMessage = $_resp.taskerrors | Where-Object { $_.errorCode -eq "PDD_IPDU_TRAPRECEIVERACCOUNT_TAKEN" }

				$_externalManagerIP = $_errorMessage.data.mgmtSystemIP

				Try
				{

					$_externalManagerFQDN = [System.Net.DNS]::GetHostByAddress($_externalManagerIP)

				}

				Catch
				{

					"[{0}] Couldn't resolve {1} to FQDN [{2}]." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_externalManagerIP, $_.Exception.Message | Write-Verbose

					$_externalManagerFQDN = [PSCustomObject]@{HostName = $_externalManagerIP}

				}				

				"[{0}] Found iPDU '{1} is already being managed by {2}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Hostname, $_externalManagerIP | Write-Verbose

				"[{0}] {1} resolves to {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_externalManagerIP, $_externalManagerFQDN.HostName | Write-Verbose

				"[{0}] iPDU '{1}' is already claimed by another management system {2} ({3})." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Hostname, $_externalManagerIP, $_externalManagerFQDN.HostName | Write-Verbose

				if ($Force -and $PSCmdlet.ShouldProcess($Hostname,"iPDU is already claimed by another management system $_externalManagerIP ($($_externalManagerFQDN.HostName)). Force add?")) 
				{
							
					"[{0}] - iPDU is being claimed due to user chosing YES to force add." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$import.force = $true

					Try
					{
						
						$_resp = Send-HPOVRequest -Uri $PowerDevicesDiscoveryUri -Method POST -Body $_import -Hostnamme $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				elseif ($PSCmdlet.ShouldProcess($Hostname,"iPDU is already claimed by another management system $_externalManagerIP ($($_externalManagerFQDN.HostName)). Force add?")) 
				{
							
					"[{0}] - iPDU is being claimed due to user chosing YES to force add." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$import.force = $true

					Try
					{
						
						$_resp = Send-HPOVRequest -Uri $PowerDevicesDiscoveryUri -Method POST -Body $_import -Hostnamme $ApplianceConnection.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				else 
				{

					if ($PSBoundParameters['whatif'].ispresent) 
					{ 
							
						"[{0}] -WhatIf was passed, would have force added '$Hostname' iPDU to appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_resp = $null
							
					}

					else 
					{

						# If here, user chose "No", End Processing

						"[{0}] Not importing iPDU {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Hostname | Write-Verbose

						$_resp = $Null

					}

				}

			}

			elseif ($_resp.taskErrors)
			{

				$_errorMessage = $_resp.taskErrors

				if ($_errorMessage -is [System.Collections.IEnumerable]) 
				{ 
						
					# Loop to find a Message value that is not blank.
					$displayMessage = $_errorMessage.message | Where-Object { $null -ne $_ }

					$ErrorRecord = New-ErrorRecord InvalidOperationException 'InvalidResultAddingPDU' InvalidResult 'Hostname' -Message $displayMessage
				
				}
						
				else 
				{ 
					
					$ErrorRecord = New-ErrorRecord InvalidOperationException $errorMessage.errorCode InvalidResult 'Hostname' -Message ($_errorMessage.details + " " + $_errorMessage.message) 
				
				}

				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		if (-not $PSBoundParameters['Async'])
		{

			$_resp | Wait-HPOVTaskComplete

		}

		else
		{

			$_resp

		}
			
	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
