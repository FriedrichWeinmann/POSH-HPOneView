function Enable-HPOVLogicalInterconnectPortMonitoring
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('uri', 'li','name','Resource')]
		[object]$InputObject,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Object]$AnalyzerPort,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Object]$MonitoredPorts,	
		
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

		if ($InputObject.category -ne $ResourceCategoryEnum.LogicalInterconnect)
		{

			# Throw exception
			$ExceptionMessage = 'The provided object "{0}" is not supported.  Only Logical Interconnect resources are supported.' -f $InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneview.InputObjectResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ([Array]$MonitorPorts.Count -gt 16)
		{

			# Throw exception
			$ExceptionMessage = 'The provided number of monitored ports exceeds the allowed limited of 16.  Please remove {0} or more from the MonitoredPorts parameter.' -f ([Array]$MonitorPorts.Count - 16)
			$ErrorRecord = New-ErrorRecord HPOneview.PortMonitorException MonitoredPortsCountExceeded LimitsExceeded "MonitorPorts" -TargetType 'Object' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_Uri = "{0}/port-monitor" -f $InputObject.uri

		# Process AnalyzerPort
		# Split string to get bay and port
		$_AnalyzerPort = $AnalyzerPort.Split(':')

		# Synergy uplink config
		if ($_AnalyzerPort.Count -ge 3)
		{

			'[{0}] Port configuration is Synergy Ethernet' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_EnclosureID = [RegEx]::Replace($_AnalyzerPort[0], '(e|E)nclosure', '')

			# Remove bay so we just have the ID
			$_Bay = [RegEx]::Replace($_AnalyzerPort[1], '(b|B)ay', '')
			
			# Get faceplate portName (Need to make sure Synergy Uplink Port format which uses : instead of . for subport delimiter is replaced correctly)
			$_UplinkPort = [String]$_AnalyzerPort[2].Replace('\.',':')

			if ($_AnalyzerPort.Count -eq 4)
			{

				$_UplinkPort = '{0}.{1}' -f $_UplinkPort, $_AnalyzerPort[3]

			}

		}

		else
		{

			'[{0}] Port configuration is not Synergy Ethernet' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Set the Enclosure ID value.  FC type needs to be -1
			$_EnclosureID = "1"

			# Remove bay so we just have the ID
			$_Bay = [RegEx]::Replace($_AnalyzerPort[0], '(b|B)ay', '')
			
			# Get faceplate portName
			$_UplinkPort = $_AnalyzerPort[1]

		}

		'[{0}] Processing Frame "{1}", Bay "{2}", Port "{3}"' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_EnclosureID, $_Bay, $_UplinkPort | Write-Verbose

		# Can I simplify this next 4 lines into a single search call for either LI type (BL and SY)?
		$_EnclosureDeletgate = [Func[object,bool]]{ param ($e) return $e.enclosureIndex -eq $_EnclosureID }
		$_Enclosure = [System.Linq.Enumerable]::Where($InputObject.interconnectMap.interconnectMapEntries, $_EnclosureDeletgate)

		$_InterconnectDelegate = [Func[object,bool]]{ param ($i) return $i.location.locationEntries.type -eq 'Bay' -and $i.location.locationEntries.value -eq $_Bay }
		$_PermittedIc = [System.Linq.Enumerable]::Where($_Enclosure, $_InterconnectDelegate)
		
		"[{0}] Found permitted Interconnect URI {1} for Bay {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_PermittedIc.interconnectUri, $_Bay | Write-Verbose

		# Generate error that Interconnect could not be found from the LI
		if ($null -eq $_PermittedIc)
		{

			$ExceptionMessage = 'The Interconnect Bay ID {0} could not be identified within the provided Logical Interconnect resource object.' -f $bay
			$ErrorRecord = New-ErrorRecord HPOneView.UplinkSetResourceException UnsupportedLogicalInterconnectResource InvalidArgument 'InputObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}
		
		# Building Port URI
		$_AnalyzerPortUri = '{0}/ports/{1}:{2}' -f $_PermittedIc.interconnectUri, [regex]::Match($_PermittedIc.interconnectUri, '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}').value, $_UplinkPort
		$_AnalyzerPortCfg = New-Object HPOneView.Networking.AnalyzerPortCfg($_AnalyzerPortUri)

		"[{0}] Adding monitored port {1} to config" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_AnalyzerPortCfg | Write-Verbose
		
		$_LogicalInterconnectPortMonitorConfig = New-Object HPOneView.Networking.PortMonitorCfg ($_AnalyzerPortCfg)

		foreach ($_p in $MonitoredPorts)
		{

			# Split string to get bay and port
			$_port = $_p.Port.Split(':')

			# Synergy uplink config
			if ($_port.Count -ge 3)
			{

				'[{0}] Port configuration is Synergy Ethernet' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_EnclosureID = [RegEx]::Replace($_port[0], '(e|E)nclosure', '')

				# Remove bay so we just have the ID
				$_Bay = [RegEx]::Replace($_port[1], '(b|B)ay', '')
				
				# Get faceplate portName (Need to make sure Synergy Uplink Port format which uses : instead of . for subport delimiter is replaced correctly)
				$_MonitoredPortName = $_port[2].ToLower()

				if ($_port.Count -eq 4)
				{

					$_MonitoredPortName = '{0}.{1}' -f $_UplinkPort, $_port[3]

				}

			}

			else
			{

				'[{0}] Port configuration is not Synergy Ethernet' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Set the Enclosure ID value.  FC type needs to be -1
				$_EnclosureID = "1"

				# Remove bay so we just have the ID
				$_Bay = [RegEx]::Replace($_port[0], '(b|B)ay', '')
				
				# Get faceplate portName
				$_MonitoredPortName = $_port[1].ToLower()

			}

			'[{0}] Processing Frame "{1}", Bay "{2}", Port "{3}"' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_EnclosureID, $_Bay, $_MonitoredPortName | Write-Verbose

			# Can I simplify this next 4 lines into a single search call for either LI type (BL and SY)?
			$_EnclosureDeletgate = [Func[object,bool]]{ param ($e) return $e.enclosureIndex -eq $_EnclosureID }
			$_Enclosure = [System.Linq.Enumerable]::Where($InputObject.interconnectMap.interconnectMapEntries, $_EnclosureDeletgate)
			
			$_InterconnectDelegate = [Func[object,bool]]{ param ($i) return $i.location.locationEntries.type -eq 'Bay' -and $i.location.locationEntries.value -eq $_Bay }
			$_PermittedIc = [System.Linq.Enumerable]::Where($_Enclosure, $_InterconnectDelegate)
			
			"[{0}] Found permitted Interconnect URI {1} for Bay {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_PermittedIc.interconnectUri, $_Bay | Write-Verbose

			# Generate error that Interconnect could not be found from the LI
			if ($null -eq $_PermittedIc)
			{

				$ExceptionMessage = 'The Interconnect Bay ID {0} could not be identified within the provided Logical Interconnect resource object.' -f $_Bay
				$ErrorRecord = New-ErrorRecord HPOneView.UplinkSetResourceException UnsupportedLogicalInterconnectResource InvalidArgument 'InputObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			}
			
			$_MonitoredPortUri = '{0}/ports/{1}:{2}' -f $_PermittedIc.interconnectUri, [regex]::Match($_PermittedIc.interconnectUri, '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}').value, $_MonitoredPortName

			$_MonitoredPort = New-Object HPOneView.Networking.MonitoredPortCfg($_MonitoredPortUri, $_p.Direction)

			"[{0}] Adding monitored port {1} to config" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_MonitoredPort | Write-Verbose
				
			$_LogicalInterconnectPortMonitorConfig.MonitoredPorts.Add($_MonitoredPort)

		}

		Try
		{

			Send-HPOVRequest -Uri $_Uri -Method PUT -Body $_LogicalInterconnectPortMonitorConfig -Hostname $ApplianceConnection | Wait-HPOVTaskComplete

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
