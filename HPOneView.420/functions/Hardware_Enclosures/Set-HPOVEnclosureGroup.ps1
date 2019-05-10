function Set-HPOVEnclosureGroup
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Alias('EnclosureGroup')]
		[Object]$InputObject,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$ConfigurationScript,
		 
		# [Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		# [ValidateNotNullOrEmpty()]
		# [Alias ('LogicalInterconnectGroupUri','LogicalInterconnectGroup')]
		# [object]$LogicalInterconnectGroupMapping,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		# [Parameter (Mandatory = $false, ParameterSetName = 'Synergy')]
		[ValidateSet ('RedundantPowerFeed','RedundantPowerSupply', IgnoreCase = $false)]
		[string]$PowerRedundantMode = "RedundantPowerFeed",

		# [Parameter (Mandatory = $false, ParameterSetName = 'Synergy')]
		# [ValidateSet ('AddressPool', 'DHCP', 'External')]
		# [String]$IPv4AddressType,
		
		# [Parameter (Mandatory = $false, ParameterSetName = 'Synergy')]
		# [ValidateNotNullOrEmpty()]
		# [object]$AddressPool,
		
		# [Parameter (Mandatory = $false, ParameterSetName = 'Synergy')]
		# [ValidateSet ('None', 'Internal', 'External')]
		# [String]$DeploymentNetworkType,
		
		# [Parameter (Mandatory = $false)]
		# [ValidateNotNullOrEmpty()]
		# [object]$DeploymentNetwork,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		# [Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Synergy')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = ($ConnectedSessions | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject']))
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

	}

	Process
	{

		# Validate InputObject
		if ($InputObject.category -ne $ResourceCategoryEnum['EnclosureGroup'])
		{

			$ExceptionMessage = "The provided -InputObject value is not an {0} resource.  Please correct the input object and try again." -f $ResourceCategoryEnum['EnclosureGroup']
			$ErrorRecord = New-ErrorRecord HPOneView.InputObjectResourceException InvalidResourceObject InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_EnclosureGroupToUpdate = $null

		try
		{

			$_EnclosureGroupToUpdate = $InputObject.PSObject.Copy()

		}

		catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		# Determine operations that need to be performed
		switch ($PSBoundParameters.Keys)
		{

			'Name'
			{

				"[{0}] Updating Name." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_EnclosureGroupToUpdate.name = $Name

			}

			'ConfigurationScript'
			{

				# Validate the enclosure group is for c-Class not Synergy
				if (-not $InputObject.enclosureTypeUri.StartsWith($CClassEnclosureTypeUri))
				{

					$ExceptionMessage = "The provided -InputObject resource object is not a c-Class enclosure.  Please correct the input object and try again."
					$ErrorRecord = New-ErrorRecord HPOneView.InputObjectResourceException InvalidResourceObject InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				"[{0}] Updating configuration script" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_Uri = $InputObject.Uri + "/script"

				$_EnclosureGroupToUpdate | Add-Member -NotePropertyName configurationScript -NotePropertyValue $ConfigurationScript

			}

			'PowerRedundantMode'
			{

				"[{0}] Updating PowerRedundantMode." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_EnclosureGroupToUpdate.powerMode = $PowerRedundantMode

			}

			'LogicalInterconnectGroupMapping'
			{

				"[{0}] Updating PowerRedunLogicalInterconnectGroupMappingdantMode." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

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

		}

		"[{0}] Updating enclosure group configuration." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		try
		{

			Send-HPOVRequest -Uri $_EnclosureGroupToUpdate.Uri -Method PUT -Body $_EnclosureGroupToUpdate -Hostname $InputObject.ApplianceConnection

		}

		catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

	}

	end
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
