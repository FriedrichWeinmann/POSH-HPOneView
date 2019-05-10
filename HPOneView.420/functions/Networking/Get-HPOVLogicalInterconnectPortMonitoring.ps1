function Get-HPOVLogicalInterconnectPortMonitoring
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('uri', 'li','name','Resource')]
		[object]$InputObject,
		
		[Parameter (ValueFromPipelineByPropertyName, ParameterSetName = "default", Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		if (-not $InputObject)
		{

			$Pipeline = $true

		}

		else
		{

			"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

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

	}

	Process
	{

		# Validate input object is $ResourceCategoryEnum.LogicalInterconnect
		if ($InputObject.category -ne $ResourceCategoryEnum.LogicalInterconnect)
		{

			# Throw exception
			$ExceptionMessage = 'The provided object "{0}" is not supported.  Only Logical Interconnect resources are supported.' -f $InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneview.InputObjectResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		Try
		{

			$Uri = '{0}/port-monitor' -f $InputObject.uri
			$LIPortMonitorConfigState = Send-HPOVRequest -Uri $Uri -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if ($null -ne $LIPortMonitorConfigState.analyzerPort)
		{

			$AnalyzerPort = New-Object HPOneView.Networking.AnalyzerPort($LIPortMonitorConfigState.analyzerPort.portName, 
																		 $LIPortMonitorConfigState.analyzerPort.portStatus,
																		 $LIPortMonitorConfigState.analyzerPort.portHealthStatus, 
																		 $LIPortMonitorConfigState.analyzerPort.interconnectName,
																		 $LIPortMonitorConfigState.analyzerPort.bayNumber,
																		 $LIPortMonitorConfigState.analyzerPort.interconnectUri, 
																		 $LIPortMonitorConfigState.analyzerPort.portUri, 
																		 $LIPortMonitorConfigState.ApplianceConnection)
		}

		$_MonitoredPorts = New-Object 'System.Collections.Generic.List[HPOneView.Networking.MonitoredPort]'

		ForEach ($_monitoredport in $LIPortMonitorConfigState.monitoredPorts)
		{

			# Get associated deployed connection 
			$Uri = '/rest/index/associations/resources?name=CONNECTION_TO_INTERCONNECT&childUri={0}' -f $_monitoredport.interconnectUri

			Try
			{

				$_IndexResults = Send-HPOVRequest -Uri $Uri -Hostname $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_AssociatedConnection = $null

			# Get Connection object(s), and then filter for the associated connection we need
			ForEach ($_IndexEntry in $_IndexResults.members)
			{

				"[{0}] Get full object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_IndexEntry.name | Write-Verbose

				Try
				{

					$_FullIndexEntry = Send-HPOVRequest -Uri $_IndexEntry.parentResource.uri -Hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($_FullIndexEntry.interconnectPort -eq $_monitoredport.portName.Replace('d', $null))
				{

					$_AssociatedConnection = $_FullIndexEntry.PSObject.Copy()
					break;

				}

			}

			$_Vlans = New-Object 'System.Collections.Generic.List[Int]'

			if ($null -ne $_AssociatedConnection)
			{

				# Get list of VLANs
							

				switch ($_AssociatedConnection.networkResourceUri)
				{

					{$_.StartsWith($EthernetNetworksUri)}
					{

						$_Uri = '{0}' -f $_AssociatedConnection.networkResourceUri

					}

					{$_.StartsWith($NetworkSetsUri)}
					{

						$_Uri = '{0}/networkSetData' -f $_AssociatedConnection.networkResourceUri

					}

				}

				Try
				{

					$_AssociatedNetwork = Send-HPOVRequest -Uri $_Uri -hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				ForEach ($_Network in $_AssociatedNetwork)
				{

					$_Vlans.Add($_Network.vlanId)

				}

				# Finally, get Server Profile object so we can get Connection ID
				$_ServerProfileUri = '{0}/{1}' -f $ServerProfilesUri, $_AssociatedConnection.containerId

				Try
				{

					$_ServerProfile = Send-HPOVRequest -Uri $_ServerProfileUri -hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				$deletgate = [Func[object,bool]]{ param ($c) return $c.mac -eq $_AssociatedConnection.macAddress }
				$_AssociatedServerProfileConnection = [System.Linq.Enumerable]::Where($_ServerProfile.connectionSettings.connections,$deletgate)

				$_PortDetails = New-Object HPOneView.Networking.MonitoredPort+PortDetails ($_AssociatedServerProfileConnection.connectionId,
																						$_AssociatedNetwork.name,
																						$_AssociatedConnection.macAddress,
																						$_Vlans)
			}		

			$_MonitoredPortConfig = New-Object HPOneView.Networking.MonitoredPort($_monitoredport.portName, 
																				  $_monitoredport.portMonitorConfigInfo,
																				  $_monitoredport.portStatus,
																				  $_monitoredport.portHealthStatus, 
																				  $_monitoredport.interconnectName,
																				  $_monitoredport.bayNumber,
																				  $_monitoredport.interconnectUri, 
																				  $_monitoredport.portUri,
																				  $_PortDetails,
																				  $LIPortMonitorConfigState.ApplianceConnection)
		
			$_MonitoredPorts.Add($_MonitoredPortConfig)

		}

		New-Object HPOneView.Networking.LogicalInterconnect+PortMonitoringConfig($LIPortMonitorConfigState.enablePortMonitor,
																				 $AnalyzerPort,
																				 $_MonitoredPorts,
																				 $LIPortMonitorConfigState.eTag,
																				 $LIPortMonitorConfigState.ApplianceConnection)

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
