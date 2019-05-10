function Set-HPOVLogicalSwitch
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Ethernet")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "FibreChannel")]
		[ValidateNotNullOrEmpty()]
		[Alias ('LogialSwitch')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FibreChannel")]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FibreChannel")]
		[ValidateNotNullOrEmpty()]
		[string]$Prefix,

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FibreChannel")]
		[ValidateNotNullOrEmpty()]
		[string]$Suffix,

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[ValidateNotNullOrEmpty()]
		[ValidateSet ("General", "Management", "VMMigration", "FaultTolerance")]
		[string]$Purpose,

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Bool]$Smartlink, 

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Bool]$PrivateNetwork, 

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FibreChannel")]
		[validaterange(2,20000)]
		[int32]$TypicalBandwidth, 
		
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FibreChannel")]
		[validaterange(100,20000)]
		[int32]$MaximumBandwidth, 

		[Parameter (Mandatory = $false, ParameterSetName = "FibreChannel")]
		[ValidateRange(1,1800)]
		[Alias ('lst')]
		[int32]$LinkStabilityTime, 

		[Parameter (Mandatory = $false, ParameterSetName = "FibreChannel")]
		[Alias ('ald')]
		[Bool]$AutoLoginRedistribution,

		[Parameter (Mandatory = $false, ParameterSetName = "FibreChannel")]
		[ValidateNotNullOrEmpty()]
		[Object]$ManagedSan,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "FibreChannel")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)
	
	Begin 
	{

		Write-Warning 'IN DEV'
		BREAK

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject'])) 
		{ 
			
			"[{0}] Network resource passed via pipeline." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
			$PipelineInput = $True 
		
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

		$_NetworksToUpdate = New-Object System.Collections.ArrayList
		$NetCollection     = New-Object System.Collections.ArrayList

	}

	Process 
	{

		#build collection of networks to modify
		foreach ($net in $InputObject) 
		{

			if ($PSBoundParameters['LinkStabilityTime'] -and $net.category -eq 'fcoe-networks')
			{

				$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'LinkStabilityTime' -TargetType 'Int' -Message "The -LinkStabilityTime Parameter is not supported with FCoE Network resources, only FibreChannel network resources.  Please check your call and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if ($PSBoundParameters['AutoLoginRedistribution'] -and $net.category -eq 'fcoe-networks')
			{

				$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'AutoLoginRedistribution' -TargetType 'Boolean'  -Message "The -AutoLoginRedistribution Parameter is not supported with FCoE Network resources, only FibreChannel network resources.  Please check your call and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			# Check the name Parameter value if the caller inadvertantly provided an object for name Parameter
			if ($name -and ($name -match "category=ethernet-networks" -or $name -match "category=fc-networks" -or $name -match "category=fcoe-networks"))
			{ 
			
				$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'Name' -Message "The -name Parameter value appears to have been passed the network resource object, which is converted to type [String] and is an invalid operation.  Please verify that you provided the Network Name attribute in the -name Parameter value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

			elseif ($name -and $name.length -gt 255) 
			{

				$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'Name' -Message "The -name Parameter value is greater than 255 characters.  Please check the -name Parameter value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			switch ($net.Gettype().Name) 
			{

				"PSCustomObject" 
				{ 
	
					if ($net -is [PSCustomObject] -and ($net.category -eq "ethernet-networks" -or $net.category -eq "fc-networks" -or $net.category -eq "fcoe-networks")) 
					{

						"[{0}] Collecting $($net.type) $($net.name) resource." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						[void]$_NetworksToUpdate.Add($net)

					}

					else 
					{

						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "[$($net.gettype().name)] is an unspported data type.  Only [System.String] or [PSCustomObject] or an [Array] of [System.String] or [PSCustomObject] network resources are allowed.  Please check the -network Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}
					
				}

				"String" 
				{ 
				
					# User provided Network 'name' and 1 or more Appliance Connections
					if ($net -is [String] -and (-not ($net.StartsWith('/rest/'))))
					{
					
						ForEach ($_appliance in $ApplianceConnection)
						{

							"[{0}] Getting '$($net)' resource from appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							
							Try 
							{

								$_tempNet = Get-HPOVNetwork $net -type $PSCmdlet.ParameterSetName -ApplianceConnection $_appliance

							}
							
							Catch [HPOneView.NetworkResourceException]
							{

								if ($_.CategoryInfo.Category -eq 'ObjectNotFound')
								{

									$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException NetworkResourceNotFound ObjectNotFound 'InputObject' -Message "'$net' Network was not found.  Please check the value and try again."
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}
								
								else
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}

							}
							
							if ($_tempNet.count -gt 1)
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException NonUniqueNetworkName InvalidResult 'InputObject' -Message "Multiple '$_tempNet' Network resource found with the same name.  Please check the value and try again, or provide the Network Resource Object instead of the name."
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}
					
							[void]$_NetworksToUpdate.Add($_tempNet)

						}
						
					}

					elseif ($net -is [String] -and ($net.StartsWith('/rest/ethernet-networks/') -or $net.StartsWith('/rest/fc-networks/'))) 
					{
					
						"[{0}] Getting '$($net)' resource from appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Try
						{

							$net = Send-HPOVRequest $net -Appliance $ApplianceConnection

						}

						Catch
						{

						  $PSCmdlet.ThrowTerminatingError($_)

						}
												
						[void]$NetCollection.Add($net)
					
					}
				
				}

			}

		}

	}

	End 
	{

		ForEach ($_net in $_NetworksToUpdate)
		{

			# Set Specific Network Type settings
			switch ($_net.category) 
			{

				"ethernet-networks" 
				{

					"[{0}] Updating $($_net.name) Ethernet Network." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					switch ($PSBoundParameters.keys) 
					{

						"purpose" 
						{ 
						
							"[{0}] Setting network Purpose to: $purpose" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							$_net.purpose = $purpose
							
						}

						"smartlink" 
						{

							"[{0}] Setting smartlink Enabled to: $([bool]$smartlink)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							$_net.smartlink = [bool]$smartlink

						}

						"privateNetwork" 
						{ 

							"[{0}] Setting privateNetwork Enabled to: $([bool]$privateNetwork)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							$_net.privateNetwork = [bool]$privateNetwork
						
						}

					}

				}

				"fc-networks" 
				{

					switch ($PSBoundParameters.keys) 
					{

						"LinkStabilityTime" 
						{

							"[{0}] Setting LinkStabilityTime to '$LinkStabilityTime' seconds" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							if ($_net.fabricType -eq 'DirectAttach')
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidFabricOperation InvalidOperation 'LinkStabilityTime' -TargetType $LinkStabilityTime.Gettype().Name -Message ("Cannot set LinkStabilityTime value to a DirectAttach FibreChannel resource, {0}." -f $_net.name)
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

							$_net.linkStabilityTime = [int]$linkStabilityTime

						}

						"AutoLoginRedistribution" 
						{

							"[{0}] Setting AutoLoginRedistribution Enabled to: $([bool]$AutoLoginRedistribution)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							if ($_net.fabricType -eq 'DirectAttach')
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidFabricOperation InvalidOperation 'AutoLoginRedistribution' -TargetType $AutoLoginRedistribution.Gettype().Name -Message ("Cannot set AutoLoginRedistribution value to a DirectAttach FibreChannel resource, {0}" -f $_net.name)
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}
							
							$_net.autoLoginRedistribution = [bool]$autoLoginRedistribution

							if ($_net.linkStabilityTime -eq 0 -and (-not($LinkStabilityTime)) -and [Bool]$AutoLoginRedistribution)
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidLinkStabilityTimeValue InvalidOperation 'AutoLoginRedistribution' -Message ("The '{0}' FC Network resource is a Direct Attach fabric.  The Managed SAN resource cannot be modified." -f $_net.name)
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

						}

						"managedSan"
						{

							if ($_net.fabricType -eq 'DirectAttach')
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidFabricOperation InvalidResult 'Network' -Message ("The '{0}' FC Network resource is a Direct Attach fabric.  The Managed SAN resource cannot be modified." -f $_net.name)
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

							else
							{

								"[{0}] Processing ManagedSAN for FC Network." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								Try
								{

									$_net.managedSanUri = (VerifyManagedSan $managedSan $_net.ApplianceConnection.Name)

								}

								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}

							}
							
						}

					}

				}

				"fcoe-networks"
				{
					
					switch ($PSBoundParameters.keys) 
					{

						"managedSan"
						{

							"[{0}] Processing ManagedSAN for FC Network." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
							$_net.managedSanUri = (VerifyManagedSan $managedSan $_net.ApplianceConnection.Name)
							
						}

					}

				}

			}

			# Shared Parameters for each Network Type
			if ($PSBoundParameters["name"]) 
			{
			
				"[{0}] Updating Network name to '$name'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
				# Validate name Parameter is [String]
				$_net.name = $name
				
			}
	
			if ($PSBoundParameters["prefix"]) 
			{
				
				"[{0}] Updating Network name to include '$prefix' prefix to Network Name." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] Updated Network Name: $($prefix + $_net.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
				# Validate name Parameter is [String]
				$_net.name = $prefix + $_net.name
				
			}
	
			if ($PSBoundParameters["suffix"]) 
			{
				
				"[{0}] Updating Network name to include '$suffix' suffix to Network Name." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] Updated Network Name: $($_net.name + $suffix)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
				# Validate name Parameter is [String]
				$_net.name += $suffix
				
			}
	
			if ($PSBoundParameters["typicalBandwidth"] -or $PSBoundParameters["maximumBandwidth"]) 
			{
	
				"[{0}] Updating Network bandwidth assignment." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Getting Connection Template resource." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$ct = Send-HPOVRequest $_net.connectionTemplateUri -Appliance $_net.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				} 
				
				if ($PSBoundParameters["maximumBandwidth"]) 
				{
				
					"[{0}] Original Maximum bandwidth assignment: $($ct.bandwidth.maximumBandwidth)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] New Maximum bandwidth assignment: $maximumBandwidth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$ct.bandwidth.maximumBandwidth = $maximumBandwidth
	
				}

				if($PSBoundParameters["typicalBandwidth"]) 
				{
	
					"[{0}] Original Typical bandwidth assignment: $($ct.bandwidth.typicalBandwidth)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] New Typical bandwidth assignment: $typicalBandwidth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$ct.bandwidth.typicalBandwidth = $typicalBandwidth
					
				}
	
				# "[{0}] Updating Connection Template: $($ct | Format-List * )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$ct = Send-HPOVRequest $ct.uri PUT $ct -Appliance $ct.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
	
			}

			$_net = $_net | Select-Object * -ExcludeProperty defaultTypicalBandwidth, defaultMaximumBandwidth, created, modified

			# "[{0}] Updating Network Resource object: $($_net )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			Try
			{

				$resp = Send-HPOVRequest $_net.uri PUT $_net -Appliance $_net.ApplianceConnection.Name
			
			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			[void]$NetCollection.Add($resp)
		
		}
		
		Return $NetCollection

	}

}
