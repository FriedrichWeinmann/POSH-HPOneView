function New-HPOVUplinkSet 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "PipelineOrObjectEthernet")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "PipelineOrObjectEthernet")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "PipelineOrObjectFibreChannel")]
		[Alias ('li','lig','ligName','Resource')]
		[Object]$InputObject,

		[Parameter (Mandatory, ParameterSetName = "PipelineOrObjectFibreChannel")]
		[Parameter (Mandatory, ParameterSetName = "PipelineOrObjectEthernet")]
		[Alias ('usName')]
		[String]$Name,

		[Parameter (Mandatory, ParameterSetName = "PipelineOrObjectFibreChannel")]
		[Parameter (Mandatory, ParameterSetName = "PipelineOrObjectEthernet")]
		[Alias ('usType')]
		[ValidateSet ("Ethernet", "FibreChannel", "Untagged", "Tunnel", 'ImageStreamer', IgnoreCase = $false)]
		[String]$Type,

		[Parameter (Mandatory = $false, ParameterSetName = "PipelineOrObjectFibreChannel")]
		[Parameter (Mandatory = $false, ParameterSetName = "PipelineOrObjectEthernet")]
		[Alias ('usNetworks')]
		[ValidateNotNullorEmpty()]
		[Array]$Networks,

		[Parameter (Mandatory = $false, ParameterSetName = "PipelineOrObjectEthernet")]
		[Alias ('usNativeEthNetwork','Native','PVID')]
		[ValidateNotNullorEmpty()]
		[Object]$NativeEthNetwork,

		[Parameter (Mandatory = $false, ParameterSetName = "PipelineOrObjectFibreChannel")]
		[Parameter (Mandatory = $false, ParameterSetName = "PipelineOrObjectEthernet")]
		[Alias ('usUplinkPorts')]
		[ValidateScript({($_.Split(","))[0].contains(":")})]
		[Array]$UplinkPorts,

		[Parameter (Mandatory = $false, ParameterSetName = "PipelineOrObjectEthernet")]
		[Alias ('usEthMode')]
		[ValidateSet ("Auto", "Failover", IgnoreCase=$false)]
		[String]$EthMode = "Auto",
		
		[Parameter (Mandatory = $false, ParameterSetName = "PipelineOrObjectEthernet")]
		[ValidateSet ("Short", "Long", IgnoreCase=$false)]
		[String]$LacpTimer = "Short",

		[Parameter (Mandatory = $false, ParameterSetName = "PipelineOrObjectEthernet")]
		[ValidateScript({$_.contains(":")})]
		[String]$PrimaryPort,

		[Parameter (Mandatory = $false, ParameterSetName = "PipelineOrObjectFibreChannel")]
		[ValidateSet ("Auto", "2", "4", "8", IgnoreCase=$false)]
		[String]$fcUplinkSpeed = "Auto",

		[Parameter (Mandatory = $false, ParameterSetName = "PipelineOrObjectFibreChannel")]
		[Bool]$EnableTrunking,

		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName, ParameterSetName = "PipelineOrObjectEthernet")]
		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName, ParameterSetName = "PipelineOrObjectFibreChannel")]
		[Switch]$Async,
		
		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName, ParameterSetName = "PipelineOrObjectEthernet")]
		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName, ParameterSetName = "PipelineOrObjectFibreChannel")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{
		
		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject']))
		{

			$PipelineInput = $true

		}

		else
		{

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

		if (-not $PipelineInput -and $ApplianceConnection.ApplianceType -ne 'Composer' -and $Type -eq 'ImageStreamer')
		{
			
			$Exceptionmessage = 'The ApplianceConnection {0} is not a Synergy Composer.  The "ImageStreamer" Type is only supported with HPE Synergy.' -f $ApplianceConnection.Name
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
		}

		else
		{

			$_NewUplinkSetCol = New-Object System.Collections.ArrayList

			# If pipeline object is String and not PSCustomObject, fail the call
			if ($InputObject -is [String] -or (-not($InputObject -is [PSCustomObject])))
			{

				"[{0}] Input Object is an unsupported type: {1}.  Generating error." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.GetType().FullName | Write-Verbose
				
				$ErrorRecord = New-ErrorRecord ArgumentException InvalidParameter InvalidArgument 'Resource' -TargetType 'PSObject' -Message "The -Resource Parameter value type($($InputObject.GetType().Fullname)) provided is not a Logical Interconnect Group object.  Please check the value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			elseif ($InputObject -is [PSCustomObject])
			{

				$InputObject = $InputObject.PSObject.Copy()

			}

			# Validate the resource contains the ApplianceConnection NoteProperty
			if (-not($InputObject.ApplianceConnection))
			{

				"[{0}] Input Object does not contain the ApplianceConnection NoteProperty, generating error." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.GetType().FullName | Write-Verbose
				
				$ErrorRecord = New-ErrorRecord ArgumentException InvalidParameter InvalidArgument 'Type' -Message "The -Type value 'ImageStreamer' is only available for Synergy resources.  Please choose another UplinkSet type."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			# Determine the resource type; LIG or LI
			switch ($InputObject.category)
			{

				# Uplink Sets are created differently for LI Resources
				'logical-interconnects'
				{

					if ($Type -eq 'Imagestreamer' -and $InputObject.enclosureType -notmatch 'SY')
					{

						$ErrorRecord = New-ErrorRecord ArgumentException InvalidParameter InvalidArgument 'Resource' -TargetType 'PSObject' -Message "The -Resource Parameter value does not contain the ApplianceConnection object property.  Please validate the object was retrieved from Get-HPOVLogicalInterconnectGroup or a resource URI via Send-HPOVRequest."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					"[{0}] Provided LI Resource Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
					"[{0}] Provided LI Resource Category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.category | Write-Verbose
					"[{0}] Provided LI Resource URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.uri | Write-Verbose

					# Init Uplink Set Objects
					$_liUplinkSetObject  = NewObject -liUplinkSetObject

					$_liUplinkSetObject.name = $Name
				
					if ($EthMode)
					{

						$_liUplinkSetObject.connectionMode = $EthMode

						if ($EthMode -eq 'Failover' -and $PSBoundParameters['LacpTimer'])
						{

							$ErrorRecord = New-ErrorRecord ArgumentException InvalidParameter InvalidArgument 'LacpTimer' -Message "The -LacpTimer Parameter value is not supported when -EthMode is set to Failover."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

					if ($EthMode -eq 'Auto' -and $PSBoundParameters['LacpTimer'])
					{

						$_liUplinkSetObject.lacpTimer = $LacpTimer

					}

					# Add Logical Interconnect object URI to Uplink Set Object
					$_liUplinkSetObject.logicalInterconnectUri = $InputObject.uri

					# Get list of interconnects within LI resource
					$_liInterconnects = $InputObject.interconnectMap.interconnectMapEntries
				
					"[{0}] Uplink Ports to Process: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [System.String]::Join(', ', $UplinkPorts) | Write-Verbose

					# Loop through requested Uplink Ports
					$port              = New-Object System.Collections.ArrayList
					$uslogicalLocation = New-Object System.Collections.ArrayList

					foreach ($_p in $UplinkPorts)
					{

						# Split string to get bay and port
						$_p = $_p.Split(':')

						# Synergy uplink config
						if ($_p.Count -ge 3)
						{

							'[{0}] Port configuration is Synergy Ethernet' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							
							if ($Type -eq 'FibreChannel' -and $InputObject.enclosureType -match 'SY')
							{

								'[{0}] Setting EnclosureID to -1 for Synergy FibreChannel' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								[String]$EnclosureID = '-1'

							}

							else
							{

								[string]$EnclosureID = $_p[0].TrimStart('enclosureEnclosure')

							}							

							# Remove bay so we just have the ID
							$bay = $_p[1].ToLower().TrimStart('bayBay') -replace " ",$null
							
							# Get faceplate portName (Need to make sure Synergy Uplink Port format which uses : instead of . for subport delimiter is replaced correctly)
							$uplinkPort = $_p[2]

							if ($_p.Count -eq 4)
							{

								$uplinkPort = '{0}.{1}' -f $uplinkPort, $_p[3]

							}

							'[{0}] Processing Frame "{1}", Bay "{2}", Port "{3}"' -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnclosureID, $bay, $uplinkPort | Write-Verbose

							"[{0}] Looking for Interconnect URI for Bay {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $bay | Write-Verbose

							# Loop through Interconnect Map Entry Template items looking for the provided Interconnet Bay number
							ForEach ($l in ($InputObject.interconnectMap.interconnectMapEntries | Where-Object enclosureIndex -eq $EnclosureID)) 
							{ 
	
								if ($l.location.locationEntries | Where-Object { $_.type -eq "Bay" -and $_.relativeValue -eq $bay }) 
								{

									$permittedIcUri = $l.permittedInterconnectTypeUri

									"[{0}]] Found permitted Interconnect Type URI {1} for Bay {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $permittedIcUri, $bay | Write-Verbose

								}

							}

						}

						else
						{

							'[{0}] Port configuration is not Synergy Ethernet' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							# WHY IS THIS HERE?  THIS IS FOR SYNERGY.  NEED TO LOOK AT MY UNIT TESTS.
							# Set the Enclosure ID value.  FC type needs to be -1
							if ($Type -eq 'FibreChannel' -and $InputObject.enclosureType -match 'SY')
							{

								'[{0}] Setting EnclosureID to -1 for Synergy FibreChannel' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								[String]$EnclosureID = -1

							}

							else
							{

								[string]$EnclosureID = $InputObject.enclosureUris

							}		

							# Remove bay so we just have the ID
							$bay = $_p[0].ToLower().TrimStart('bayBay') -replace " ",$null
							
							# Get faceplate portName
							$uplinkPort = $_p[1]

							'[{0}] Processing Bay "{1}", Port "{2}"' -f $MyInvocation.InvocationName.ToString().ToUpper(), $bay, $uplinkPort | Write-Verbose

							"[{0}] Looking for Interconnect URI for Bay {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $bay | Write-Verbose

							# Loop through Interconnect Map Entry Template items looking for the provided Interconnet Bay number
							ForEach ($l in $InputObject.interconnectMap.interconnectMapEntries) 
							{ 

								#$found = $l.logicalLocation.locationEntries | ? { $_.type -eq "Bay" -and $_.relativeValue -eq $bay }
																
								if ($l.location.locationEntries | Where-Object { $_.type -eq "Bay" -and $_.value -eq $bay }) 
								{
										
									$permittedIcUri = $l.permittedInterconnectTypeUri

									"[{0}]] Found permitted Interconnect Type URI {1} for Bay {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $permittedIcUri, $bay | Write-Verbose

								}

							} 

						}

						# Generate error that Interconnect could not be found from the LI
						if ($null -eq $permittedIcUri)
						{

							$ExceptionMessage = 'The Interconnect Bay ID {0} could not be identified within the provided Logical Interconnect resource object.' -f $bay
							$ErrorRecord = New-ErrorRecord HPOneView.UplinkSetResourceException UnsupportedLogicalInterconnectResource InvalidArgument 'InputObject' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)
						}
						
						# Get Interconnect Type object in order to get relative port ID
						Try
						{

							$_interconnecttype = Send-HPOVRequest -Uri $permittedIcUri -Hostname $InputObject.ApplianceConnection.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}
					
						# Validate the Interconnect has capable Uplink Ports
						if (-not ($_interconnecttype.portInfos | Where-Object uplinkCapable))
						{

							$ExceptionMessage = "The Interconnect/Fabric module in 'BAY{0}' has no uplink capable ports.  Please check the value and try again." -f $bay, $uplinkPort
							$ErrorRecord = New-ErrorRecord HPOneView.UplinkSetResourceException UnsupportedInterconnectResource InvalidArgument 'UplinkPorts' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						'Looking for {0} port in portInfos Interconnect property.' -f $uplinkPort | Write-Verbose #.Replace('.',':') | Write-Verbose

						# Translate the port number
						$_portRelativeValue = $_interconnecttype.portInfos | Where-Object { $_.portName.Replace(':','.') -eq $uplinkPort } 

						# Didn't find relative port number, so generate terminating error
						if (-not $_portRelativeValue) 
						{

							$ExceptionMessage = "The provided uplink port 'BAY{0}:{1}' is an invalid port ID.  Did you mean 'X{2}'?  Please check the value and try again." -f $bay, $uplinkPort, $uplinkPort
							$ErrorRecord = New-ErrorRecord HPOneView.UplinkSetResourceException InvalidUplinkPortID InvalidArgument 'port' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						# Make sure the port found is uplinkCapable
						if (-not $_portRelativeValue.uplinkCapable) 
						{

							$ExceptionMessage = "The provided uplink port 'BAY{0}:{1}' is not uplink capable.  Please check the value and try again." -f $bay,$uplinkPort
							$ErrorRecord = New-ErrorRecord HPOneView.UplinkSetResourceException UnsupportedUplinkPort InvalidArgument 'UplinkPorts' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						# Add uplink port
						$_location = NewObject -UplinkSetLocation

						$_EnclosureLocation       = NewObject -UplinkSetLocationEntry
						$_EnclosureLocation.type  = 'Enclosure'
						$_EnclosureLocation.value = $EnclosureId
						[void]$_location.location.locationEntries.Add($_EnclosureLocation)

						$_BayLocation       = NewObject -UplinkSetLocationEntry
						$_BayLocation.type  = 'Bay'
						$_BayLocation.value = [int]$bay
						[void]$_location.location.locationEntries.Add($_BayLocation)

						$_PortLocation       = NewObject -UplinkSetLocationEntry
						$_PortLocation.type  = 'Port'
						$_PortLocation.value = [string]$_portRelativeValue.portName
						[void]$_location.location.locationEntries.Add($_PortLocation)

						# Create Primary Port logical location object
						if ($PrimaryPort -match $_p -and $EthMode -eq "Failover") 
						{

							"[{0}] Setting Uplink Set mode to 'Failover', and Primary Port to '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PrimaryPort | Write-Verbose

							$_liUplinkSetObject.primaryPortLocation | Add-Member -NotePropertyName locationEntries -NotePropertyValue (New-Object System.Collections.ArrayList)

							$_liUplinkSetObject.mode = $EthMode

							$_EnclosureLogicalLocation       = NewObject -UplinkSetLocationEntry
							$_EnclosureLogicalLocation.type  = 'Enclosure'
							$_EnclosureLogicalLocation.value = [int]$EnclosureID
							[void]$_liUplinkSetObject.primaryPortLocation.locationEntries.Add($_EnclosureLogicalLocation)

							$_BayLogicalLocation       = NewObject -UplinkSetLocationEntry
							$_BayLogicalLocation.type  = 'Bay'
							$_BayLogicalLocation.value = [int]$bay
							[void]$_liUplinkSetObject.primaryPortLocation.locationEntries.Add($_BayLogicalLocation)

							$_PortLogicalLocation       = NewOBject -UplinkSetLocationEntry
							$_PortLogicalLocation.type  = 'Port'
							$_PortLogicalLocation.value = [string]$_portRelativeValue.portName
							[void]$_liUplinkSetObject.primaryPortLocation.locationEntries.Add($_PortLogicalLocation)

						}
	
						# Set FC Uplink Port Speed
						if ($Type -eq "FibreChannel") 
						{ 

							$_location.desiredSpeed = $global:SetUplinkSetPortSpeeds[$fcUplinkSpeed]

						}

						else 
						{ 
							
							$_location.desiredSpeed = "Auto" 
						
						}

						"[{0}] Adding Uplink Set to LIG: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_logicalLocation | out-string) | Write-Verbose
							
						[void]$_liUplinkSetObject.portConfigInfos.Add($_location)

					}

					if ($PSBoundParameters['Networks'])
					{

						# Network Objects
						"[{0}] Getting Network Uris" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_networkUris = GetNetworkUris -_Networks $Networks -_ApplianceConnection $ApplianceConnection

						$_NetworkUris | ForEach-Object {
						
							[void]$_liUplinkSetObject.networkUris.Add($_)

						}

					}					
					
					if ($PSBoundParameters['NativeEthNetwork'])
					{
						
						"[{0}] Getting Native Ethernet Network Uri" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_liUplinkSetObject | Add-Member -NotePropertyName nativeNetworkUri -NotePropertyValue $null

						$_liUplinkSetObject.nativeNetworkUri = GetNetworkUris -_Networks $NativeEthNetwork -_ApplianceConnection $ApplianceConnection

					}

					# Validate Uplink Network Type.
					if ($Type -ne 'FibreChannel')
					{

						$_liUplinkSetObject.networkType         = $UplinkSetNetworkTypeEnum[$Type]
						$_liUplinkSetObject.ethernetNetworkType = $UplinkSetEthNetworkTypeEnum[$Type]

					}

					else
					{

						$_liUplinkSetObject.networkType = $UplinkSetNetworkTypeEnum[$Type]

						# Check for the module type first.  If VCFC, allow the correct fcMode value, either TRUNK or NONE.
						if ($FCTrunkCapablePartnumbers.Contains($_interconnecttype.partNumber))
						{

							if ($EnableTrunking)
							{

								$_ligUplinkSetObject.fcMode = 'TRUNK'

							}

							else
							{

								$_ligUplinkSetObject.fcMode = 'NONE'

							}

						}

					}
					
					"[{0}] {1} Uplink Set object: {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, ($_liUplinkSetObject | convertto-json -depth 99) | Write-Verbose

					"[{0}] Sending request..." | Write-Verbose

					Try
					{
						
						$resp = Send-HPOVRequest -uri $UplinkSetsUri -method POST -body $_liUplinkSetObject -Hostname $InputObject.ApplianceConnection.Name

						if (-not $PSBoundParameters['Async'])
						{

							$resp | Wait-HPOVTaskComplete

						}

						else
						{

							$resp

						}

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				'logical-interconnect-groups'
				{

					# Create new instance of the LIGUplinkSet Object
					$_ligUplinkSetObject = NewObject -ligUplinkSetObject

					if ($Type -eq 'Imagestreamer' -and $InputObject.enclosureType -notmatch 'SY')
					{

						$ExceptionMessage = "The -Resource Parameter value does not contain the ApplianceConnection object property.  Please validate the object was retrieved from Get-HPOVLogicalInterconnectGroup or a resource URI via Send-HPOVRequest."
						$ErrorRecord = New-ErrorRecord ArgumentException InvalidParameter InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					$_ligUplinkSetObject.name = $Name

					if ($EthMode)
					{

						$_ligUplinkSetObject.mode = $EthMode

						if ($EthMode -eq 'Failover' -and $PSBoundParameters['LacpTimer'])
						{

							$ErrorRecord = New-ErrorRecord ArgumentException InvalidParameter InvalidArgument 'LacpTimer' -Message "The -LacpTimer Parameter value is not supported when -EthMode is set to Failover."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

					if ($EthMode -eq 'Auto' -and $PSBoundParameters['LacpTimer'])
					{

						$_ligUplinkSetObject.lacpTimer = $LacpTimer

					}

					"[{0}] Provided LIG Resource Name: $($InputObject.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Provided LIG Resource Category: $($InputObject.category)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Provided LIG Resource URI: $($InputObject.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# Get list of interconnects in LIG definition
					$ligInterconnects = $InputObject.interconnectMapTemplate.interconnectMapEntryTemplates
				
					if ($UplinkPorts) 
					{ 
						
						"[{0}] Uplink Ports: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [System.String]::Join(', ', $UplinkPorts) | Write-Verbose 
					
					}

					else 
					{ 
						
						"[{0}] No uplink ports request." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
					
					}

					# Loop through requested Uplink Ports
					$port              = New-Object System.Collections.ArrayList
					$uslogicalLocation = New-Object System.Collections.ArrayList

					foreach ($_p in $UplinkPorts)
					{
						
						# Split string to get bay and port
						$_p = $_p.Split(':')

						# Synergy uplink config
						if ($_p.Count -ge 3)
						{

							[string]$EnclosureID = $EnclosureID = $_p[0].TrimStart('enclosureEnclosure')

							# Remove bay so we just have the ID
							$bay = $_p[1].ToLower().TrimStart('bayBay') -replace " ",$null
							
							# Get faceplate portName (Need to make sure Synergy Uplink Port format which uses : instead of . for subport delimiter is replaced correctly)
							#$uplinkPort = $_p[2].Replace('.',':')
							$uplinkPort = $_p[2]

							if ($_p.Count -eq 4)
							{

								$uplinkPort = '{0}.{1}' -f $uplinkPort, $_p[3]

							}

							'[{0}] Processing Frame "{1}", Bay "{2}", Port "{3}"' -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnclosureID, $bay, $uplinkPort | Write-Verbose

							"[{0}] Looking for Interconnect URI for Bay {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $bay | Write-Verbose

							# Loop through Interconnect Map Entry Template items looking for the provided Interconnet Bay number
							ForEach ($l in ($InputObject.interconnectmaptemplate.interconnectmapentrytemplates | Where-Object enclosureIndex -eq $EnclosureID)) 
							{ 
																
								if ($l.logicalLocation.locationEntries | Where-Object { $_.type -eq "Bay" -and $_.relativeValue -eq $bay }) 
								{

									$permittedIcUri = $l.permittedInterconnectTypeUri

									"[{0}] Found permitted Interconnect Type URI {1} for Bay {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $permittedIcUri, $bay | Write-Verbose

								}

							} 

						}

						else
						{

							'[{0}] Port configuration is not Synergy Ethernet' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							# Set the Enclosure ID value.  FC type needs to be -1
							if ($Type -eq 'FibreChannel' -and $InputObject.enclosureType -match 'SY')
							{

								'[{0}] Setting EnclosureID to -1 for Synergy FibreChannel' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								[String]$EnclosureID = -1

							}

							else
							{

								[String]$EnclosureID = 1

							}							

							# Remove bay so we just have the ID
							$bay = $_p[0].ToLower().TrimStart('bayBay') -replace " ",$null
							
							# Get faceplate portName
							$uplinkPort = $_p[1]

							'[{0}] Processing Bay "{1}", Port "{2}"' -f $MyInvocation.InvocationName.ToString().ToUpper(), $bay, $uplinkPort | Write-Verbose

							"[{0}] Looking for Interconnect URI for Bay {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $bay | Write-Verbose

							# Loop through Interconnect Map Entry Template items looking for the provided Interconnet Bay number
							ForEach ($l in $InputObject.interconnectmaptemplate.interconnectmapentrytemplates) 
							{ 

								if ($l.logicalLocation.locationEntries | Where-Object { $_.type -eq "Bay" -and $_.relativeValue -eq $bay }) 
								{
										
									$permittedIcUri = $l.permittedInterconnectTypeUri

									"[{0}] Found permitted Interconnect Type URI {1} for Bay {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $permittedIcUri, $bay | Write-Verbose

								}

							} 

						}

						# Get Interconnect Type object in order to get relative port ID
						Try
						{

							$_interconnecttype = Send-HPOVRequest $permittedIcUri -Hostname $InputObject.ApplianceConnection.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}	

						# Validate the Interconnect has capable Uplink Ports
						if (-not ($_interconnecttype.portInfos | Where-Object uplinkCapable))
						{

							$ExceptionMessage = "The Interconnect/Fabric module in 'BAY{0}' has no uplink capable ports.  Please check the value and try again." -f $bay,$uplinkPort
							$ErrorRecord = New-ErrorRecord HPOneView.UplinkSetResourceException UnsupportedInterconnectResource InvalidArgument 'UplinkPorts' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}					

						# Translate the port number
						$_portRelativeValue = $_interconnecttype.portInfos | Where-Object { $_.portName.Replace(':','.') -eq $uplinkPort } 

						# Didn't find relative port number, so generate terminating error
						if (-not $_portRelativeValue) 
						{

							$ExceptionMessage = "The provided uplink port 'BAY{0}:{1}' is an invalid port ID.  Please check the value and try again." -f $bay,$uplinkPort
							$ErrorRecord = New-ErrorRecord HPOneView.UplinkSetResourceException InvalidUplinkPortID InvalidArgument 'UplinkPorts' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						# Make sure the port found is uplinkCapable
						if (-not $_portRelativeValue.uplinkCapable) 
						{

							$ExceptionMessage = "The provided uplink port 'BAY{0}:{1}' is not uplink capable.  Please check the value and try again." -f $bay,$uplinkPort
							$ErrorRecord = New-ErrorRecord HPOneView.UplinkSetResourceException UnsupportedUplinkPort InvalidArgument 'UplinkPorts' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						# Add uplink port
						$_logicalLocation = NewObject -UplinkSetLogicalLocation

						$_EnclosureLogicalLocation = NewObject -UplinkSetLogicalLocationEntry
						$_EnclosureLogicalLocation.type = 'Enclosure'
						$_EnclosureLogicalLocation.relativeValue = [int]$EnclosureID

						[void]$_logicalLocation.logicalLocation.locationEntries.Add($_EnclosureLogicalLocation)

						$_BayLogicalLocation = NewObject -UplinkSetLogicalLocationEntry
						$_BayLogicalLocation.type = 'Bay'
						$_BayLogicalLocation.relativeValue = [int]$bay

						[void]$_logicalLocation.logicalLocation.locationEntries.Add($_BayLogicalLocation)

						$_PortLogicalLocation = NewObject -UplinkSetLogicalLocationEntry
						$_PortLogicalLocation.type = 'Port'
						$_PortLogicalLocation.relativeValue = [int]$_portRelativeValue.portNumber

						[void]$_logicalLocation.logicalLocation.locationEntries.Add($_PortLogicalLocation)

						# Create Primary Port logical location object
						if ($PrimaryPort -match $_p -and $EthMode -eq "Failover") 
						{

							"[{0}] Setting Uplink Set mode to 'Failover', and Primary Port to '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PrimaryPort | Write-Verbose 

							$_ligUplinkSetObject.primaryPortLocation | Add-Member -NotePropertyName locationEntries -NotePropertyValue (New-Object System.Collections.ArrayList)

							$_ligUplinkSetObject.mode = $EthMode

							$_EnclosureLogicalLocation               = NewObject -UplinkSetLogicalLocationEntry
							$_EnclosureLogicalLocation.type          = 'Enclosure'
							$_EnclosureLogicalLocation.relativeValue = [int]$EnclosureID

							[void]$_ligUplinkSetObject.primaryPortLocation.locationEntries.Add($_EnclosureLogicalLocation)

							$_BayLogicalLocation               = NewObject -UplinkSetLogicalLocationEntry
							$_BayLogicalLocation.type          = 'Bay'
							$_BayLogicalLocation.relativeValue = [int]$bay

							[void]$_ligUplinkSetObject.primaryPortLocation.locationEntries.Add($_BayLogicalLocation)

							$_PortLogicalLocation               = NewOBject -UplinkSetLogicalLocationEntry
							$_PortLogicalLocation.type          = 'Port'
							$_PortLogicalLocation.relativeValue = [int]$_portRelativeValue.portNumber

							[void]$_ligUplinkSetObject.primaryPortLocation.locationEntries.Add($_PortLogicalLocation)

						}
	
						# Set FC Uplink Port Speed
						if ($Type -eq "FibreChannel") 
						{ 

							$_logicalLocation.desiredSpeed = $global:SetUplinkSetPortSpeeds[$fcUplinkSpeed] 

						}

						else 
						{ 
							
							$_logicalLocation.desiredSpeed = "Auto" 
						
						}

						"[{0}] Adding Uplink Set to LIG: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_logicalLocation | out-string) | Write-Verbose
							
						[void]$_ligUplinkSetObject.logicalPortConfigInfos.Add($_logicalLocation)

					}

					if ($PSBoundParameters['Networks'])
					{

						"[{0}] Getting Network Uris" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
						$_NetworkUris = GetNetworkUris -_Networks $Networks -_ApplianceConnection $ApplianceConnection

						$_NetworkUris | ForEach-Object {
						
							[void]$_ligUplinkSetObject.networkUris.Add($_)

						}

					}			
					
					if ($NativeEthNetwork)
					{
						
						"[{0}] Getting Native Ethernet Network Uri" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_ligUplinkSetObject | Add-Member -NotePropertyName nativeNetworkUri -NotePropertyValue $null

						$_ligUplinkSetObject.nativeNetworkUri = GetNetworkUris -_Networks $NativeEthNetwork -_ApplianceConnection $ApplianceConnection

					}

					# Validate Uplink Network Type.     
					if ($Type -ne 'FibreChannel')
					{

						$_ligUplinkSetObject.networkType         = $UplinkSetNetworkTypeEnum[$Type]
						$_ligUplinkSetObject.ethernetNetworkType = $UplinkSetEthNetworkTypeEnum[$Type]

					}

					else
					{

						$_ligUplinkSetObject.networkType = $UplinkSetNetworkTypeEnum[$Type]

						if ($FCTrunkCapablePartnumbers.Contains($_interconnecttype.partNumber))
						{

							if ($EnableTrunking)
							{

								$_ligUplinkSetObject.fcMode = 'TRUNK'

							}

							else
							{

								$_ligUplinkSetObject.fcMode = 'NONE'

							}

						}

					}					

					"[{0}] {1} Uplink Set object: {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, ($_ligUplinkSetObject | convertto-json -depth 99) | Write-Verbose

					# Rebuld uplinkset collection
					"[{0}] {1} Rebuilding UplinkSet template collection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

					'[{0}] UplinkSets to readd: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.uplinkSets.Count | Write-Verbose

					$InputObject.uplinkSets | ForEach-Object {

						"[{0}] Saving Uplink Set object to new collection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_.name | Write-Verbose

						[void]$_NewUplinkSetCol.Add($_)

					}

					[void]$_NewUplinkSetCol.Add($_ligUplinkSetObject)
										
					[Array]$InputObject.uplinkSets = $_NewUplinkSetCol

					'[{0}] UplinkSets after rebuild: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.uplinkSets.Count | Write-Verbose

					'[{0}] Updated Resource: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), ($InputObject | ConvertTo-Json -Depth 99 | Out-String) | Write-Verbose

					'[{0}] Sending request...' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{
						
						$resp = Send-HPOVRequest -uri $InputObject.uri -method PUT -body $InputObject -Hostname $InputObject.ApplianceConnection.Name

						if ($PSBoundParameters['Async'])
						{

							$resp

						}

						else
						{

							$resp | Wait-HPOVTaskComplete

						}

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				# Unsupported resource category
				default
				{

					$ExceptionMessage = "The Resource Parameter value provided is not a Logical Interconnect Group or Logical Interconnect object.  Please check the value and try again."
					$ErrorRecord = New-ErrorRecord ArgumentException InvalidParameter InvalidArgument 'Resource' -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

		}

	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
