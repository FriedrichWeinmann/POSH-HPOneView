function New-HPOVLogicalInterconnectGroup 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "C7000")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "C7000")]
		[Parameter (Mandatory, ParameterSetName = "Synergy")]
		[ValidateNotNullOrEmpty()]
		[Alias ('ligname')]
		[String]$Name,

		[Parameter (Mandatory, ParameterSetName = "Synergy")]
		[ValidateRange(1,5)]
		[int]$FrameCount = 1,

		[Parameter (Mandatory, ParameterSetName = "Synergy")]
		[ValidateRange(1,3)]
		[int]$InterconnectBaySet,

		[Parameter (Mandatory, ParameterSetName = "Synergy")]
		[ValidateSet ('SEVC40F8','SEVCFC','SAS')]
		[String]$FabricModuleType,

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "C7000")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Synergy")]
		[ValidateNotNullOrEmpty()]
		[Hashtable]$Bays,

		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[ValidateSet ('HighlyAvailable','Redundant','ASide','BSide')]
		[String]$FabricRedundancy = 'Redundant',

		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[Alias ("IGMPSnoop")]
		[bool]$EnableIgmpSnooping = $False,
		
		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[ValidateRange(1,3600)]
		[Alias ('IGMPIdle')]
		[int]$IgmpIdleTimeoutInterval = 260,
		
		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Alias ('FastMAC')]
		[bool]$EnableFastMacCacheFailover = $True,
		
		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[ValidateRange(1,30)]
		[Alias ('FastMACRefresh')]
		[int]$MacRefreshInterval = 5,
		
		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[Alias ('LoopProtect')]
		[bool]$EnableNetworkLoopProtection = $True,

		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Alias ('PauseProtect')]
		[bool]$EnablePauseFloodProtection = $True,

		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[bool]$EnableLLDPTagging = $false,

		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[bool]$EnableEnhancedLLDPTLV,		

		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[ValidateSet ('IPv4','IPv6','IPv4AndIPv6')]
		[String]$LldpAddressingMode,		
		
		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[Object]$SNMP,
		
		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[Bool]$SnmpV1,
		
		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[Bool]$SnmpV3,

		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[ValidateNotNullOrEmpty()]
		[Object]$SnmpV3User,

		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[ValidateNotNullOrEmpty()]
		[Array]$InternalNetworks,

		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[Alias ('qos','QosConfig')]
		[Object]$QosConfiguration,

		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[Parameter (Mandatory = $False, ParameterSetName = "Import")]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.ScopeCollection]$Scope,

		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[Parameter (Mandatory = $False, ParameterSetName = "Import")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $False, ParameterSetName = "C7000")]
		[Parameter (Mandatory = $False, ParameterSetName = "Synergy")]
		[switch]$Async,

		[Parameter (Mandatory, ParameterSetName = "Import")]
		[ValidateScript({split-path $_ | Test-Path})]
		[Alias ('i')]
		[object]$Import

	)

	Begin 
	{
		
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

		$LigTasks = New-Object System.Collections.ArrayList

	}
	
	Process
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			If ($Import)
			{
			
				"[{0}] Reading input file" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				try 
				{

					# Open input file, join so we can validate if the JSON format is correct.
					$lig = [string]::Join("", (Get-Content $import -ErrorAction Stop)) | convertfrom-json -ErrorAction Stop

					if ($PSBoundParameters['Scope'])
					{

						$lig | Add-Member -NotePropertyName initialScopeUris -NotePropertyValue (New-Object System.Collections.ArrayList)

						ForEach ($_Scope in $Scope)
						{

							"[{0}] Adding resource to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

							[void]$lig.initialScopeUris.Add($_Scope.Uri)

						}

					}

					"[{0}] LIG Object to Import: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($lig | ConvertTo-Json -depth 99 | Out-String) | Write-Verbose

					"[{0}] Sending request"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
					$task = Send-HPOVRequest $logicalInterconnectGroupsUri POST $lig -Appliance $_appliance

					[void]$LigStatus.Add($task)

				}
			
				# If there was a problem with the input file (format, not syntax) throw error
				catch [System.ArgumentException] 
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Import' -TargetType "PSObject" -Message "JSON Input File is invalid.  Please check the contents and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			Else 
			{

				switch ($PSCmdlet.ParameterSetName)
				{

					'C7000'
					{

						$uri = $LogicalInterconnectGroupsUri

						# Create new LIgObject
						$lig = NewObject -C7KLig 

						$lig.ethernetSettings.enableIgmpSnooping          = $EnableIgmpSnooping
						$lig.ethernetSettings.igmpIdleTimeoutInterval     = $IgmpIdleTimeoutInterval
						$lig.ethernetSettings.enableFastMacCacheFailover  = $EnableFastMacCacheFailover
						$lig.ethernetSettings.macRefreshInterval          = $MacRefreshInterval
						$lig.ethernetSettings.enableNetworkLoopProtection = $EnableNetworkLoopProtection
						$lig.ethernetSettings.enablePauseFloodProtection  = $EnablePauseFloodProtection
						$lig.ethernetSettings.enableTaggedLldp            = $EnableLLDPTagging
						$lig.ethernetSettings.enableRichTLV               = $EnableEnhancedLLDPTLV

						# Fill in missing bay locations from the input value if needed.
						$Secondary = @{ 1 = $null; 2 = $null; 3 = $null; 4 = $null; 5 = $null; 6 = $null; 7 = $null; 8 = $null }

						# Check for any duplicate keys
						$duplicates = $Bays.keys | Where-Object { $Secondary.ContainsKey($_) }

						if ($duplicates) 
						{

							foreach ($item in $duplicates) 
							{

								$Secondary.Remove($item)

							}

						}

						#join the two hash tables
						$NewBays = $Bays + $Secondary 

						# "[{0}] Bay configuration: $($NewBays | Sort-Object Key -DescEnding | Format-List * )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						# Assign located Interconnect object URI to device bay mapping.
						foreach ($_bay in ($NewBays.GetEnumerator() | Sort-Object Key))
						{

							$_interconnectObject = $null
				
			   				switch ($_bay.value) 
							{

								"FlexFabric" 
								{            

									# Get VC FlexFabric interconnect-type URI
									"[{0}] Found VC FF in bay: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_bay.name | Write-Verbose

									$_interconnectObject = Get-HPOVInterconnectType -partNumber "571956-B21" -Appliance $_appliance

								}

								"Flex10" 
								{

									# Get VC Flex-10 interconnect-type URI
									"[{0}] Found VC F10 in bay: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_bay.name | Write-Verbose

									$_interconnectObject = Get-HPOVInterconnectType -partNumber "455880-B21" -Appliance $_appliance

								}

								"Flex1010D" 
								{

									# Get VC Flex-10/10D interconnect-type URI
									"[{0}] Found VC F1010D in bay: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_bay.name | Write-Verbose

									$_interconnectObject = Get-HPOVInterconnectType -partNumber "638526-B21" -Appliance $_appliance

								}

								"Flex2040f8" 
								{

									# Get VC Flex-10/10D interconnect-type URI
									"[{0}] Found VC Flex2040f8 in bay: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_bay.name | Write-Verbose

									$_interconnectObject = Get-HPOVInterconnectType -partNumber "691367-B21" -Appliance $_appliance

								}

								"VCFC20" 
								{

									# Get VC Flex-10/10D interconnect-type URI
									"[{0}] Found VC FC 20-port in bay {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_bay.name | Write-Verbose

									$_interconnectObject = Get-HPOVInterconnectType -partNumber "572018-B21" -Appliance $_appliance

								}

								"VCFC24" 
								{

									# Get VC Flex-10/10D interconnect-type URI
									"[{0}] Found VC FC 24-port in bay {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_bay.name | Write-Verbose

									$_interconnectObject = Get-HPOVInterconnectType -partNumber "466482-B21" -Appliance $_appliance

								}

								"VCFC16" 
								{

									# Get VC FC 16Gb 24-port interconnect-type URI
									"[{0}] Found VC 16Gb FC 24-port in bay {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_bay.name | Write-Verbose

									$_interconnectObject = Get-HPOVInterconnectType -partNumber "751465-B21" -Appliance $_appliance

								}

								"FEX" 
								{

									# Get Cisco Fabric ExtEnder for HP BladeSystem interconnect-type URI
									"[{0}] Found Cisco Fabric ExtEnder for HP BladeSystem in bay {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_bay.name | Write-Verbose
							
									$_interconnectObject = Get-HPOVInterconnectType -partNumber "641146-B21" -Appliance $_appliance

								}

								default 
								{

									$_interconnectObject = $null

								}
					
							}
				
							$_InterconnectMapEntryTemplate = NewObject -InterconnectMapEntryTemplate

							$_InterconnectMapEntryTemplate.permittedInterconnectTypeUri = $_interconnectObject.uri;
							
							$_LogicalLocationEntry = NewObject -LocationEntry
							$_LogicalLocationEntry.relativeValue = 1
							$_LogicalLocationEntry.type          = 'Enclosure'
							
							[void]$_InterconnectMapEntryTemplate.logicalLocation.locationEntries.Add($_LogicalLocationEntry)

							$_LogicalLocationEntry = NewObject -LocationEntry
							$_LogicalLocationEntry.relativeValue = [String]$_bay.name.ToString().ToLower().Replace('bay',$null)
							$_LogicalLocationEntry.type          = 'Bay'
							
							[void]$_InterconnectMapEntryTemplate.logicalLocation.locationEntries.Add($_LogicalLocationEntry)

							[void]$lig.interconnectMapTemplate.interconnectMapEntryTemplates.Add($_InterconnectMapEntryTemplate)

						}

					}

					'Synergy'
					{

						if ((${Global:ConnectedSessions} | Where-Object Name -EQ $_appliance.Name).ApplianceType -ne 'Composer')
						{

							$Message = 'The Appliance {0} is not a Synergy Composer, and this operation is not supported.  Only Synergy managed resources are supported with this Cmdlet.' -f $_appliance.Name

							$ErrorRecord = New-ErrorRecord HPOneView.Appliance.ComposerNodeException UnsupportedMethod InvalidOperation 'ApplianceConnection' -TargetType 'HPOneView.Appliance.Connection' -Message $Message

							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						switch ($FabricModuleType)
						{

							'SEVC40F8'
							{

								# Used for the POST request below
								$uri = $LogicalInterconnectGroupsUri

								# Create new LIgObject
								$lig = NewObject -SELig 

								$lig.name                                         = $Name
								$lig.redundancyType                               = $LogicalInterconnectGroupRedundancyEnum[$FabricRedundancy]
								$lig.interconnectBaySet                           = $InterconnectBaySet
								$lig.ethernetSettings.enableIgmpSnooping          = $EnableIgmpSnooping
								$lig.ethernetSettings.igmpIdleTimeoutInterval     = $IgmpIdleTimeoutInterval
								$lig.ethernetSettings.enableFastMacCacheFailover  = $EnableFastMacCacheFailover
								$lig.ethernetSettings.macRefreshInterval          = $MacRefreshInterval
								$lig.ethernetSettings.enableNetworkLoopProtection = $EnableNetworkLoopProtection
								$lig.ethernetSettings.enablePauseFloodProtection  = $EnablePauseFloodProtection
								$lig.ethernetSettings.enableTaggedLldp            = $EnableLLDPTagging
								$lig.ethernetSettings.enableRichTLV               = $EnableEnhancedLLDPTLV

								# This is here to make sure Frame# is present, and not just a hashtable of bays.
								if ($FrameCount -ne $Bays.Count)
								{

									$Message = "The -FrameCount parameter value '{0}' does not match the expected Frame and Fabric Bay configuration in the -Bays parameters, '{1}'." -f $FrameCount, $Bays.Count
									$ErrorRecord = New-ErrorRecord HPOneView.LogicalInterconnectGroupResourceException InvalidArgumentValue InvalidArgument 'InternalNetworks' -TargetType 'PSObject' -Message $Message
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								1..$FrameCount | ForEach-Object { [void]$lig.enclosureIndexes.Add($_) }

							}

							'SEVCFC'
							{

								# Used for the POST request below
								$uri = $LogicalInterconnectGroupsUri

								# Create new LIgObject
								$lig = NewObject -SELig 
								$lig.name               = $Name
								$lig.redundancyType     = $LogicalInterconnectGroupRedundancyEnum[$FabricRedundancy]
								$lig.interconnectBaySet = $InterconnectBaySet
								[void]$lig.enclosureIndexes.Add('-1')
								$EnclosureIndex = '-1'

								# Validate BaySet
								if ($InterconnectBaySet -eq 3)
								{

									$Message = "The -InterconnectBaySet parameter value '{0}' is not supported.  Please choose InterconnectBaySet 1 or 2." -f $InterconnectBaySet
									$ErrorRecord = New-ErrorRecord HPOneView.LogicalInterconnectGroupResourceException InvalidArgumentValue InvalidArgument 'InterconnectBaySet' -TargetType 'Int' -Message $Message
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}
								
							}

							'SAS'
							{

								# Used for the POST request below
								$uri = $SasLogicalInterconnectGroupsUri

								# Create new LIgObject
								$lig = NewObject -SESASLIG
								$lig.name  = $Name

							}
							
						}

						ForEach ($_Entry in ($Bays.GetEnumerator() | Sort-Object Key))
						{

							if ($_Entry.Name -Match 'frame')
							{
						
								if ($EnclosureIndex = '-1' -and $FabricModuleType -eq 'SEVCFC')
								{

									[int]$_FrameID = -1

								}

								else
								{

									[int]$_FrameID = $_Entry.Name.ToLower().Replace("frame",$null)

								}
								

								"[$($MyInvocation.InvocationName.ToString().ToUpper())] Processing Frame ID: {0}" -f $_FrameID | Write-Verbose

								ForEach ($_Bay in ($_Entry.Value).GetEnumerator())
								{

									[int]$_BayID = $_Bay.Name.ToString().ToLower().Replace('bay',$null)

									"[$($MyInvocation.InvocationName.ToString().ToUpper())] Getting Fabric Module for Bay {0} to {1}" -f $_BayID, $_Bay.Value | Write-Verbose 
						
									$_InterconnectBayObject = $null

									Try
									{

										$_InterconnectBayObject = Get-InterconnectBayObject $_Bay $_appliance

									}

									Catch
									{

										$PSCmdlet.ThrowTerminatingError($_)

									}

									"[$($MyInvocation.InvocationName.ToString().ToUpper())] Setting Fabric Module Bay {0} to {1}" -f $_BayID, $_InterconnectBayObject.name | Write-Verbose 

									$_InterconnectMapEntryTemplate = NewObject -InterconnectMapEntryTemplate

									$_InterconnectMapEntryTemplate.permittedInterconnectTypeUri = $_InterconnectBayObject.uri
									$_InterconnectMapEntryTemplate.enclosureIndex               = $_FrameID
									
									$_LogicalLocationEntry = NewObject -LocationEntry
									$_LogicalLocationEntry.relativeValue = $_FrameID
									$_LogicalLocationEntry.type          = 'Enclosure'
								
									[void]$_InterconnectMapEntryTemplate.logicalLocation.locationEntries.Add($_LogicalLocationEntry)

									$_LogicalLocationEntry = NewObject -LocationEntry
									$_LogicalLocationEntry.relativeValue = $_BayID
									$_LogicalLocationEntry.type          = 'Bay'
									
									[void]$_InterconnectMapEntryTemplate.logicalLocation.locationEntries.Add($_LogicalLocationEntry)

									[void]$lig.interconnectMapTemplate.interconnectMapEntryTemplates.Add($_InterconnectMapEntryTemplate)
							
								}

							}

							else
							{

								[int]$_BayID = $_Entry.Name.ToString().ToLower().Replace('bay',$null)

								if ($EnclosureIndex = '-1' -and $FabricModuleType -eq 'SEVCFC')
								{

									[int]$_FrameID = -1

								}

								else
								{

									$_FrameID = 1
									
								}							
											
								$_InterconnectBayObject = $null

								Try
								{

									$_InterconnectBayObject = Get-InterconnectBayObject $_Entry $_appliance

								}

								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}

								if ($_BayID -ne 1 -and $_BayID -ne 4 -and $_InterconnectBayObject.name -match 'SAS')
								{

									$Message = 'The Fabric Module Bay {0} is invalid for the Synergy 12Gb SAS Connection Module.  Please specify Fabric Module Bay 1 or 4.' -f $_BayID
									$ErrorRecord = New-ErrorRecord HPOneView.LogicalInterconnectGroupResourceException InvalidFabricBayIDforSasInterconnect InvalidArgument 'Bays' -TargetType $_Entry.GetType().Name -Message $Message
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

								}

								"[{0}] Setting Fabric Module Bay {1} to {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_BayID, $_Entry.Value | Write-Verbose 

								$_InterconnectMapEntryTemplate = NewObject -InterconnectMapEntryTemplate

								$_InterconnectMapEntryTemplate.permittedInterconnectTypeUri = $_InterconnectBayObject.uri
								$_InterconnectMapEntryTemplate.enclosureIndex               = $_FrameID
								
								$_LogicalLocationEntry = NewObject -LocationEntry
								$_LogicalLocationEntry.relativeValue = $_FrameID
								$_LogicalLocationEntry.type          = 'Enclosure'
							
								[void]$_InterconnectMapEntryTemplate.logicalLocation.locationEntries.Add($_LogicalLocationEntry)

								$_LogicalLocationEntry = NewObject -LocationEntry
								$_LogicalLocationEntry.relativeValue = $_BayID
								$_LogicalLocationEntry.type          = 'Bay'
								
								[void]$_InterconnectMapEntryTemplate.logicalLocation.locationEntries.Add($_LogicalLocationEntry)

								[void]$lig.interconnectMapTemplate.interconnectMapEntryTemplates.Add($_InterconnectMapEntryTemplate)

							}

						}

					}

				}
				
				if ($lig.type -notmatch 'sas')
				{

					# Decide what type of QoS Configuration to add to activeQosConfig
					$lig.qosConfiguration.activeQosConfig = if ($QosConfiguration) 
					{ 

						if(-not($QosConfiguration -is [PSCustomObject]))
						{

							$Message = "The -QosConfiguration Parameter does not contain a valid QOS Configuration Object.  Please check the value and try again."
							$ErrorRecord = New-ErrorRecord HPOneView.LogicalInterconnectGroupResourceException InvalidArgumentValue InvalidArgument 'QosConfiguration' -TargetType $QosConfiguration.Gettype().Name -Message $Message
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}
					
						if ($QosConfiguration.type -ne 'QosConfiguration')
						{

							$Message = "The -QosConfiguration Parameter value does not contain a valid QOS Configuration Object.  OBject type expected 'QosConfiguration', Received '$($QosConfiguration.type)'.  Please check the value and try again."
							$ErrorRecord = New-ErrorRecord HPOneView.LogicalInterconnectGroupResourceException InvalidArgumentValue InvalidArgument 'QosConfiguration' -TargetType 'PSObject' -Message $Message
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
						}

						$QosConfiguration 
				
					} 
				
					Else 
					{ 
					
						NewObject -QosConfiguration 
				
					}

					if ($PSBoundParameters['InternalNetworks'])
					{

						ForEach ($_network in $InternalNetworks)
						{

							"[{0}] Internal Network Type: $($_network.GetType().Name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							switch ($_network.GetType().Name)
							{

								'String'
								{

									"[{0}] Processing Internal Network: $_network" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

									if ($_network.StartsWith($EthernetNetworksUri))
									{

										Try
										{

											# Validating object
											$_network = Send-HPOVRequest $_network -Hostname $_appliance

											# Generate terminating error due to incorrect object from URI isn't the correct type
											if ($_network.category -ne 'ethernet-networks')
											{

												$Message = "The Internal Network '$_network' does not match the allowed value of 'ethernet-networks'.  Please specify an Ethernet Network to assign to the Internal Networks property."
												$ErrorRecord = New-ErrorRecord HPOneView.LogicalInterconnectGroupResourceException InvalidArgumentValue InvalidArgument 'InternalNetworks' -TargetType 'PSObject' -Message $Message
												$PSCmdlet.ThrowTerminatingError($ErrorRecord)

											}

										}

										catch
										{

											$PSCmdlet.ThrowTerminatingError($_)

										}

									}

									# Get network resource via Get-HPOVNetwork
									else
									{

										try
										{

											$_network = Get-HPOVNetwork $_network -ApplianceConnection $_appliance

										}

										catch
										{

											$PSCmdlet.ThrowTerminatingError($_)

										}

									}

								}

								'PSCustomObject'
								{

									"[{0}] Processing Internal PSObject Network: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_network.name, $_network.uri | Write-Verbose

									# Throw terminating error if the Internet Network object is not type Ethernet Network
									if (-not($_network.category -eq 'ethernet-networks'))
									{

										$Message = "The Internal Network category for ($_network.name) does not match the allowed value of 'ethernet-networks'."
										$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InternalNetworks' -TargetType 'PSObject' -Message $Message
										$PSCmdlet.ThrowTerminatingError($ErrorRecord)

									}

									# Error if Netowrk Object does not match the appliance connection we are currently Processing.
									if ($_network.ApplianceConnection.Name -ne $_appliance.Name)
									{

										$Message = "The Internal Network '($_network.name)' Appliance Connection ($($_network.ApplianceConnection.Name)) does not match the current Appliance Connection ($($_appliance.Name)) being Processed."
										$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InternalNetworks' -TargetType 'PSObject' -Message $Message
										$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
									}

								}

							}

							# Add to URI's to collection
							[void]$lig.internalNetworkUris.Add($_network.uri)

						}

					}

				}			

				if ($PSBoundParameters['Snmp'])
				{

					$lig.snmpConfiguration = $Snmp

				}

				$lig.name = $Name

				# "[{0}] LIG: $(ConvertTo-Json -Depth 99 $lig)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Sending request to create '$($lig.name)'..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
				Try
				{
				
					$task = Send-HPOVRequest $uri POST $lig -Hostname $_appliance
				
				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($Async.IsPresent)
				{

					[void]$LigTasks.Add($task)

				}

				else
				{

					Try
					{

						$_FinalTaskStaus = Wait-HPOVTaskComplete $task

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					[void]$LigTasks.Add($_FinalTaskStaus)

				}		

			}

		}

	}

	End 
	{

		Return $LigTasks

	}

}
