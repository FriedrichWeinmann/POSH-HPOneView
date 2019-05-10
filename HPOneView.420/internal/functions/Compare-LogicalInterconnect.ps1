Function Compare-LogicalInterconnect
{

    [CmdletBinding ()]
    Param
    (

        [Parameter (Mandatory, HelpMessage = "Please provide the Encloure or Logical Interconnect object.")]
        [ValidateNotNullorEmpty()]
		[Object]$InputObject

    )

    Begin
    {

		$ApplianceConnection = $InputObject.ApplianceConnection

        Try
        {
		
			'Getting all configured Uplink Set objects.' -f $_LigUplinkSet.name | Write-Verbose #-Verbose
			$UplinkSets = Get-HPOVUplinkSet -ApplianceConnection $ApplianceConnection.Name
			
			'Getting all Interconnect Types objects.' -f $_LigUplinkSet.name | Write-Verbose #-Verbose
            $InterconnectTypes = Get-HPOVInterconnectType -ApplianceConnection $ApplianceConnection.Name
        
        }
        
        Catch
        {
        
            $PSCmdlet.ThrowTerminatingError($_)
        
        }

    }

    Process
    {


        $CompareObject            = New-Object System.Collections.ArrayList
        $_LogicalInterconnects    = New-Object System.Collections.ArrayList   # Logical Interconnect Uris; not sure what this is used for yet.
        $InterconnectMap          = New-Object System.Collections.ArrayList   # Collection of Interconnects?
        $InterconnectMapTemplate  = New-Object System.Collections.ArrayList
        $SideIndicator            = @{ Parent = '<='; Child = '=>'; NotEqual = '<=>'}

		function CompareInterconnects ($_LogicalInterconnect, $_LogicalInterconnectGroup) 
		{

            "Processing Logical Interconnect '{0}' and LIG '{1}'" -f $_LogicalInterconnect.name, $_LogicalInterconnectGroup.name | Write-Verbose #-Verbose

            #Build array of expected Interconnects within LIG
            foreach ($InterconnectMapEntryGroup in $_LogicalInterconnectGroup.interconnectMapTemplate.interconnectMapEntryTemplates) 
            {

                if ($InterconnectMapEntryGroup.permittedInterconnectTypeUri) 
                {

                    [void]$InterconnectMapTemplate.Add([PSCustomObject]@{
                        bayNumber           = ($InterconnectMapEntryGroup.logicalLocation.locationEntries | Where-Object type -eq "BAY").relativeValue; 
                        InterconnectTypeUri = $InterconnectMapEntryGroup.permittedInterconnectTypeUri
                    })
            
                }

            }

            
            #$InterconnectMap = New-Object System.Collections.ArrayList
			#Build array of actual Interconnects in LI
            foreach ($_InterconnectMapEntry in $_LogicalInterconnect.InterconnectMap.interconnectMapEntries) 
            {

                if ($_InterconnectMapEntry.permittedInterconnectTypeUri) 
                {

                    [void]$InterconnectMap.Add([PSCustomObject]@{
                        bayNumber           = ($_InterconnectMapEntry.location.locationEntries | Where-Object type -eq "Bay").value; 
                        InterconnectTypeUri = $_InterconnectMapEntry.permittedInterconnectTypeUri
                    })

                }

            }

            $diff = Compare-Object -ReferenceObject $InterconnectMapTemplate -DifferenceObject $InterconnectMap -Property bayNumber, InterconnectTypeUri -IncludeEqual

            foreach ($d in $diff) 
			{

                'Processing LI with LIG DIFF' | Write-Verbose #-Verbose

                $InterconnectType = $InterconnectTypes | Where-Object { $_.uri -eq $d.InterconnectTypeUri }

                if ($d.SideIndicator -eq "==") 
				{

                    'Expected Interconnect in "{0}" matches Group for Interconnect bay "{1}" type "{2}"' -f $_LogicalInterconnect.name,  $d.bayNumber, $InterconnectType.name | Write-Verbose #-Verbose
               
				} 
				
				else 
				{

                    if ($d.SideIndicator -eq $SideIndicator.Parent) 
					{

                        $_diff = New-Object HPOneView.Library.CompareObject($d.bayNumber,
																			$SideIndicator.Child,
																			$InterconnectType.name,
																			$null,
                                                                            $_LogicalInterconnectGroup.name,
                                                                            $_LogicalInterconnect.name,
																			'MISSING_MODULE')

                        [void]$CompareObject.Add($_diff)

						'"{0}" Logical Interconnect is currently missing expected module "{1}" within Interconnect bay "{2}" ' -f $_LogicalInterconnect.name, $InterconnectType.name, $d.bayNumber | Write-Verbose
						
                    }
					
					elseif ($d.SideIndicator -eq $SideIndicator.Child)  
					{

						$_diff = New-Object HPOneView.Library.CompareObject($d.bayNumber,
																			$SideIndicator.Parent,
																			$InterconnectType.name,
																			$null,
																			$_LogicalInterconnectGroup.name,
																			$_LogicalInterconnect.name,
																			'EXTRA_MODULE')

						[void]$CompareObject.Add($_diff)

						'"{0}" Logical Interconnect contains an extra module "{1}" within Interconnect bay "{2}" ' -f $_LogicalInterconnect.name, $InterconnectType.name, $d.bayNumber | Write-Verbose

					}

                }

            }

            # Process Ethernet Settings
            $EthernetSettingsProperties = "enableIgmpSnooping", "igmpIdleTimeoutInterval", "enableFastMacCacheFailover", "macRefreshInterval", "enableNetworkLoopProtection", "enablePauseFloodProtection", "enableRichTLV", "enableTaggedLldp"
            $EthernetSettingsDiff = New-Object System.Collections.Arraylist

            if ($_LogicalInterconnectGroup.category -ne 'sas-logical-interconnect-groups')
            {

                ForEach ($Property in $EthernetSettingsProperties)
                {

                    if ($_LogicalInterconnectGroup.ethernetSettings.$Property -ne $_LogicalInterconnect.ethernetSettings.$Property)
                    {

                        $_diff = New-Object HPOneView.Library.CompareObject($Property, 
                                                                            $SideIndicator.NotEqual, 
                                                                            $_LogicalInterconnectGroup.ethernetSettings.$Property, 
                                                                            $_LogicalInterconnect.ethernetSettings.$Property, 
                                                                            $_LogicalInterconnectGroup.name,
                                                                            $_LogicalInterconnect.name,
                                                                            'SETTING_MISMATCH')

                        [void]$EthernetSettingsDiff.Add($_diff)
                        [void]$CompareObject.Add($_diff)

                    }

                }

                ForEach ($diff in $EthernetSettingsDiff)
                {

                    'Logical Interconnect "{0}" Ethernet Setting "{1}" does not match the parent "{2}" setting.' -f $diff.InputObject, $diff.ChildSetting, $diff.ParentSetting | Write-Verbose

                }

            # }

			# if ($_LogicalInterconnectGroup.category -ne 'sas-logical-interconnect-groups')
			# {

				# Process QoS
				$_diff = Compare-Object -ReferenceObject $_LogicalInterconnectGroup.qosConfiguration.activeQosConfig.configType -DifferenceObject $_LogicalInterconnect.qosConfiguration.activeQosConfig.configType -PassThru

				if ($_diff.SideIndicator -eq $SideIndicator.Parent)
				{

					$_diff = New-Object HPOneView.Library.CompareObject('ActiveQosConfig', 
																		$SideIndicator.Parent, 
																		$_LogicalInterconnectGroup.qosConfiguration.activeQosConfig.configType, 
																		$_LogicalInterconnect.qosConfiguration.activeQosConfig.configType, 
																		$_LogicalInterconnectGroup.name,
																		$_LogicalInterconnect.name,
																		'SETTING_MISMATCH')

					[void]$CompareObject.Add($_diff)

				}

				elseif ($_diff.SideIndicator -eq $SideIndicator.Child)
				{

					$_diff = New-Object HPOneView.Library.CompareObject('ActiveQosConfig', 
																		$SideIndicator.Child, 
																		$_LogicalInterconnectGroup.qosConfiguration.activeQosConfig.configType, 
																		$_LogicalInterconnect.qosConfiguration.activeQosConfig.configType, 
																		$_LogicalInterconnectGroup.name,
																		$_LogicalInterconnect.name,
																		'SETTING_MISMATCH')

					[void]$CompareObject.Add($_diff)
					
				}

			}

		}
		
        function GetUplinkSets ($_LI, $_LIG) 
        {

            'Processing Uplink Set objects' | Write-Verbose #-Verbose
            'LI: {0} [{1}]' -f $_LI.name,$_LI.uri | Write-Verbose #-Verbose
            'LIG: {0}' -f $_LIG.name | Write-Verbose #-Verbose
            'Number of LIG Uplink Sets: {0}' -f $_LIG.uplinkSets.count | Write-Verbose #-Verbose
			'Number of matched Uplink Sets to LI: {0}' -f ($UplinkSets | Where-Object logicalInterconnectUri -eq $_LI.uri).Count | Write-Verbose #-Verbose
			
			if (($UplinkSets | Where-Object logicalInterconnectUri -eq $_LI.uri).Count -gt $_LIG.uplinkSets.Count)
			{

				'Number of Unmatched Uplink Sets to LI: {0}' -f (($UplinkSets | Where-Object logicalInterconnectUri -eq $_LI.uri).Count - $_LIG.uplinkSets.Count) | Write-Verbose #-Verbose

			}

			else
			{

				'Number of Unmatched Uplink Sets to LIG: {0}' -f ($_LIG.uplinkSets.Count - ($UplinkSets | Where-Object logicalInterconnectUri -eq $_LI.uri).Count) | Write-Verbose #-Verbose
			
			}
            
			$myLUs = New-Object System.Collections.ArrayList
			
			'Processing LIG policy for undefined Uplink Sets within LI.' -f $_LigUplinkSet.name | Write-Verbose #-Verbose
			
			ForEach ($_LigUplinkSet in $_LIG.uplinkSets)
            {

                'Looking for unprovisioned LIG Uplink Set: {0}' -f $_LigUplinkSet.name | Write-Verbose #-Verbose

                if (($UplinkSets | Where-Object logicalInterconnectUri -eq $_LI.uri).name -notcontains $_LigUplinkSet.name)
                {

                    '{0} is not provisioned within LI.' -f $_LigUplinkSet.name | Write-Verbose #-Verbose

                    $MissingUplinkSet = NewObject -liUplinkSetObject
					$MissingUplinkSet.name = "Missing"
					Add-Member -InputObject $MissingUplinkSet -NotePropertyName UplinkSetGroup -NotePropertyValue $null -Force
					Add-Member -InputObject $MissingUplinkSet -NotePropertyName LogicalInterconnectName -NotePropertyValue $_LI.name
					Add-Member -InputObject $MissingUplinkSet.UplinkSetGroup -NotePropertyName LogicalInterconnectGroupName -NotePropertyValue $_LIG.name                   
                    [void]$myLUs.Add($MissingUplinkSet)
                    
                }

            }

			# Inject LIG Uplink Set object into LI for further matching later
            foreach ($lu in ($UplinkSets | Where-Object logicalInterconnectUri -eq $_LI.uri)) 
            {

				"Match on: {0}" -f $lu.logicalInterconnectUri | Write-Verbose #-Verbose

				Add-Member -InputObject $lu -NotePropertyName UplinkSetGroup -NotePropertyValue $null -Force
				Add-Member -InputObject $lu -NotePropertyName LogicalInterconnectName -NotePropertyValue $_LI.name
				$lu.UplinkSetGroup = $_LIG.uplinkSets | Where-Object name -eq $lu.name
				
				# If LIG Uplink Set doesn't exist, add placebo
				if ($null -eq $lu.UplinkSetGroup)
				{

					'Uplink Set "{0}" is not defined in the LIG.' -f $_LigUplinkSet.name | Write-Verbose #-Verbose
					
					$MissingLIGUplinkSet = MissingUplinkSetFromLIG
					$MissingLIGUplinkSet.UplinkSetGroup               = $_LigUplinkSet
					$MissingLIGUplinkSet.LogicalInterconnectUri       = $_LI.uri
					$MissingLIGUplinkSet.LogicalInterconnectName      = $_LI.name
					$MissingLIGUplinkSet.LogicalInterconnectGroupName = $_Lig.name

				}

				else
				{

					'Uplink Set "{0}" exists in both LI and LIG.' -f $_LigUplinkSet.name | Write-Verbose #-Verbose

					Add-Member -InputObject $lu.UplinkSetGroup -NotePropertyName LogicalInterconnectGroupName -NotePropertyValue $_LIG.name

				}
				
				[void]$myLUs.Add($lu)

			}
			
            # Need to add a check here for when the LIG Uplink Set(s) differe from LI, not what matches from LI to global Uplink Sets
			return $myLUs
			
        }

        function GetPortName ($bay, $portNumber) 
        {
            
            'Getting name for port Bay: {0}; Port Number: {1}' -f $Bay, $PortNumber | Write-Verbose #-Verbose
            

            # This function uses the Interconnect map Group set up in CompareInterconnects
            $InterconnectMapEntry = $InterconnectMapTemplate | Where-Object bayNumber -eq $bay
            "InterconnectType: {0}" -f $InterconnectMapEntry | Write-Verbose #-Verbose

            $InterconnectModuleType = $InterconnectTypes | Where-Object uri -eq $InterconnectMapEntry.InterconnectTypeUri
            "Interconnect Module Type: {0}" -f $InterconnectModuleType | Write-Verbose #-Verbose

            "Uplink Port Name: {0}" -f ($InterconnectModuleType.portInfos | Where-Object portNumber -eq $PortNumber).portName | Write-Verbose #-Verbose
            Return ($InterconnectModuleType.portInfos | Where-Object portNumber -eq $PortNumber).portName

        }

        function CompareNetworks ($lu, $lut) 
        {

            'Examining Networks associated with Uplink Set "{0}"' -f $lu.name | Write-Verbose #-Verbose

            switch ($lu.networkType)
            {

                'FibreChannel'
                {

                    'Processing Fibre Channel Uplink Set' | Write-Verbose #-Verbose

                    if ($lu.fcNetworkUris.Count -ne $lut.networkUris.Count) 
                    {

                        '{0} currently has {1} FC networks, Group has {2}' -f $lu.name, $lu.fcNetworkUris.Count, $lut.networkUris.Count | Write-Verbose
                    
					}
					
					if ($null -eq $lut.fcNetworkUris) 
					{

						$diff = [PSCustomObject]@{InputObject = $lu.fcNetworkUris; SideIndicator = "=>"}

					}

					elseif ($null -eq $lu.fcNetworkUris) 
					{

						$diff = [PSCustomObject]@{InputObject = $lut.fcNetworkUris; SideIndicator = "<="}

					}

					else
					{

						$diff = Compare-Object -ReferenceObject $lu.fcNetworkUris -DifferenceObject $lut.networkUris

					}

                }

                'Ethernet'
                {

                    'Processing Ethernet Uplink Set' | Write-Verbose #-Verbose

                    if ($lu.networkUris.Count -ne $lut.networkUris.Count) 
                    {
                        
                        '{0} currently has {1} Ethernet networks, Group has {2}' -f $lu.name, $lu.networkUris.Count, $lut.networkUris.Count | Write-Verbose
                        
					}
					
					if ($null -eq $lut.networkUris) 
					{

						$diff = [PSCustomObject]@{InputObject = $lu.networkUris; SideIndicator = "=>"}

					}

					elseif ($null -eq $lu.networkUris) 
					{

						$diff = [PSCustomObject]@{InputObject = $lut.networkUris; SideIndicator = "<="}

					}

					else
					{

						$diff = Compare-Object -ReferenceObject $lu.networkUris -DifferenceObject $lut.networkUris

					}                   

                }

            }
            
            foreach ($d in $diff) 
            {

				ForEach ($_uri in $d.InputObject)
				{

					Try
					{
					
						$net = Send-HPOVRequest -Uri $_uri -Hostname $ApplianceConnection
					
					}
					
					Catch
					{
					
						$PSCmdlet.ThrowTerminatingError($_)
					
					}

					if ($d.SideIndicator -eq $SideIndicator.Child)
					{
	
						$_diff = New-Object HPOneView.Library.CompareObject($lu.name, 
																			$SideIndicator.Parent, 
																			$net.name,
																			$null, 
																			$lut.LogicalInterconnectGroupName,
																			$lu.LogicalInterconnectName,
																			'MISSING_NETWORK')
	
						[void]$CompareObject.Add($_diff)
	
						'{0} is currently missing network {1} VLAN {2}' -f $lu.name, $net.name, $net.vlanId | Write-Verbose
	
					} 
					
					else 
					{
	
						$_diff = New-Object HPOneView.Library.CompareObject($lu.name, 
																			$SideIndicator.Child, 
																			$null,
																			$net.name, 
																			$lut.LogicalInterconnectGroupName,
																			$lu.LogicalInterconnectName,
																			'EXTRA_NETWORK')
						[void]$CompareObject.Add($_diff)
	
						'{0} currently has extra network {1} VLAN {2}' -f $lu.name, $net.name, $net.vlanId | Write-Verbose
	
					}

				}

            }

        }

		function CompareLocalNetworks ($li, $lig) 
        {

            'Examining Internal Networks' | Write-Verbose #-Verbose

			if ($li.internalNetworkUris.Count -ne $lig.internalNetworkUris.Count) 
			{
				
				'{0} currently has {1} Internal Ethernet networks, Group has {2}' -f $li.name, $li.internalNetworkUris.Count, $lig.internalNetworkUris.Count | Write-Verbose
				
			}

			$diff = Compare-Object -ReferenceObject $lig.internalNetworkUris -DifferenceObject $li.internalNetworkUris

            
            foreach ($d in $diff) 
            {

                Try
                {
                
                    $net = Send-HPOVRequest $d.InputObject
                
                }
                
                Catch
                {
                
                    PSCmdlet.ThrowTerminatingError($_)
                
                }
                
                if ($d.SideIndicator -eq $SideIndicator.Parent) 
                {

                    $_diff = New-Object HPOneView.Library.CompareObject('InternalNetworks', 
                                                                        $SideIndicator.Child, 
																		$net.name,
                                                                        $null,                                                                         
                                                                        $lig.name,
                                                                        $li.name,
                                                                        'MISSING_NETWORK')

                    [void]$CompareObject.Add($_diff)

                    '{0} is currently missing internal network {1} VLAN {2}' -f $li.name, $net.name, $net.vlanId | Write-Verbose

                } 
                
                else 
                {

                    $_diff = New-Object HPOneView.Library.CompareObject('InternalNetworks', 
                                                                        $SideIndicator.Parent, 
                                                                        $null,
                                                                        $net.name, 
                                                                        $lig.name,
                                                                        $li.name,
                                                                        'EXTRA_NETWORK')
                    [void]$CompareObject.Add($_diff)

                    '{0} currently has extra network {1} VLAN {2}' -f $li.name, $net.name, $net.vlanId | Write-Verbose

                }

            }

        }

        function ComparePorts ($lu, $lut) 
        {

            "Comparing ports" | Write-Verbose #-Verbose

            "Uplink Set Port count: {0}" -f $lu.portConfigInfos.Count | Write-Verbose #-Verbose
            "LIG Uplink Set Port count: {0}" -f $lut.logicalPortConfigInfos.Count | Write-Verbose #-Verbose

            if ($lu.portConfigInfos.Count -ne $lut.logicalPortConfigInfos.Count) 
            {

                '{0} currently has {1} ports, Group has {2}' -f $lu.name, $lu.portConfigInfos.Count, $lut.logicalPortConfigInfos.Count | Write-Verbose

            }

            #Build array of LU ports
            $luPorts = New-Object System.Collections.ArrayList
            $lutPorts = New-Object System.Collections.ArrayList

            # Process LIG Uplink Set Uplink Ports
            foreach ($upPorts in $lut.logicalPortConfigInfos) 
            {

                $Port = [PSCustomObject]@{ type = 'lut.portConfigInfos';bayNumber = $null; portNumber = $null; portName = $null; Speed = $null }

                foreach ($loc in $upPorts.logicalLocation.locationEntries) 
                {

                    $Port.Speed = $upPorts.desiredSpeed

                    if ($loc.type -eq "BAY") { $Port.bayNumber = $loc.relativeValue }

                    if ($loc.type -eq "PORT") { $Port.portNumber = $loc.relativeValue }

                }

                $Port.portName = GetPortName $Port.bayNumber $Port.portNumber

                [void]$lutPorts.Add($Port)

            }

			# // TODO: Logic here is incorrect and broken.  Not identifying the corect ports.
            # Process LI Uplink Set Uplink Ports
            foreach ($upPorts in $lu.portConfigInfos) 
            {

                $Port = [PSCustomObject]@{ type = 'lu.portConfigInfos';bayNumber = $null; portNumber = $null; portName = $null; Speed = $null }

                foreach ($loc in $upPorts.Location.locationEntries) 
                {

                    $Port.Speed = $upPorts.desiredSpeed

                    if ($loc.type -eq "BAY") { $Port.bayNumber = $loc.Value }

                    if ($loc.type -eq "PORT") { $Port.portName = $loc.Value }

                }

                [void]$luPorts.Add($Port)

            }

            $PortLocationDiff = Compare-Object -ReferenceObject $lutPorts -DifferenceObject $luPorts -Property bayNumber, portName

            'PortLocationDiff Object: {0}' -f ($PortLocationDiff | Out-String) | Write-Verbose #-Verbose

            foreach ($d in $PortLocationDiff) 
            {

                $Property = 'Bay{0}:{1}' -f $d.bayNumber, $d.portName

                if ($d.SideIndicator -eq $SideIndicator.Parent) 
                {

                    $_diff = New-Object HPOneView.Library.CompareObject($lu.name, 
                                                                        $SideIndicator.Child, 
                                                                        $Property, 
                                                                        $null, 
                                                                        $lut.LogicalInterconnectGroupName,
                                                                        $lu.LogicalInterconnectName,
                                                                        'MISSING_UPLINKPORT')
                    
                    [void]$CompareObject.Add($_diff)
                    
                    '{0} is currently missing port bay {1} port ' -f $lu.name, $d.bayNumber, $d.portName | Write-Verbose
                
                } 
                
                elseif ($d.SideIndicator -eq $SideIndicator.Child)  
                {

                    $_diff = New-Object HPOneView.Library.CompareObject($lu.name, 
                                                                        $SideIndicator.Parent, 
                                                                        $null, 
                                                                        $Property, 
                                                                        $lut.LogicalInterconnectGroupName,
                                                                        $lu.LogicalInterconnectName,
                                                                        'ADDITIONAL_UPLINKPORT')
                    
                    [void]$CompareObject.Add($_diff)
                    
                    '{0} currently has extra port on bay {1} port {2}' -f $lu.name, $d.bayNumber, $d.portName | Write-Verbose

                }

            }

            $PortSpeedDiff = Compare-Object -ReferenceObject $lutPorts -DifferenceObject $luPorts -Property Speed -PassThru

            'PortSpeedDiff Object: {0}' -f ($PortSpeedDiff | Out-String) | Write-Verbose #-Verbose

            foreach ($d in $PortSpeedDiff) 
            {

                if ($luPorts | Where-Object { $_.bayNumber -eq $d.bayNumber -and $_.portName -eq $d.portName} )
                {

                    $Property = '{0}:Bay{1}:{2}' -f $lut.name,$d.bayNumber, $d.portName

                    'luPort Object: {0}' -f (($luPorts | Where-Object { $_.bayNumber -eq $d.bayNumber -and $_.portName -eq $d.portName}) | Out-String) | Write-Verbose #-Verbose

                    if ($d.SideIndicator -eq '=>')
                    {

						$ParentValue = $null

						if ($lutPorts | Where-Object { $_.bayNumber -eq $d.bayNumber -and $_.portName -eq $d.portName})
						{

							$ParentValue = '{0}' -f $GetUplinkSetPortSpeeds[($lutPorts | Where-Object { $_.bayNumber -eq $d.bayNumber -and $_.portName -eq $d.portName}).Speed]

						}
                        
                        $ChildValue = '{0}' -f $GetUplinkSetPortSpeeds[$d.Speed]

                    }
                
                    elseif ($d.SideIndicator -eq '<=')
                    {

						$ChildValue = $null
						
						if ($luPorts | Where-Object { $_.bayNumber -eq $d.bayNumber -and $_.portName -eq $d.portName})
						{

							$ChildValue = '{0}' -f $GetUplinkSetPortSpeeds[($luPorts | Where-Object { $_.bayNumber -eq $d.bayNumber -and $_.portName -eq $d.portName}).Speed]

						}

                        $ParentValue = '{0}' -f $GetUplinkSetPortSpeeds[$d.Speed]                        

                    }

                    $_diff = New-Object HPOneView.Library.CompareObject($Property, 
                                                                        $SideIndicator.NotEqual, 
                                                                        $ParentValue, 
                                                                        $ChildValue, 
                                                                        $lut.LogicalInterconnectGroupName,
                                                                        $lu.LogicalInterconnectName,
                                                                        'LINKSPEED_MISMATCH')
                    
                    [void]$CompareObject.Add($_diff)

                    '{0} Uplink Port {1}:{2} has different link speed {3} than Group {4}' -f $lut.name, $d.bayNumber, $d.portName, $ParentValue, $ChildValue | Write-Verbose

                }

            }

        }

        function CompareUplinksWithGroup ($lu) 
        {

            $lut = $lu.UplinkSetGroup

            if (! $lut) 
            {
                
                '"{0}" Uplink Set has no matching LIG Uplink Set. Skipping.' -f $lu.name | Write-Verbose
                
            }

            if ($lu.name -eq 'missing')
            {

                '"{0}" Uplink Set within Logical Interconnect Group "{1}" is not provisioned or missing from Logical Interconnect "{2}"' -f $lut.name, $lu.LogicalInterconnectGroupName, $lu.LogicalInterconnectName | Write-Verbose

                $_diff = New-Object HPOneView.Library.CompareObject('UplinkSets',
                                                                    $SideIndicator.Child, 
                                                                    $lut.name, 
                                                                    $null, 
                                                                    $lu.LogicalInterconnectGroupName,
                                                                    $lu.LogicalInterconnectName,
                                                                    'MISSING_UPLINKSET')
                
                [void]$CompareObject.Add($_diff)

            }

            else 
            {

                'Comparing {0} Uplink Set with Group' -f $lu.name | Write-Verbose #-Verbose 

                'LU: {0}' -f $lu | Write-Verbose #-Verbose
                'LUT: {0}' -f $lut | Write-Verbose #-Verbose

                if ($lu.networkType -ne $lut.networkType) 
                {
                    
                    $_diff = New-Object HPOneView.Library.CompareObject(($lu.name + ':networkType'), 
                                                                        $SideIndicator.Parent, 
                                                                        $lut.networkType, 
                                                                        $lu.networkType,
                                                                        $lut.LogicalInterconnectGroupName,
                                                                        $lu.LogicalInterconnectName,
                                                                        'NETWORKTYPE_MISMATCH')
                    
                    [void]$CompareObject.Add($_diff)
                    
                    '"{0}" current Type "{1}" differs from Group Type "{2}"' -f $lu.name, $lu.networkType, $lut.networkType | Write-Verbose
                
                }

                if ($lu.connectionMode -ne $lut.mode) 
                {

					$LutPort = $null
					$LuPort = $null

					if ($lut.LogicalInterconnectGroupName)
					{

						$LutPort = $lut.LogicalInterconnectGroupName + ":" + $lut.name

					}
					
					if ($lu.LogicalInterconnectName)
					{

						$LuPort = $lu.LogicalInterconnectName + ":" + $lu.name

					}
					
                    $_diff = New-Object HPOneView.Library.CompareObject('connectionMode', 
                                                                        $SideIndicator.Parent, 
                                                                        $lut.mode, 
                                                                        $lu.connectionMode, 
                                                                        $LutPort,
                                                                        $LuPort,
                                                                        'CONNECTIONMODE_MISMATCH')

                    [void]$CompareObject.Add($_diff)

					'"{0}" current Connection Mode "{1}" differs from Group Connection Mode "{2}"' -f $lu.name, $lu.connectionMode, $lut.mode | Write-Verbose
					
                }

                if ( $lut.mode -ne 'Auto' -or $lu.connectionMode -ne 'Auto')
                {

                    $LutPrimaryPort = [PSCustomObject]@{ bayNumber = $null; portNumber = $null; portName = $null; Speed = $null }
                    $LutPrimaryPort.bayNumber = ($lut.primaryPort.locationEntries | Where-Object { $_.type -eq 'Bay' } ).relativeValue
                    $LutPrimaryPort.portNumber = ($lut.primaryPort.locationEntries | Where-Object { $_.type -eq 'Port' } ).relativeValue
                    $LutPrimaryPort.portName = GetPortName $LutPrimaryPort.bayNumber $LutPrimaryPort.portNumber

                    $LuPrimaryPort = [PSCustomObject]@{ bayNumber = $null; portNumber = $null; portName = $null; Speed = $null }
                    $LuPrimaryPort.bayNumber = ($lu.primaryPortLocation.locationEntries | Where-Object type -eq 'Bay').value
                    $LuPrimaryPort.portName = ($lu.primaryPortLocation.locationEntries | Where-Object type -eq 'Port').value

                    $PrimaryPortDiff = Compare-Object -ReferenceObject $LutPrimaryPort -DifferenceObject $LuPrimaryPort -Property portName -PassThru

                    'PrimaryPortDiff Object: {0}' -f ($PrimaryPortDiff | Out-String) | Write-Verbose #-Verbose

                    if ($PrimaryPortDiff)
                    {

                        $_SideIndicator = '<=>'

                        $_ParentPrimaryPort = ('BAY{0}:{1}' -f $LutPrimaryPort.bayNumber, $LutPrimaryPort.portName)
                        $_ChildPrimaryPort = ('BAY{0}:{1}' -f $LuPrimaryPort.bayNumber, $LuPrimaryPort.portName)

                        if (! $LuPrimaryPort.portName)
                        {

                            $_SideIndicator = '<='
                            $_ChildPrimaryPort = $null

                        }

                        elseif (! $LutPrimaryPort.portName)
                        {

                            $_SideIndicator = '=>'
                            $_ParentPrimaryPort = $null

                        }

                        $_diff = New-Object HPOneView.Library.CompareObject('PrimaryPort',
                                                                            $_SideIndicator,
                                                                            $_ParentPrimaryPort,
                                                                            $_ChildPrimaryPort, 
                                                                            ($lut.LogicalInterconnectGroupName + ":" + $lut.name),
                                                                            ($lu.LogicalInterconnectName + ":" + $lu.name),
                                                                            'PRIMARYPORT_MISMATCH')

                        [void]$CompareObject.Add($_diff)

                        '"{0}" current Primary Port "{1}" differs from Group "{2}"' -f $lu.name, $_ChildPrimaryPort, $_ParentPrimaryPort | Write-Verbose                

                    }

                }


                if ($lu.nativeNetworkUri -ne $lut.nativeNetworkUri) 
                {

                    'LU NativeNetworkUri: {0}' -f $lu.nativeNetworkUri | Write-Verbose #-Verbose
                    'LUT NativeNetworkUri: {0}' -f $lut.nativeNetworkUri | Write-Verbose #-Verbose

                    $_SideIndicator = $SideIndicator.NotEqual

                    if ($lu.nativeNetworkUri) 
                    { 
                        
                        $luNativeNetwork = (Send-HPOVRequest $lu.nativeNetworkUri).name 
                    
                    }

                    else
                    {
                    
                        $luNativeNetwork = "None"
                        $_SideIndicator = $SideIndicator.Parent
                    
                    }

                    if ($lut.nativeNetworkUri) 
                    {

                        $lutNativeNetwork = (Send-HPOVRequest $lut.nativeNetworkUri).name

                    }

                    else
                    {
                    
                        $lutNativeNetwork = "None"
                        $_SideIndicator = $SideIndicator.Child
                    
                    }

                    $_diff = New-Object HPOneView.Library.CompareObject(($lu.name + ':nativeNetworkUri'), 
                                                                        $_SideIndicator,
                                                                        $lutNativeNetwork, 
                                                                        $luNativeNetwork, 
																		$lut.LogicalInterconnectGroupName,
																		$lu.LogicalInterconnectName,
                                                                        'NATIVENETWORK_MISMATCH')
                    
                    [void]$CompareObject.Add($_diff)
                    
                    '"{0}" current Native Network "{1}" differs from Group Native Network "{2}"' -f $lu.name, $luNativeNetwork, $lutNativeNetwork | Write-Verbose

                }

                CompareNetworks $lu $lut

                ComparePorts $lu $lut

            }

		}
		
        Function MissingUplinkSetFromLIG 
        {

            Return [PSCustomObject] @{

                Name                         = "missing";
                UplinkSetGroup               = $null;
                LogicalInterconnectUri       = $null;
                LogicalInterconnectName      = $null;
                LogicalInterconnectGroupName = $null

            }

        }

        ##################################################################
        # If InputObject is not a PSCustomObject, assume it is an Enclosure Name
        if ($InputObject -IsNot [System.Management.Automation.PSCustomObject])
        {

            Try
            {
            
                $InputObject = Get-HPOVEnclosure -Name $InputObject -ApplianceConnection $ApplianceConnection
            
            }
            
            Catch
            {
            
                PSCmdlet.ThrowTerminatingError($_)
            
            }    

        }

        "InputObject resource: {0} [{1}]" -f $InputObject.name, $InputObject.category | Write-Verbose

        # Loop through all ICM bays of the Enclosure object
        if ($InputObject.category -eq 'enclosures')
        {

            '{0} has {1} interconnect bays which are configured as {2} logical Interconnects' -f $InputObject.name, ($InputObject.interconnectBays | Where-Object interconnectUri).Count, $_LogicalInterconnectUris.Count | Write-Verbose

            $UniqueLIUris = $InputObject.interconnectBays | Select-Object -Property logicalInterconnectUri -Unique | Where-Object { $_.logicalInterconnectUri }  

            ForEach ($_uri in $UniqueLIUris.logicalInterconnectUri)
            {

                'Processing LI URI: {0}' -f $_uri | Write-Verbose

                Try
                {
                
                    $_LIObject = Send-HPOVRequest -Uri $_uri -Hostname $ApplianceConnection
                    $_LigObject = Send-HPOVRequest -Uri $_LIObject.logicalInterconnectGroupUri -Hostname $ApplianceConnection
                    
                    $_LIObject | Add-Member -NotePropertyName LogicalInterconnectGroup -NotePropertyValue $_LigObject -Force
                    [void]$_LogicalInterconnects.Add($_LIObject)
                
                }
                
                Catch
                {
                
                    $PSCmdlet.ThrowTerminatingError($_)
                
                }

            }

        }

        elseif ($InputObject.category -eq 'logical-enclosures')
        {

            # Is this even right?  There is a logicalInterconnectUris property.  Should that be used, even for C-Class and Synergy?
            ForEach ($_LogicalInterconnectUri in ($InputObject.logicalInterconnectUris | Where-Object { -not $_.StartsWith($SasLogicalInterconnectsUri) }))
            {

                Try
                {
                
                    $_LogicalInterconnect = Send-HPOVRequest -Uri $_LogicalInterconnectUri -Hostname $ApplianceConnection
                
                }
                
                Catch
                {
                
                    $PSCmdlet.ThrowTerminatingError($_)
                
                }

                '{0} has {1} interconnect bays which are configured within the Logical Interconnect' -f $InputObject.name, $InputObject.interconnects.Count | Write-Verbose

                Try
                {
                
                    $_LigObject = Send-HPOVRequest -Uri $_LogicalInterconnect.logicalInterconnectGroupUri -Hostname $ApplianceConnection
                    
					$_LogicalInterconnect | Add-Member -NotePropertyName LogicalInterconnectGroup -NotePropertyValue $_LigObject -Force
					
                    [void]$_LogicalInterconnects.Add($_LogicalInterconnect)
                
                }
                
                Catch
                {
                
                    $PSCmdlet.ThrowTerminatingError($_)
                
                }                

            }

        }

        elseif ($InputObject.category -eq 'logical-interconnects')
        {

            '{0} has {1} interconnect bays which are configured within the Logical Interconnect' -f $InputObject.name, $InputObject.interconnects.Count | Write-Verbose

            Try
            {
            
                $_LIObject = $InputObject.PSObject.Copy()
                $_LigObject = Send-HPOVRequest -Uri $_LIObject.logicalInterconnectGroupUri -Hostname $ApplianceConnection
                
                $_LIObject | Add-Member -NotePropertyName LogicalInterconnectGroup -NotePropertyValue $_LigObject -Force
                [void]$_LogicalInterconnects.Add($_LIObject)
            
            }
            
            Catch
            {
            
                $PSCmdlet.ThrowTerminatingError($_)
            
            }

        }

        else
        {

            Throw "Unsupported InputObject.  Only Enclosure or Logical Interconnect resources are permitted."

        }

		# Start the compare process
        foreach ($_LI in $_LogicalInterconnects) 
        {

            "Logical Interconnect '{0}' has '{1}' Interconnects and is based on Group '{2}'" -f $_LI.name, $_LogicalInterconnect.Interconnects.Count, $_LI.LogicalInterconnectGroup.name | Write-Verbose

			# Compare Expected and Actual interconnect map
            CompareInterconnects $_LI $_LI.LogicalInterconnectGroup

			# Collect Uplink Sets from both LIG and LI
            $lus = GetUplinkSets $_LI $_LI.LogicalInterconnectGroup

            foreach ($lu in $lus) 
            {

				# Compare Uplink Sets between LI and LIG, with LIG Uplink Set within LI Uplink Set (LU)
                CompareUplinksWithGroup $lu

            }

			# Compare Local Networks
			CompareLocalNetworks $_LI $_LI.LogicalInterconnectGroup
            
        }

		# Display final object
        $CompareObject

    }

    End
    {

        'Done.' | Write-Verbose

    }

}
