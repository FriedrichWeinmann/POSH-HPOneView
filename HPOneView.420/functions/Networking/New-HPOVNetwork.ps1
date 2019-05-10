function New-HPOVNetwork 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Ethernet")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "FC")]
		[Parameter (Mandatory, ParameterSetName = "FCOE")]
		[Parameter (Mandatory, ParameterSetName = "VLANIDRange")]
		[Parameter (Mandatory, ParameterSetName = "Ethernet")]
		[string]$Name, 

		[Parameter (Mandatory, ParameterSetName = "FC")]
		[Parameter (Mandatory, ParameterSetName = "FCOE")]
		[Parameter (Mandatory = $false, ParameterSetName = "VLANIDRange")]
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[ValidateSet ("Ethernet", "FC", "FibreChannel", "Fibre Channel", "FCoE")]
		[string]$Type = "Ethernet",
		
		[Parameter (Mandatory, ParameterSetName = "FCOE")]
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")] 
		[validaterange(1,4095)]
		[int32]$VlanId,

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")] 
		[object]$Subnet,

		[Parameter (Mandatory, ParameterSetName = "VLANIDRange")]
		[string]$VlanRange,

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")] 
		[Parameter (Mandatory = $false, ParameterSetName = "VLANIDRange")]
		[ValidateSet ('Untagged','Tagged','Tunnel', IgnoreCase = $False)]
		[string]$VLANType = "Tagged", 

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "VLANIDRange")]
		[ValidateSet ("General", "Management", "VMMigration", "FaultTolerance", 'ISCSI', IgnoreCase = $False)]
		[string]$Purpose = "General", 

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "VLANIDRange")]
		[boolean]$SmartLink = $true, 

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "VLANIDRange")]
		[boolean]$PrivateNetwork = $false, 

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "VLANIDRange")]
		[Parameter (Mandatory = $false, ParameterSetName = "FCOE")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[validaterange(2,20000)]
		[int32]$TypicalBandwidth = 2500, 
		
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "VLANIDRange")]
		[Parameter (Mandatory = $false, ParameterSetName = "FCOE")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[validaterange(100,20000)]
		[int32]$MaximumBandwidth = 20000, 

		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[int32]$LinkStabilityTime = 30, 

		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[boolean]$AutoLoginRedistribution = $False,

		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[ValidateSet ("FabricAttach","FA", "DirectAttach","DA")]
		[string]$FabricType = "FabricAttach",

		[Parameter (Mandatory = $false, ParameterSetName = "FC", ValueFromPipeline)]
		[Parameter (Mandatory = $false, ParameterSetName = "FCOE", ValueFromPipeline)] 
		[ValidateNotNullOrEmpty()]
		[object]$ManagedSan,

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "FCOE")]
		[Parameter (Mandatory = $false, ParameterSetName = "VLANIDRange")]
		[Parameter (Mandatory = $false, ParameterSetName = "importFile")]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.ScopeCollection]$Scope,

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "FCOE")]
		[Parameter (Mandatory = $false, ParameterSetName = "VLANIDRange")]
		[Parameter (Mandatory = $false, ParameterSetName = "importFile")]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "FCOE")]
		[Parameter (Mandatory = $false, ParameterSetName = "VLANIDRange")]
		[Parameter (Mandatory = $false, ParameterSetName = "importFile")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory, ParameterSetName = "importFile")]
		[Alias ("i", "import")]
		[string]$ImportFile

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

		$colStatus = New-Object System.Collections.ArrayList

	}
	 
	Process 
	{

		# Validate Ethernet VLAN ID Setting if Type = 'Tagged'
		if ($PSBoundParameters['VLANType'] -eq 'Tagged' -and (-not($PSBoundParameters['VLANID'])))
		{

			# Generate Error
			$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidNetworkTypeOperation InvalidOperation 'VLANType' -Message "The -VLANType Parameter was used to specify a 'Tagged' Network, however the -VLANID Parameter was not provided.  Please provide a VLANID to the Network resource you are creating."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Validate Ethernet VLAN ID Setting if Network Type is FCoE
		if ($PSBoundParameters['Type'] -eq 'FCoE' -and (-not($PSBoundParameters['VlanId'])))
		{

			# Generate Error
			$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidNetworkTypeOperation InvalidOperation 'Type' -Message "The -Type Parameter was used to specify a 'FCoE' Network, however the -VLANID Parameter was not provided.  Please provide a VLANID to the Network resource you are creating."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Resolved Parameter Set Name: $($PSCmdlet.ParameterSetName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Processing CMDLET for '$($_appliance.name)' appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			If ($ImportFile) 
			{

				try 
				{

					$network = [string]::Join("", (Get-Content $importfile -ErrorAction Stop)) | convertfrom-json -ErrorAction Stop

				}

				catch [System.Management.Automation.ItemNotFoundException] 
				{

					$ErrorRecord = New-ErrorRecord System.Management.Automation.ItemNotFoundException InputFileNotFound ObjectNotFound 'New-HPOVNetwork' -Message "$importFile not found.  Please check the filename or path is valid and try again."
						
					# Generate Terminating Error
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				catch [System.ArgumentException] 
				{

					$ErrorRecord = New-ErrorRecord System.ArgumentException InvalidJSON ParseError 'New-HPOVNetwork' -Message "JSON incorrect or invalid within '$importFile' input file."
						
					# Generate Terminating Error
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}
			
			else
			{
			
				"[{0}] Network Type Requested: $($Type)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				switch ($Type) 
				{

					"Ethernet" 
					{

						if (-not($PSBoundParameters['vlanRange'])) 
						{

							"[{0}] Creating '$name' Ethernet Network" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$Network = NewObject -EthernetNetwork

							$Network.vlanId              = $VlanId
							$Network.ethernetNetworkType = $VLANType
							$Network.purpose             = $EthernetNetworkPurposeEnum[$Purpose]
							$Network.name                = $Name
							$Network.smartLink           = $SmartLink
							$Network.privateNetwork      = $PrivateNetwork

							if ($PSBoundParameters['Subnet'])
							{

								"[{0}] Subnet {1} was provided, validating." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Subnet.netowrkId | Write-Verbose

								# Genrate Error
								if (-not($Subnet -is [PSCustomObject]))
								{

									$Message = 'The Subnet Parameter value is not an Object.  Please provide a valid Object by using the Get-HPOVAddressPoolSubnet Cmdlet.'
									$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidSubnetValue InvalidArgument 'Subnet' -TargetType $Subnet.Gettype().Name -Message $Message
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								# Genrate Error, invalid object type
								if ($Subnet.category -ne 'id-range-IPv4-subnet')
								{

									$Message = "The Subnet Parameter value is not a valid 'id-range-IPv4-subnet' Object.  The object category provided was {0}.  Please provide a valid Object by using the Get-HPOVAddressPoolSubnet Cmdlet." -f $Subnet.category
									$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidSubnetObject InvalidArgument 'Subnet' -TargetType 'PSObject' -Message $Message
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								# Invalid object for the appliance connection
								if ($Subnet.ApplianceConnection.Name -ne $_appliance.Name)
								{

									$Message = "The Subnet Parameter value is missing the 'ApplianceConnection' property.  Please provide a valid Object by using the Get-HPOVAddressPoolSubnet Cmdlet."
									$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidNetworkTypeOperation InvalidOperation 'Subnet' -TargetType 'PSObject' -Message $Message
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								$network.subnetUri = $Subnet.uri

							}

						}

						else 
						{
					
							"[{0}] Creating bulk '$name' + '$vlanRange' Ethernet Networks" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$network = NewObject -BulkEthernetNetworks

							$network.vlanIdRange                = $vlanRange
							$network.purpose                    = $purpose
							$network.namePrefix                 = $Name
							$network.smartLink                  = $smartLink
							$network.privateNetwork             = $privateNetwork
							$network.bandwidth.typicalBandwidth = $typicalBandwidth
							$network.bandwidth.maximumBandwidth = $maximumBandwidth
									
						}

					}
					
					{ @("FC","FibreChannel","Fibre Channel") -contains $_ } 
					{

						"[{0}] Creating '$name' FC Network" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$network = NewObject -FCNetwork

						$network.name                    = $Name
						$network.linkStabilityTime       = $linkStabilityTime
						$network.autoLoginRedistribution = $autoLoginRedistribution
						$network.fabricType              = $FCNetworkFabricTypeEnum[$FabricType]
						$network.connectionTemplateUri   = $null

						Try
						{

							$network.managedSanUri  = if ($ManagedSan) { (VerifyManagedSan $ManagedSan $_appliance) } else { $null }

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						# If maxbandiwdth value isn't specified, 10Gb is the default value, must change to 8Gb
						if ( $maximumBandwidth -eq 10000 ){ $maximumBandwidth = 8000 }

					}

					"FCOE" 
					{

						"[{0}] Creating '$name' FCOE Network" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$network = NewObject -FCoENetwork

						$network.name                  = $Name
						$network.vlanId                = $vlanId
						$network.connectionTemplateUri = $null
						
						Try
						{

							$network.managedSanUri = if ($ManagedSan) { (VerifyManagedSan $ManagedSan $_appliance) } else { $null }

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

				}
			
			}

			if ($PSBoundParameters['Scope'])
			{

				ForEach ($_Scope in $Scope)
				{

					"[{0}] Adding resource to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

					[void]$network.initialScopeUris.Add($_Scope.Uri)

				}

			}

			foreach($net in $network) 
			{

				if ($net.type.StartsWith('ethernet-networks') -and $net.type -ne 'ethernet-networkV4') { $net.type = 'ethernet-networkV4' }

				if ($net.defaultTypicalBandwidth) 
				{ 
					
					$typicalBandwidth = $net.defaultTypicalBandwidth 
					$net = $net | Select-Object * -ExcludeProperty defaultTypicalBandwidth
				
				}
				
				if ($net.defaultMaximumBandwidth) 
				{ 
					
					$maximumBandwidth = $net.defaultMaximumBandwidth 
					$net = $net | Select-Object * -ExcludeProperty defaultMaximumBandwidth

				}

				if ($net.typicalBandwidth) { $typicalBandwidth = $net.typicalBandwidth }
				if ($net.maximumBandwidth) { $maximumBandwidth = $net.maximumBandwidth }
				if ($PSBoundParameters['ImportFile'] -and $net.fabricUri) { $net.fabricUri = $null }
				if ($PSBoundParameters['ImportFile'] -and $net.subnetUri) { $net.subnetUri = $null }
				if ($PSBoundParameters['ImportFile'] -and [Array]$net.scopeUris -gt 0) { [Array]$net.scopeUris = @() }
				if ($PSBoundParameters['ImportFile'] -and $net.connectionTemplateUri) { [Array]$net.connectionTemplateUri = $null }

				switch ($net.type) 
				{

					{$_ -match "bulk-ethernet-network"}
					{
						
						"[{0}] Creating bulk '{1}' + '{2}' Ethernet Networks" -f $MyInvocation.InvocationName.ToString().ToUpper(), $name, $vlanRange | Write-Verbose

						$netUri = $EthernetNetworksUri + "/bulk"

						break

					}

					{$_ -match "ethernet-network"}
					{

						"[{0}] Creating {1} Ethernet Network" -f $MyInvocation.InvocationName.ToString().ToUpper(), $net.name | Write-Verbose

						$netUri = $EthernetNetworksUri

						$net = $net | Select-Object * -ExcludeProperty uri

					}

					{$_ -match "fc-network"}
					{

						"[{0}] Creating {1} FC Network" -f $MyInvocation.InvocationName.ToString().ToUpper(), $net.name | Write-Verbose

						$netUri = $FcNetworksUri

						$net = $net | Select-Object * -ExcludeProperty uri

					}

					{$_ -match "fcoe-network"}
					{

						"[{0}] Creating {1} FCoE Network" -f $MyInvocation.InvocationName.ToString().ToUpper(), $net.name | Write-Verbose

						$netUri = $FCoENetworksUri

						$net = $net | Select-Object * -ExcludeProperty uri

					}

					# Should never get here.  If so, this is an internal error we need to fix.
					default 
					{

						$ErrorRecord = New-ErrorRecord System.ArgumentException InvalidNetworkType InvalidType 'type' -Message "(INTERNAL ERROR) The Network Resource Type $($net.type) is invalid for '$($net.name)' network."
						
						# Generate Terminating Error
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				$objStatus = [pscustomobject]@{ 
					
					Name      = $net.Name; 
					Status    = $Null; 
					Details   = $Null;
					Exception = $Null;
				
				}

				$task = $null

				# Check if Network Type is Direct Attach and if ManagedFabric Parameter is being called at the same time.
				if (($fabricType -eq "DirectAttach" -or $fabricType -eq "DA") -and $managedfabric) 
				{ 

					$objStatus.Details = "You specified a DirectAttach Fabric Type and passed the ManagedSan Parameter.  The ManagedSan Parameter is to be used for FabricAttach networks only."
				   
				}

				else 
				{
					 
					Try
					{

						"[{0}] Sending request to create '$($net.name)' network." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$task = Send-HPOVRequest -Uri $netUri -Method POST -Body $net -Hostname $_appliance 
					
					}	
					
					Catch
					{

						"[{0}] Exception caught when trying to create '$($net.name)' network." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						"[{0}] Exception: $($_.Exception.Message.ToString())" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$objStatus.Status    = "Failed"
						$objStatus.Details   = $_.exception.message
						$objStatus.Exception = $_

					}

				}

				if (-not $task.Uri) 
				{

					"[{0}] Create Network Object '$($net.name)' request was rejected." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$objStatus.Status = "Failed"
					
					# Do not want to overwrite the details value from the Fabric Type check above.
					if ($task) { $objStatus.Details = $task }

				}

				else 
				{ 
					
					"[{0}] Create Network Object '$($net.name)' creating. Monitor task." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# Wait for the network to be created
					Try
					{

						$task = Wait-HPOVTaskComplete $task #-Appliance $_appliance

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$objStatus.Status  = $task.taskState
					$objStatus.Details = $task

				}

				[void] $colStatus.add($objStatus) #| Out-Null

				# Update Bandwidth allocation if set to different than default values
				if (($typicalBandwidth -or $maximumBandwidth) -and (-not($objStatus.Status -eq "Failed")) -and $net.type -ne 'bulk-ethernet-networkV1' ) 
				{

					"[{0}] Setting bandwidth to network object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting Network object to retrieve ConnectionTemplate URI" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# Get network resource URI
					Try
					{

						$net = Send-HPOVRequest $task.associatedResource.resourceUri -Hostname $_appliance

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					"[{0}] ConnectionTemplate URI '$($net.connectionTemplateUri)'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					if ($net -and $net.connectionTemplateUri) 
					{

						$ctUri = $net.connectionTemplateUri
						
						Try
						{

							$ct = Send-HPOVRequest $ctUri -Hostname $_appliance

							if ($typicalBandwidth) { $ct.bandwidth.typicalBandwidth = $typicalBandwidth }

							if ($maximumBandwidth) { $ct.bandwidth.maximumBandwidth = $maximumBandwidth }

							$void = Send-HPOVRequest $ct.uri PUT $ct -Hostname $ct.ApplianceConnection.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}        

					}

				}

			}

		}

	}

	End 
	{

		if ($colStatus | Where-Object { $_.Status -ne "Completed" }) 
		{ 
			
			write-error "One or more networks failed the creation attempt!" 
		
		}

		Return $colStatus
		
	}

}
