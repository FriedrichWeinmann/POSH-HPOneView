function New-HPOVEnclosureGroup 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'C7000')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'C7000')]
		[Parameter (Mandatory, ParameterSetName = 'Synergy')]
		[Parameter (Mandatory, ParameterSetName = 'DiscoverFromEnclosure')]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Synergy')]
		[ValidateRange(1,5)]
		[int]$EnclosureCount = 1,
		 
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'C7000')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Synergy')]
		[ValidateNotNullOrEmpty()]
		[Alias ('logicalInterconnectGroupUri','logicalInterconnectGroup')]
		[object]$LogicalInterconnectGroupMapping,

		[Parameter (Mandatory = $false, ParameterSetName = 'C7000')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Synergy')]
		[Parameter (Mandatory = $false, ParameterSetName = 'DiscoverFromEnclosure')]
		[ValidateSet ('RedundantPowerFeed','RedundantPowerSupply', IgnoreCase = $false)]
		[string]$PowerRedundantMode = "RedundantPowerFeed",

		[Parameter (Mandatory = $false, ParameterSetName = 'C7000')]
		[Parameter (Mandatory = $false, ParameterSetName = 'DiscoverFromEnclosure')]
		[ValidateNotNullOrEmpty()]
		[string]$ConfigurationScript,      
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Synergy')]
		[ValidateSet ('AddressPool', 'DHCP', 'External')]
		[String]$IPv4AddressType = 'DHCP',
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Synergy')]
		[ValidateNotNullOrEmpty()]
		[object]$AddressPool,
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Synergy')]
		[ValidateSet ('None', 'Internal', 'External')]
		[String]$DeploymentNetworkType = 'None',
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Synergy')]
		[ValidateNotNullOrEmpty()]
		[object]$DeploymentNetwork,

		[Parameter (Mandatory, ParameterSetName = 'DiscoverFromEnclosure')]
		[switch]$DiscoverFromEnclosure,

		[Parameter (Mandatory, ParameterSetName = 'DiscoverFromEnclosure')]
		[ValidateNotNullorEmpty()]
		[String]$OAAddress,

		[Parameter (Mandatory, ParameterSetName = 'DiscoverFromEnclosure')]
		[ValidateNotNullorEmpty()]
		[String]$Username,

		[Parameter (Mandatory, ParameterSetName = 'DiscoverFromEnclosure')]
		[ValidateNotNullorEmpty()]
		[String]$Password,

		[Parameter (Mandatory = $false, ParameterSetName = 'DiscoverFromEnclosure')]
		[ValidateNotNullorEmpty()]
		[String]$LigPrefix,

		[Parameter (Mandatory = $false, ParameterSetName = 'C7000')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Synergy')]
		[Parameter (Mandatory = $false, ParameterSetName = 'DiscoverFromEnclosure')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'ImportFile')]
		[HPOneView.Appliance.ScopeCollection]$Scope,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'C7000')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'ImportFile')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Synergy')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'DiscoverFromEnclosure')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory, ParameterSetName = "ImportFile")]
		[ValidateNotNullOrEmpty()]
		[Alias ("i", "import")]
		[string]$ImportFile

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Resolved Parameter Set Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PSCmdlet.ParameterSetName | Write-Verbose

		if (-not($PSBoundParameters['LogicalInterconnectGroupMapping']))
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

		$_EnclosureGroupCreateResults = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PSCmdlet.ParameterSetName -eq 'DiscoverFromEnclosure')
		{

			if ($ApplianceConnection.ApplianceType -eq 'Composer')
			{
				
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message ('The ApplianceConnection {0} is a Synergy Composer, which does not support Enclosure Discovery to create an Enclosure Group.' -f $ApplianceConnection.Name)
				$PSCmdlet.WriteError($ErrorRecord)
				
			}

			else
			{

				$_EnclosureGroupPreview = NewObject -EnclosureGroupPreview

				$_EnclosureGroupPreview.username  = $Username
				$_EnclosureGroupPreview.password  = $Password
				$_EnclosureGroupPreview.hostname  = $OAAddress
				$_EnclosureGroupPreview.ligPrefix = $LigPrefix

				Try
				{

					$_EnclosurePreview = Send-HPOVRequest $EnclosurePreviewUri POST $_EnclosureGroupPreview -Hostname $ApplianceConnection

					if (-not($PSBoundParameters['LigPrefix']))
					{

						$_EnclosurePreview.logicalInterconnectGroup.name = $_EnclosurePreview.logicalInterconnectGroup.name.Replace('null',$Name)

					}

					$LigTaskResp = Send-HPOVRequest $LogicalInterconnectGroupsUri POST $_EnclosurePreview.logicalInterconnectGroup -Hostname $ApplianceConnection | Wait-HPOVTaskComplete

					$LogicalInterconnectGroupMapping = Send-HPOVRequest $LigTaskResp.associatedResource.resourceUri -Hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}	

			}					

		}

		if ($PSCmdlet.ParameterSetName -eq 'importFile')
		{

			$_EnclosureGroup = (Get-Content $ImportFile).ToString()

			"[{0}] Enclosure Group object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_EnclosureGroup | Write-Verbose

			Try
			{

				$resp = Send-HPOVRequest $enclosureGroupsUri POST $_EnclosureGroup -Hostname $ApplianceConnection.Name

				$resp.PSObject.TypeNames.Insert(0,'HPOneView.EnclosureGroup')

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		else
		{	
			
			$_EnclosureGroup           = NewObject -EnclosureGroup
			$_EnclosureGroup.name      = $Name
			$_EnclosureGroup.powerMode = $PowerRedundantMode

			switch ($PSCmdlet.ParameterSetName)
			{

				'Synergy'
				{

					$_EnclosureGroup           = NewObject -SynergyEnclosureGroup
					$_EnclosureGroup.name      = $Name
					$_EnclosureGroup.powerMode = $PowerRedundantMode

					if ($ApplianceConnection.ApplianceType -ne 'Composer')
					{
				
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message ('The ApplianceConnection {0} is not a Synergy Composer.  Creating an Enclosure Group with OSDeployment Settings is only supported with Synergy Composers and the HPE Synergy Image Streamer.' -f $ApplianceConnection.Name)
						$PSCmdlet.WriteError($ErrorRecord)
				
					}

					else
					{

						"[{0}] Processing Synergy LIG(s)." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_c = 0

						# Explicit Mapping with Hashtable
						if ($LogicalInterconnectGroupMapping -is [System.Collections.IEnumerable] -and $LogicalInterconnectGroupMapping -isnot [String])
						{
					
							# Loop through LIGs to build EG Interconnect Bay Mapping
							# -LogicalInterConnectGroupMapping $MyMultiFrameVCEthLig,$MyVCFCLig
							# -LogicalInterConnectGroupMapping @{Frame1=$MyMultiFrameVCEthLig,$MyVCFCLig;Frame2=$MyMultiFrameVCEthLig,$MyVCFCLig;Frame3=$MyMultiFrameVCEthLig}
							foreach ($_FrameLig in $LogicalInterconnectGroupMapping.GetEnumerator())
							{

								if (($_FrameLig -is [System.Collections.IEnumerable] -and $_FrameLig -isnot [String] -and $_FrameLig -isnot [Array]) -or ($_FrameLig -is [System.Collections.DictionaryEntry]))
								{

									$_FrameLigIndex = $_FrameLig.Key.ToLower().TrimStart('frameenclosure')

									$_FrameLig = $_FrameLig.Value

									'[{0}] Frame LIG Index ID: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_FrameLigIndex | Write-Verbose

								}	

								ForEach ($_LigEntry in $_FrameLig)
								{

									'[{0}] Processing LIG: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_LigEntry.name | Write-Verbose

									if (('sas-logical-interconnect-groups' -eq $_LigEntry.category) -or ('-1' -contains $_LigEntry.enclosureIndexes))
									{

										'[{0}] Frame LIG is either Natasha or Carbon, storing EnclosureIndexID from FrameLigIndex: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_FrameLigIndex | Write-Verbose

										$_EnclosureIndexID = $_FrameLigIndex

									}

									else
									{

										$_EnclosureIndexID = $null

									}

									if ('logical-interconnect-groups','sas-logical-interconnect-groups' -notcontains $_LigEntry.category)
									{

										$Message     = "The provided Logical Interconnect Group value for Bay {0} is not a valid Logical Interconnect Group Object {1}." -f $_LigEntry.Name, $_LigEntry.Value.category
										$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidLogicalInterconnectGroupCategory InvalidType 'LogicalInterconnectGroupMapping' -TargetType 'PSObject' -Message $Message
									
										$PSCmdlet.ThrowTerminatingError($ErrorRecord)

									}					

									if ($_LigEntry.enclosureType -NotMatch 'SY')
									{

										$Message     = "The provided Logical Interconnect Group {0} is modeled for the HPE BladeSystem C7000 enclosure type.  Please provide a Synergy Logical Interconnect Grou presource, and try again." -f $_LigEntry.name
										$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidLogicalInterconnectGroupCategory InvalidType 'LogicalInterconnectGroupMapping' -TargetType 'PSObject' -Message $Message
									
										$PSCmdlet.ThrowTerminatingError($ErrorRecord)

									}
									
									# Loop through InterconnectMapTemplate Entries
									ForEach ($_InterconnectMapTemplate in $_LigEntry.interconnectMapTemplate.interconnectMapEntryTemplates)
									{

										# Detect I3S setting in the Uplink Sets of the LIG
										if (-not $_I3SSettingsFound)
										{
											
											$_I3SSettingsFound = $_LigEntry.uplinkSets | Where-Object ethernetNetworkType -eq 'ImageStreamer'
										
										}

										$_InterconnectBayMapping = NewObject -InterconnectBayMapping

										$_InterconnectBayMapping.enclosureIndex              = if (-not $_EnclosureIndexID) { $_InterconnectMapTemplate.enclosureIndex } else { $_EnclosureIndexID }
										$_InterconnectBayMapping.interconnectBay             = ($_InterconnectMapTemplate.logicalLocation.locationEntries | Where-Object type -eq 'Bay').relativeValue
										$_InterconnectBayMapping.logicalInterconnectGroupUri = $_LigEntry.uri 

										# If LIG is not present in the EG interconnectBayMapping
										if ((Compare-Object $_EnclosureGroup.interconnectBayMappings -DifferenceObject $_InterconnectBayMapping -Property enclosureIndex,interconnectBay,logicalInterconnectGroupUri -IncludeEqual).SideIndicator -notcontains '==') 
										{

											'[{0}] Mapping Frame {1} Bay {2} -> {3} ({4})' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_InterconnectBayMapping.enclosureIndex, $_InterconnectBayMapping.interconnectBay, $_LigEntry.Name, $_LigEntry.uri | Write-Verbose

											[void]$_EnclosureGroup.interconnectBayMappings.Add($_InterconnectBayMapping)

											$_c++

										}
										
									}

								}	

							}

						}

						ElseIf ($LogicalInterconnectGroupMapping -is [PSCustomObject] -and ('logical-interconnect-groups','sas-logical-interconnect-groups' -contains $LogicalInterconnectGroupMapping.category))
						{

							if ($LogicalInterconnectGroupMapping.enclosureType -NotMatch 'SY')
							{

								$Message     = "The provided Logical Interconnect Group {0} is modeled for the HPE BladeSystem C7000 enclosure type.  Please provide a Synergy Logical Interconnect Group resource, and try again." -f $LogicalInterconnectGroupMapping.name
								$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidLogicalInterconnectGroupCategory InvalidType 'LogicalInterconnectGroupMapping' -TargetType 'PSObject' -Message $Message
								
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

							# Detect I3S setting in the Uplink Sets of the LIG
							$_I3SSettingsFound = $LogicalInterconnectGroupMapping.uplinkSets | Where-Object ethernetNetworkType -eq 'ImageStreamer'

							ForEach ($_InterconnectMapEntry in $LogicalInterconnectGroupMapping.interconnectMapTemplate.interconnectMapEntryTemplates)
							{

								ForEach ($_LocationEntry in ($_InterconnectMapEntry.logicalLocation.locationEntries | Where-Object type -eq 'Bay'))
								{

									if (-not($_EnclosureGroup.interconnectBayMappings | Where-Object interconnectBay -eq $_LocationEntry.relativeValue))
									{

										$_InterconnectBayMapping = NewOBject -InterconnectBayMapping

										$_InterconnectBayMapping.interconnectBay             = ($_LocationEntry | Where-Object type -eq 'bay').relativeValue
										$_InterconnectBayMapping.logicalInterconnectGroupUri = $LogicalInterconnectGroupMapping.uri

										$_InterconnectBayMapping = $_InterconnectBayMapping | Select-Object * -ExcludeProperty enclosureIndex

										'[{0}] Mapping Interconnect Bay to LIG URI {1} --> {2}' -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_LocationEntry | Where-Object type -eq 'bay').relativeValue, $LogicalInterconnectGroupMapping.uri | Write-Verbose 

										"[{0}] Interconnect Bay Mapping Entry found in LIG resource:  {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), $_LocationEntry | Write-Verbose 

										[void]$_EnclosureGroup.interconnectBayMappings.Add($_InterconnectBayMapping)

									} 

									$_c++

								}

							}

						}

						else
						{

							'[{0}] Invalid LIG Category value provided: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), ($LogicalInterconnectGroupMapping | Out-String) | Write-Verbose

							$Message     = "Invalid LogicalInterconnectGroupMapping value provided '{0}'.  Please check the value and try again." -f ($LogicalInterconnectGroupMapping )
							$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidLogicalInterconnectGroupCategory InvalidType 'LogicalInterconnectGroupMapping' -TargetType $LogicalInterconnectGroupMapping.GetType().Fullname -Message $Message
								
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						# $_EnclosureGroup.interconnectBayMappingCount = $_c

						if (-not($PSBoundParameters['EnclosureCount']))
						{

							if ($LogicalInterconnectGroupMapping -is [System.Collections.IEnumerable])
							{

								$_EnclosureGroup.enclosureCount = $LogicalInterconnectGroupMapping.Count

							}

							else
							{

								$_EnclosureGroup.enclosureCount = $LogicalInterconnectGroupMapping.enclosureIndexes.Count

							}

						}

						else
						{

							$_EnclosureGroup.enclosureCount = $EnclosureCount

						}

						$_DeploymentSettings                = NewObject -EnclosureGroupI3SDeploymentSettings
						$_DeploymentSettings.deploymentMode = $DeploymentNetworkType

						$_EnclosureGroup.osDeploymentSettings = NewObject -DeploymentModeSettings

						# // Need to update error message that I3S Setting was detected in LIG but no DeploymentSetting defined in EG params.
						if ($DeploymentNetworkType -eq 'None' -and $_I3SSettingsFound)
						{

							$Message     = "The provided LogicalInterconnectGroupMapping Parameter contains 1 or more LIGs with an ImageStreamer Uplink Set configured, but no DeploymentNetwork or DeploymentNetworkType Parameter were provided.  You must specify a DeploymentNetwork and DeploymentNetworkType cannot be 'none'."
							$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidDeploymentNetworkSettings InvalidArgument 'DeploymentNetworkType' -TargetType 'PSObject' -Message $message
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)   

						}

						elseif ($DeploymentNetworkType -ne 'None')
						{
							
							$_EnclosureGroup.osDeploymentSettings.manageOSDeployment = $true	

							if ($DeploymentNetworkType -eq 'External')
							{

								if (-not $DeploymentNetwork)
								{

									'[{0}] DeploymentNetworkType is set to "External", but no DeploymentNetwork value.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

									$Message     = "The DeploymentNetworkType was set to 'External', which requires the DeploymentNetwork parameter."
									$ErrorRecord = New-ErrorRecord InvalidOperationException NullDeploymentNetwork InvalidArgument 'DeploymentNetworkType' -TargetType 'SwitchParameter' -Message $Message

									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								switch ($DeploymentNetwork.GetType())
								{

									'PSCustomObject'
									{

										if ($DeploymentNetworkType.category -ne 'ethernet-networks')
										{

											$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidEthernetNetworkResource InvalidArgument 'DeploymentNetworkType' -TargetType 'PSObject' -Message "The provided Deployment Network resource object is not an Ethernet Network.  Please validate the Parameter value and try again."
											$PSCmdlet.ThrowTerminatingError($ErrorRecord)   

										}

										if ($DeploymentNetworkType.ethernetNetworkType -ne 'Tagged')
										{

											$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidEthernetNetworkResource InvalidArgument 'DeploymentNetworkType' -TargetType 'PSObject' -Message "The provided Deployment Network resource object is not a 'Tagged' Ethernet Network.  Please validate the Parameter value and try again."
											$PSCmdlet.ThrowTerminatingError($ErrorRecord)   

										}

									}

									'String'
									{

										Try
										{

											$DeploymentNetwork = Get-HPOVNetwork -Name $DeploymentNetwork -ApplianceConnection $ApplianceConnection -ErrorAction Stop

										}

										Catch
										{

											$PSCmdlet.ThrowTerminatingError($_)

										}

										if ($DeploymentNetwork.ethernetNetworkType -ne 'Tagged')
										{


											$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidEthernetNetworkResource InvalidArgument 'DeploymentNetwork' -Message "The provided Deployment Network resource object is not a 'Tagged' Ethernet Network.  Please validate the Parameter value and try again."
											$PSCmdlet.ThrowTerminatingError($ErrorRecord)   

										}

									}

								}
		
								$_DeploymentSettings.deploymentNetworkUri = $DeploymentNetwork.uri			

							}

						}

						$_EnclosureGroup.osDeploymentSettings.deploymentModeSettings = $_DeploymentSettings	

						$_EnclosureGroup.ipAddressingMode = $EnclosureGroupIpAddressModeEnum[$IPv4AddressType]

						foreach ($_Pool in $AddressPool)
						{

							# "[{0}] IPv4 Pool Object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_Pool ) | Write-Verbose

							if ($_Pool.category -ne 'id-range-IPv4')
							{
						
								$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolResourceException InvalidAddressPoolResource InvalidArgument 'AddressPool' -TargetType 'PSObject' -Message "An invalid Address Pool object was provided.  Please check the value and try again."
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)
						
							}

							[void]$_EnclosureGroup.ipRangeUris.Add($_Pool.uri)

						}					

					}

				}

				{'C7000','DiscoverFromEnclosure' -contains $_}
				{

					# Process LIG Object here, and will be on a single Appliance Connection
					if ($LogicalInterconnectGroupMapping -is [PSCustomObject]) 
					{ 
			
						"[{0}] Single LIG Object:  {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnectGroupMapping.name | Write-Verbose

						# Check to make sure the object is a LIG, generate error if not
						if ($LogicalInterconnectGroupMapping.category -ne 'logical-interconnect-groups')
						{

							"[{0}] Invalid LIG Category value provided '$($LogicalInterconnectGroupMapping.category)'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidLogicalInterconnectGroupCategory InvalidType 'LogicalInterconnectGroupMapping' -TargetType 'PSObject' -Message "Invalid [PSObject] value provided '$LogicalInterconnectGroupMapping'.  Logical Interconnect Group category must Begin with 'logical-interconnect-groups'.  Please check the value and try again."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						"[{0}] Will Process {1} Interconnect Bay Logical Location Entries in LIG Object." -f $MyInvocation.InvocationName.ToString().ToUpper(), ($LogicalInterconnectGroupMapping.interconnectMapTemplate.interconnectMapEntryTemplates.logicalLocation | Measure-Object).Count | Write-Verbose

						$_c = 1

						# Process Interconnect Bay Mapping, which is 1 LIG
						ForEach ($_LigBayMapping in $LogicalInterconnectGroupMapping.interconnectMapTemplate.interconnectMapEntryTemplates)
						{

							"[{0}] Processing {1} of {2} Bay Mappings" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_c, ($LogicalInterconnectGroupMapping.interconnectMapTemplate.interconnectMapEntryTemplates.logicalLocation | Measure-Object).Count | Write-Verbose

							$_InterconnectBayMapping = NewOBject -InterconnectBayMapping

							$_InterconnectBayMapping.interconnectBay             = ($_LigBayMapping.logicalLocation.locationEntries | Where-Object type -EQ 'bay').relativeValue
							$_InterconnectBayMapping.logicalInterconnectGroupUri = $LogicalInterconnectGroupMapping.uri

							"[{0}] Interconnect Bay '{1}' Mapping Entry found in LIG resource." -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_LigBayMapping.logicalLocation.locationEntries | Where-Object type -EQ 'bay').relativeValue | Write-Verbose

							[void]$_EnclosureGroup.interconnectBayMappings.Add($_InterconnectBayMapping)

							$_c++

						}

					}

					elseif ($LogicalInterconnectGroupMapping -is [System.Collections.IEnumerable] -and $LogicalInterconnectGroupMapping -isnot [String])
					{

						ForEach ($_key in $LogicalInterconnectGroupMapping.Keys)
						{

							"[{0}] Processing Hashtable key '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_key | Write-Verbose

							$_InterconnectBayMapping = NewOBject -InterconnectBayMapping

							switch (($LogicalInterconnectGroupMapping.$_key).GetType().Name)
							{

								'PSCustomObject'
								{

									# Validate object is a LIG
									if (-not(($LogicalInterconnectGroupMapping.$_key).category -eq 'logical-interconnect-groups'))
									{

										"[{0}] Invalid [PSCustomObject] value provided '{1}' for '{2}' Hashtable entry." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnectGroupMapping.$_key.category, $_key | Write-Verbose
									
										$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidLogicalInterconnectGroupMappingObject InvalidArgument 'LogicalInterconnectGroupMapping' -TargetType 'PSObject' -Message "Invalid [PSCustomObject] value provided '$(($LogicalInterconnectGroupMapping.$_key).category)' for '$_key' Hashtable entry.  Logical Interconnect Group object category must be 'logical-interconnect-groups'.  Please check the value and try again."
										$PSCmdlet.ThrowTerminatingError($ErrorRecord)

									}

									$_InterconnectBayMapping.interconnectBay             = ((($LogicalInterconnectGroupMapping.$_key).interconnectMapTemplate.interconnectMapEntryTemplates.LogicalLocation.locationEntries) | Where-Object { $_.type -EQ 'bay' -and $_.relativeValue -EQ $_key}).relativeValue
									$_InterconnectBayMapping.logicalInterconnectGroupUri = ($LogicalInterconnectGroupMapping.$_key).uri

									"[{0}] Interconnect Bay Mapping Entry:  $($_InterconnectBayMapping)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								}

								'String'
								{

									# Value is an Objects URI
									if (($LogicalInterconnectGroupMapping.$_key).StartsWith($logicalInterconnectGroupUri))
									{

										$_InterconnectBayMapping.interconnectBay             = $_key
										$_InterconnectBayMapping.logicalInterconnectGroupUri = $LogicalInterconnectGroupMapping.$_key

										"[{0}] Interconnect Bay Mapping Entry:  $($_InterconnectBayMapping)"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

									}

									# Object Name value
									else
									{

										Try
										{
									
											$_LogicalInterconnectGroupObject = Get-HPOVLogicalInterconnectGroup $LogicalInterconnectGroupMapping.$_key -ApplianceConnection $ApplianceConnection.Name

											$_InterconnectBayMapping.interconnectBay             = $_key
											$_InterconnectBayMapping.logicalInterconnectGroupUri = $_LogicalInterconnectGroupObject.uri
									
										}
									
										Catch
										{

											$PSCmdlet.ThrowTerminatingError($_)

										}

									}

								}

							}

							[void]$_EnclosureGroup.interconnectBayMappings.Add($_InterconnectBayMapping)

						}

					}

					else
					{

						'[{0}] Invalid LIG Category value provided: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), ($LogicalInterconnectGroupMapping | Out-String) | Write-Verbose

						$Message     = "Invalid LogicalInterconnectGroupMapping value provided '{0}'.  Please check the value and try again." -f ($LogicalInterconnectGroupMapping.ToString())
						$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidLogicalInterconnectGroupCategory InvalidType 'LogicalInterconnectGroupMapping' -TargetType $LogicalInterconnectGroupMapping.GetType().Fullname -Message $Message
							
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if (($_EnclosureGroup.interconnectBayMappings | Measure-Object).count -lt 8)
					{

						"[{0}] Adding null interconnectBayMapping entries."  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						for ($b = 8 - $_EnclosureGroup.interconnectBayMappings.count; $b -ne 0; $b--)
						{

							$_InterconnectBayMapping = NewObject -InterconnectBayMapping

							$n = 1

							do
							{

								$_bayId = $null

								if (-not($_EnclosureGroup.interconnectBayMappings | Where-Object interconnectBay -eq $n))
								{

									$_bayId = $n

								}

								# ERROR, we should never get more than the number of $_EnclosureGroup.interconnectBayMappingCount
								if ($n -gt 8)
								{

									$ErrorRecord = New-ErrorRecord System.InvalidOperationException InvalidOperation InvalidOperation 'InterconnectBayMappingCount' -TargetType 'Int' -Message "Could not determine Enclosure Group interconnectBay ID (`$_bayId). (`$n = $n)"

									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								$n++

							}
							until ($_bayId)

							$_InterconnectBayMapping.interconnectBay = $_bayId

							[void]$_EnclosureGroup.interconnectBayMappings.Add($_InterconnectBayMapping)

						}
			
					}

					$_EnclosureGroup.configurationScript = $ConfigurationScript

				}

			}

			#  "[$($MyInvocation.InvocationName.ToString().ToUpper())] Enclosure Group object: $($_EnclosureGroup | Format-List * )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Creating '{1}' Enclosure Group" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_EnclosureGroup.name | Write-Verbose

			Try
			{

				$resp = Send-HPOVRequest -Uri $EnclosureGroupsUri -Method POST -Body $_EnclosureGroup -Hostname $ApplianceConnection.Name

				$resp.PSObject.TypeNames.Insert(0,'HPOneView.EnclosureGroup')

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		[void]$_EnclosureGroupCreateResults.Add($resp)

	}

	End 
	{

		return $_EnclosureGroupCreateResults

	}

}
