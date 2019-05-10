function Show-HPOVApplianceSecurityModeCompatibilityReport
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	[OutputType([HPOneView.Appliance.SecurityModeCompatibilityReport], ParameterSetName="Default")]
	param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.SecurityMode]$TargetSecurityMode,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Switch]$UpdateReport,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = ($ConnectedSessions | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $PSBoundParameters['TargetSecurityMode'])
		{

			$Pipelineinput = $True

		}

		else
		{

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

		function GenerateCompatabilityReport
		{

			[CmdletBinding (DefaultParameterSetName = 'Default')]
			param
			(

				[Parameter (Mandatory, ParameterSetName = 'Default', Position = 0)]
				[ValidateNotNullOrEmpty()]
				[HPOneView.Appliance.SecurityMode]$_CurrentMode,

				[Parameter (Mandatory, ParameterSetName = 'Default', Position = 1)]
				[ValidateNotNullOrEmpty()]
				[HPOneView.Appliance.SecurityMode]$_TargetMode,

				[Parameter (Mandatory, ParameterSetName = 'Default', Position = 2)]
				[ValidateNotNullOrEmpty()]
				[Alias ('Appliance')]
				[HPOneView.Appliance.Connection]$_ApplianceConnection,

				[Parameter (Mandatory = $false, ParameterSetName = 'Default', Position = 3)]
				[Switch]$UpdateReport

			)

			Try
			{

				$_GenerateCompatabilityReport = NewObject -SecurityModeCompatabilityReport
				$_GenerateCompatabilityReport.currentMode = $_CurrentMode.ModeName
				$_GenerateCompatabilityReport.targetMode  = $_TargetMode.ModeName

				$_Uri = $ApplianceSecurityModeCompatibiltyReportUri.Clone()

				if ($UpdateReport.IsPresent)
				{

					$_Uri += "?force=true"

				}

				Send-HPOVRequest -Uri $_Uri -Method POST -Body $_GenerateCompatabilityReport -Hostname $_ApplianceConnection | Wait-HPOVTaskComplete | Out-Null

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

	}

	Process
	{

		# Get current security mode
		'[{0}] Getting current appliance security mode.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Try
		{

			$_CurrentApplianceSecurityMode = Get-HPOVApplianceCurrentSecurityMode -ApplianceConnection $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		# If current matches target, generate error saying mode already set
		if ($_CurrentApplianceSecurityMode.ModeName -eq $TargetSecurityMode.ModeName)
		{

			'[{0}] Appliance is already at the requested appliance security mode: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $TargetSecurityMode.ModeName | Write-Verbose

			$ExceptionMessage = "The appliance is already at the requested '{0}' security mode." -f $TargetSecurityMode.ModeName
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ApplianceSecurityModeException ApplianceAlreadySetToSecurityMode ResourceExists "ApplianceConnection" -Message $ExceptionMessage
			$PSCmdlet.WriteError($ErrorRecord)

		}

		else
		{

			# Regenerate report
			if ($UpdateReport.IsPresent)
			{

				'[{0}] Refreshing the security mode compatability report.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{					

					GenerateCompatabilityReport $_CurrentApplianceSecurityMode $TargetSecurityMode $ApplianceConnection $UpdateReport.IsPresent

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			# Get supported security protocols for security mode
			Try
			{

				$_SupportedSecurityProtocolsFromMode = Get-HPOVApplianceSecurityProtocol -SecurityMode $TargetSecurityMode.ModeName -ApplianceConnection $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# Check to see if a report exists, if not, generate it
			Try
			{

				$_Report = Send-HPOVRequest -Uri $ApplianceSecurityModeCompatibiltyReportUri -Hostname $ApplianceConnection

				'[{0}] Report exists on appliance.  Generating the security mode compatability report.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			Catch [HPOneview.ResourceNotFoundException]
			{

				'[{0}] Report does not exist.  Creating the security mode compatability report.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
				
					GenerateCompatabilityReport $_CurrentApplianceSecurityMode $TargetSecurityMode $ApplianceConnection

					'[{0}] Report created.  Retrieving details.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_Report = Send-HPOVRequest -Uri $ApplianceSecurityModeCompatibiltyReportUri -Hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# Build report
			Try
			{

				'[{0}] Building compatibility report object(s).' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_externalServers = New-Object "System.Collections.Generic.List[HPOneView.Appliance.SecurityModeCompatibilityReport+ExternalServer]"

				ForEach ($_ExternalCert in ($_Report.members | Where-Object { $_.reportSection.sectionKey -eq 'EXTERNALCERTIFICATE'}))
				{

					$_ExternalCompatbilityDetails = New-Object "System.Collections.Generic.List[HPOneView.Appliance.SecurityModeCompatibilityReport+CompapatibilityDetail]"

					ForEach ($_CompatDetail in $_ExternalCert.nonCompatibilityDetails)
					{

						$_CompapatibilityDetail = New-Object HPOneView.Appliance.SecurityModeCompatibilityReport+CompapatibilityDetail ($_CompatDetail.nonCompatibilityKey, $_CompatDetail.nonCompatibilityAction)
						$_ExternalCompatbilityDetails.Add($_CompapatibilityDetail)

					}

					$_externalServer = New-Object HPOneView.Appliance.SecurityModeCompatibilityReport+ExternalServer ($_ExternalCert.deviceName, 
																													  $_ExternalCert.deviceType, 
																													  $_ExternalCert.deviceUri, 
																													  $_ExternalCompatbilityDetails, 
																													  $_ExternalCert.ApplianceConnection)

					$_externalServers.Add($_externalServer)
					
				}

				$_managedDevices = New-Object "System.Collections.Generic.List[HPOneView.Appliance.SecurityModeCompatibilityReport+ManagedDevice]"

				ForEach ($_managedDevice in ($_Report.members | Where-Object { $_.reportSection.sectionKey -eq 'MANAGEDDEVICE'}))
				{

					$_ManagedDeviceCompatbilityDetails = New-Object "System.Collections.Generic.List[HPOneView.Appliance.SecurityModeCompatibilityReport+CompapatibilityDetail]"

					ForEach ($_CompatDetail in $_managedDevice.nonCompatibilityDetails)
					{

						$_CompapatibilityDetail = New-Object HPOneView.Appliance.SecurityModeCompatibilityReport+CompapatibilityDetail ($_CompatDetail.nonCompatibilityKey, $_CompatDetail.nonCompatibilityAction)
						$_ManagedDeviceCompatbilityDetails.Add($_CompapatibilityDetail)

					}

					$_externalServer = New-Object HPOneView.Appliance.SecurityModeCompatibilityReport+ManagedDevice ($_managedDevice.deviceName, 
																													 $_managedDevice.deviceType, 
																													 $_managedDevice.deviceUri, 
																													 $_ManagedDeviceCompatbilityDetails, 
																													 $_managedDevice.ApplianceConnection)

					$_managedDevices.Add($_externalServer)

				}

				$_applianceCerificates = New-Object "System.Collections.Generic.List[HPOneView.Appliance.SecurityModeCompatibilityReport+ApplianceCerificate]"

				ForEach ($_ApplianceCert in ($_Report.members | Where-Object { $_.reportSection.sectionKey -eq 'APPLIANCECERTIFICATE'}))
				{

					$_ApplianceCertCompatbilityDetails = New-Object "System.Collections.Generic.List[HPOneView.Appliance.SecurityModeCompatibilityReport+CompapatibilityDetail]"

					ForEach ($_CompatDetail in $_ApplianceCert.nonCompatibilityDetails)
					{

						$_CompapatibilityDetail = New-Object HPOneView.Appliance.SecurityModeCompatibilityReport+CompapatibilityDetail ($_CompatDetail.nonCompatibilityKey, $_CompatDetail.nonCompatibilityAction)
						$_ApplianceCertCompatbilityDetails.Add($_CompapatibilityDetail)

					}

					$_applianceCerificate = New-Object HPOneView.Appliance.SecurityModeCompatibilityReport+ApplianceCerificate ($_ApplianceCert.deviceName, 
																																$_ApplianceCert.deviceType, 
																																$_ApplianceCert.deviceUri, 
																																$_ApplianceCertCompatbilityDetails, 
																																$_ApplianceCert.ApplianceConnection)

					$_applianceCerificates.Add($_applianceCerificate)

				}

				New-Object HPOneView.Appliance.SecurityModeCompatibilityReport ($TargetSecurityMode.ModeName, 
																				$_Report.created, 
																				$_SupportedSecurityProtocolsFromMode, 
																				$_applianceCerificates, 
																				$_externalServers, 
																				$_managedDevices, 
																				$_Report.ApplianceConnection)

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
		
		}

	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
