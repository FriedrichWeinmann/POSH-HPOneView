function Set-HPOVNetwork 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Ethernet")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "FibreChannel")]
		[ValidateNotNullOrEmpty()]
		[Alias ('net','Network')]
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
		[ValidateSet ("General", "Management", "VMMigration", "FaultTolerance", "ISCSI")]
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

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Object]$IPv4Subnet,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "FibreChannel")]
		[ValidateNotNullOrEmpty()]
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

								$net = Get-HPOVNetwork -Name $net -type $PSCmdlet.ParameterSetName -ApplianceConnection $_appliance -ErrorAction Stop

							}
							
							Catch [HPOneView.NetworkResourceException]
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}
							
							if ($net.count -gt 1)
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException NonUniqueNetworkName InvalidResult 'InputObject' -Message "Multiple '$_tempNet' Network resource found with the same name.  Please check the value and try again, or provide the Network Resource Object instead of the name."
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

						}
						
					}

					elseif ($net -is [String] -and ($net.StartsWith('/rest/ethernet-networks/') -or $net.StartsWith('/rest/fc-networks/'))) 
					{
					
						"[{0}] Getting '$($net)' resource from appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Try
						{

							$net = Send-HPOVRequest -URi $net -Appliance $ApplianceConnection

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}
					
					}
				
				}

			}

			# Perform the work
			# Set Specific Network Type settings
			switch ($net.category) 
			{

				"ethernet-networks" 
				{

					"[{0}] Updating $($net.name) Ethernet Network." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					switch ($PSBoundParameters.keys) 
					{

						"purpose" 
						{ 
						
							"[{0}] Setting network Purpose to: $purpose" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$net.purpose = $Purpose
							
						}

						"smartlink" 
						{

							"[{0}] Setting smartlink Enabled to: $([bool]$smartlink)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$net.smartlink = [bool]$Smartlink

						}

						"privateNetwork" 
						{ 

							"[{0}] Setting privateNetwork Enabled to: $([bool]$privateNetwork)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$net.privateNetwork = [bool]$PrivateNetwork
						
						}

						'IPv4Subnet'
						{

							if ($null -eq $IPv4Subnet)
							{

								"[{0}] Setting subnetUri to null" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								$net.subnetUri = $null

							}

							else
							{

								# Validate the Address Pool
								Switch ($IPv4Subnet.GetType())
								{

									'String'
									{

										if ($IPv4Subnet.StartsWith('/rest/id-pools/ipv4/subnets'))
										{

											Try
											{

												$IPv4Subnet = Send-HPOVRequest -Uri $IPv4Subnet -Appliance $ApplianceConnection

											}
											
											Catch
											{

												$PSCmdlet.ThrowTerminatingError($_)

											}

										}

										elseif ($PSBoundParameters['IPv4Subnet'] -and $null -ne $IPv4Subnet)
										{

											Try
											{

												$IPv4Subnet = Get-HPOVAddressPoolSubnet -NetworkID $IPv4Subnet -Appliance $ApplianceConnection -ErrorAction Stop

											}
											
											Catch
											{

												$PSCmdlet.ThrowTerminatingError($_)

											}

										}

									}

									'PSCustomObject'
									{

										if ($IPv4Subnet.category -ne 'id-range-IPv4-subnet')
										{

											"[{0}] Invalid IPv4 Address Pool resource object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

											$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolResourceException InvalidIPv4AddressPoolResource InvalidArgument 'IPv4Subnet' -TargetType 'PSObject' -Message "An invalid IPv4 Address Pool resource object was provided.  Please verify the Parameter value and try again."
											$PSCmdlet.ThrowTerminatingError($ErrorRecord)

										}

									}

								}

								$net.subnetUri = $IPv4Subnet.uri

							}							

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

							if ($net.fabricType -eq 'DirectAttach')
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidFabricOperation InvalidOperation 'LinkStabilityTime' -TargetType $LinkStabilityTime.Gettype().Name -Message ("Cannot set LinkStabilityTime value to a DirectAttach FibreChannel resource, {0}." -f $net.name)
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

							$net.linkStabilityTime = [int]$linkStabilityTime

						}

						"AutoLoginRedistribution" 
						{

							"[{0}] Setting AutoLoginRedistribution Enabled to: $([bool]$AutoLoginRedistribution)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							if ($net.fabricType -eq 'DirectAttach')
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidFabricOperation InvalidOperation 'AutoLoginRedistribution' -TargetType $AutoLoginRedistribution.Gettype().Name -Message ("Cannot set AutoLoginRedistribution value to a DirectAttach FibreChannel resource, {0}" -f $net.name)
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}
							
							$net.autoLoginRedistribution = [bool]$autoLoginRedistribution

							if ($net.linkStabilityTime -eq 0 -and (-not($LinkStabilityTime)) -and [Bool]$AutoLoginRedistribution)
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidLinkStabilityTimeValue InvalidOperation 'AutoLoginRedistribution' -Message ("The '{0}' FC Network resource is a Direct Attach fabric.  The Managed SAN resource cannot be modified." -f $_net.name)
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

						}

						"managedSan"
						{

							if ($net.fabricType -eq 'DirectAttach')
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidFabricOperation InvalidResult 'Network' -Message ("The '{0}' FC Network resource is a Direct Attach fabric.  The Managed SAN resource cannot be modified." -f $net.name)
								$PSCmdlet.WriteError($ErrorRecord)

							}

							else
							{

								"[{0}] Processing ManagedSAN for FC Network." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								Try
								{

									$net.managedSanUri = (VerifyManagedSan $managedSan $net.ApplianceConnection.Name)

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
					
							$net.managedSanUri = (VerifyManagedSan $managedSan $net.ApplianceConnection.Name)
							
						}

					}

				}

			}

			# Shared Parameters for each Network Type
			if ($PSBoundParameters["name"]) 
			{
			
				"[{0}] Updating Network name to '$name'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
				# Validate name Parameter is [String]
				$net.name = $name
				
			}
	
			if ($PSBoundParameters["prefix"]) 
			{
				
				"[{0}] Updating Network name to include '$prefix' prefix to Network Name." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] Updated Network Name: $($prefix + $net.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
				# Validate name Parameter is [String]
				$net.name = $prefix + $net.name
				
			}
	
			if ($PSBoundParameters["suffix"]) 
			{
				
				"[{0}] Updating Network name to include '$suffix' suffix to Network Name." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] Updated Network Name: $($net.name + $suffix)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
				# Validate name Parameter is [String]
				$net.name += $suffix
				
			}
	
			if ($PSBoundParameters["typicalBandwidth"] -or $PSBoundParameters["maximumBandwidth"]) 
			{
	
				"[{0}] Updating Network bandwidth assignment." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Getting Connection Template resource." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$ct = Send-HPOVRequest $net.connectionTemplateUri -Appliance $net.ApplianceConnection.Name

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
	
				Try
				{

					$ct = Send-HPOVRequest $ct.uri PUT $ct -Appliance $ct.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
	
			}

			$net = $net | Select-Object * -ExcludeProperty defaultTypicalBandwidth, defaultMaximumBandwidth, created, modified

			Try
			{

				$resp = Send-HPOVRequest $net.uri PUT $net -Appliance $net.ApplianceConnection.Name
			
			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$resp			

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
