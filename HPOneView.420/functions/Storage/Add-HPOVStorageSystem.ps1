function Add-HPOVStorageSystem 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'StoreServe')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'StoreServe')]
		[Parameter (Mandatory, ParameterSetName = 'StoreVirtual')]
		[ValidateNotNullOrEmpty()]
		[string]$Hostname,

		[Parameter (Mandatory = $False, ParameterSetName = 'StoreServe')]
		[Parameter (Mandatory = $False, ParameterSetName = 'StoreVirtual')]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential,
		 
		[Parameter (Mandatory = $False, ParameterSetName = 'StoreServe')]
		[Parameter (Mandatory = $False, ParameterSetName = 'StoreVirtual')]
		[ValidateNotNullOrEmpty()]
		[string]$Username,

		[Parameter (Mandatory = $False, ParameterSetName = 'StoreServe')]
		[Parameter (Mandatory = $False, ParameterSetName = 'StoreVirtual')]
		[ValidateNotNullOrEmpty()]
		[Object]$Password,

		[Parameter (Mandatory = $false, ParameterSetName = 'StoreServe')]
		[Parameter (Mandatory = $false, ParameterSetName = 'StoreVirtual')]
		[ValidateSet ('StoreServ', 'StoreVirtual')]
		[String]$Family = 'StoreServ',

		[Parameter (Mandatory = $false, ParameterSetName = 'StoreServe')]
		[ValidateNotNullOrEmpty()]
		[String]$Domain = 'NO DOMAIN',

		[Parameter (Mandatory = $false, ParameterSetName = 'StoreServe')]
		[ValidateNotNullOrEmpty()]
		[Hashtable]$Ports,

		[Parameter (Mandatory, ParameterSetName = 'StoreVirtual')]
		[ValidateNotNullOrEmpty()]
		[Hashtable]$VIPS,

		[Parameter (Mandatory = $false, ParameterSetName = 'StoreServe')]
		[ValidateNotNullOrEmpty()]
		[Hashtable]$PortGroups,

		[Parameter (Mandatory = $false, ParameterSetName = 'StoreServe')]
		[Parameter (Mandatory = $false, ParameterSetName = 'StoreVirtual')]
		[Switch]$ShowSystemDetails,

		[Parameter (Mandatory = $false, ParameterSetName = 'StoreServe')]
		[Parameter (Mandatory = $false, ParameterSetName = 'StoreVirtual')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

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

		if ($Password -is [SecureString])
		{

			$Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

		}

		if ($PSBoundParameters['Credential'])
		{

			$Username = $Credential.Username
			$Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

		}

		if (-not($PSBoundParameters['Credential']) -and -not($PSBoundParameters['Username']))
		{

			$ExceptionMessage = "Credentials are required in order to add a storage system.  Please use either the -Credential or -Username parameter to supply a valid account to authenticate with."
			$ErrorRecord = New-ErrorRecord InvalidOperationException MissingCredentialParameter InvalidArgument 'Auth' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if (-not($PSBoundParameters['Password']) -and $PSBoundParameters['Username'])
		{

			$ExceptionMessage = "Credentials are required in order to add a storage system.  Please use the Password parameter to supply a String or SecureString value.  Or use the Credential parameter to supply a PSCredential object."
			$ErrorRecord = New-ErrorRecord InvalidOperationException MissingPasswordParameter InvalidArgument 'Password' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ((-not $PSBoundParameters['VIPS']) -and $Family -eq 'StoreVirtual')
		{

			$ExceptionMessage = "Adding a StoreVirtual resource requires you to provide the VIP or VIPS and associated Ethernet Network."
			$ErrorRecord = New-ErrorRecord InvalidOperationException MissingVIPSParameter InvalidArgument 'VIPS' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
		}

	}
	 
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{
		
			"[{0}] Processing appliance '{1}' (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			$_storagesystemcredentials = NewObject -StorageSystemCredentials

			$_storagesystemcredentials.hostname = $hostname
			$_storagesystemcredentials.username = $username
			$_storagesystemcredentials.password = $password
			$_storagesystemcredentials.family   = $StorageSystemFamilyTypeEnum[$Family]

			Try
			{

				$_storageSystemDiscoveryTask = Send-HPOVRequest -Uri $StorageSystemsUri -Method POST -Body $_storagesystemcredentials -Hostname $_appliance.Name | Wait-HPOVTaskComplete

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}			

			if ($_storageSystemDiscoveryTask.taskState -eq "Completed") 
			{

				Try
				{
					
					$_connectedStorageSystem = Send-HPOVRequest -Uri $_storageSystemDiscoveryTask.associatedResource.resourceUri -Hostname $_appliance.Name
				
				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}		

				"[{0}] Processing '{1}' Storage System." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_connectedStorageSystem.name | Write-Verbose

				$_connectedStorageSystem.PSObject.TypeNames.Insert(0,'HPOneView.Storage.System')

				# Display Storage System details
				if ($ShowSystemDetails) 
				{ 
					
					$_connectedStorageSystem | Out-Host 
				
				}
				
				if ($_connectedStorageSystem.deviceSpecificAttributes.discoveredPools)
				{

					$_connectedStorageSystem.deviceSpecificAttributes.discoveredPools | ForEach-Object { 
						
						$_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.System.DiscoveredPool') 

					}

					# Display Storage System Unmanaged Pool details
					if ($ShowSystemDetails) 
					{ 
						
						$_connectedStorageSystem.deviceSpecificAttributes.discoveredPools | Sort-Object domain,name | Out-Host 
					
					}

				}

				if ($_connectedStorageSystem.ports)
				{

					$_connectedStorageSystem.ports | ForEach-Object { 
						
						# This is temporary
						Add-Member -InputObject $_ -NotePropertyName ApplianceConnection -NotePropertyValue $_connectedStorageSystem.ApplianceConnection

						$_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.System.Port') 

					}

					# Display Storage System Unmanaged Port details
					if ($ShowSystemDetails) 
					{ 
						
						$_connectedStorageSystem.ports | Out-Host 
					
					}
					
				}

				# Check if ISCSI paramset first, and handle ports
				if ($PSCmdlet.ParameterSetName -eq 'StoreVirtual' -or $Family -eq 'StoreVirtual')
				{

					ForEach ($_VIP in $VIPS.GetEnumerator())
					{

						# Validate the Network associated with the VIP is an Ethernet resource
						if ($_VIP.Value.category -ne 'ethernet-networks')
						{

							$ExceptionMessage = "The provided VIP {0} and associated Network {1} is not an allowed Ethernet network resource." -f $_VIP.Name, $_VIP.Value.name
							$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidVIPNetwork InvalidArgument 'VIPS' -TargetType $VIPS.GetType().Name -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						if ($_connectedStorageSystem.ports | Where-Object name -eq $_VIP.Name)
						{

							$_StoragePort = ($_connectedStorageSystem.ports | Where-Object name -eq $_VIP.Name).PSObject.Copy()
							$_IndexOf     = $_connectedStorageSystem.ports.name.IndexOf($_StoragePort.name)

						}
						
						else
						{

							$ExceptionMessage = "The provided VIP {0} name was not found to be present on the StoreVirtual system: {1}." -f $_VIP.Name, [String]::Join(', ', $_connectedStorageSystem.ports.name)
							$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidVIPName InvalidArgument 'VIPS' -TargetType $VIPS.GetType().Name -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						$_StoragePort.expectedNetworkUri  = $_VIP.Value.uri
						$_StoragePort.expectedNetworkName = $_VIP.Value.name
						$_StoragePort.mode                = 'Managed'

						$_connectedStorageSystem.ports[$_IndexOf] = $_StoragePort

					}

				}

				else
				{

					# Handle Host Port configuration
					if ($PSBoundParameters['Ports'])
					{

						ForEach ($_port in $Ports.GetEnumerator())
						{

							"[{0}] Processing '{1}' Port" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_port.name | Write-Verbose

							if ($_connectedStorageSystem.ports | Where-Object name -eq $_port.Name)
							{

								$_StoragePort = ($_connectedStorageSystem.ports | Where-Object name -eq $_port.Name).PSObject.Copy()
								$_IndexOf     = $_connectedStorageSystem.ports.name.IndexOf($_StoragePort.name)

								"[{0}] Found port: '{1}' [{2}]" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_StoragePort.Name, $_IndexOf | Write-Verbose

							}
							
							else
							{

								"[{0}] Cleaning up storage system" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								Try
								{

									$reply = Send-HPOVRequest -uri $_connectedStorageSystem.uri -method DELETE -Hostname $_appliance.Name | Wait-HPOVTaskComplete

								}
								
								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}		

								$ExceptionMessage = "The provided host port {0} name was not found to be present on the StoreServ system.  Available host ports are: {1}." -f $_port.Name, [String]::Join(', ', $_connectedStorageSystem.ports.name)
								$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidVIPName InvalidArgument 'Ports' -TargetType $Ports.GetType().Name -Message $ExceptionMessage
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

							# First get the network.  Will error if network does not exist
							switch ($_port.value.GetType().Name)
							{

								'String'
								{
								
									if ($_port.value -ne 'Auto' -and $null -ne $_port.value)
									{

										Try
										{

											'[{0}] Looking in idex for {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_port.value | Write-Verbose

											$uri = '{0}?filter=name:"{1}"&category:fc-networks&category:fcoe-networks' -f $IndexUri, $_port.value 
											
											$_resp = Send-HPOVRequest -Uri $uri -ApplianceConnection $_appliance.Name

										}

										Catch
										{

											$PSCmdlet.ThrowTerminatingError($_)

										}

										# Error, as we couldn't find a unique FC/FCoE resource from the name via the Index
										if ($_resp.count -gt 1)
										{

											$Message     = "The provided Storage Port Network Resource name {0} was found via the index as the name of {1} resources.  Please make sure you are specifying a unique FC or FCoE resource name." -f $_port.value, $_resp.count 
											$ErrorRecord = New-ErrorRecord InvalidOperationException NonUniqueStoragePortFabricName InvalidResult 'Ports' -TargetType $Ports.GetType().Name -Message $Message
											$PSCmdlet.ThrowTerminatingError($ErrorRecord)

										}

										elseif ($_resp.count -eq 0)
										{

											$Message     = "The provided Storage Port Network Resource name {0} was not found via the index.  Please verify the FC or FCoE Network exists." -f $_port.Value
											$ErrorRecord = New-ErrorRecord InvalidOperationException StorageSystemPortNetworkNotFound ObjectNotFound 'Ports' -TargetType $Ports.GetType().Name -Message $Message
											$PSCmdlet.ThrowTerminatingError($ErrorRecord)

										}

										Try
										{

											'[{0}] Getting full network object {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_port.value | Write-Verbose

											$_sNet = Send-HPOVRequest -Uri $_resp.members.uri

										}
										
										Catch
										{

											$PSCmdlet.ThrowTerminatingError($_)

										}

									}
									
									else 
									{
									
										$_snet = [PScustomObject]@{

											expectedNetorkUri = 'Auto';
											name              = 'Auto';

										}

									}
								
								}

								'PSCustomObject'
								{

									if ('fc-networks', 'fcoe-networks' -contains $_port.value.category)
									{

										$_snet = [PScustomObject]@{

											expectedNetorkUri = $_port.value.uri;
											name              = $_port.value.name

										}

									}

									elseif ($_port.value.category -eq 'fc-sans')
									{

										$_snet = [PScustomObject]@{

											expectedNetorkUri = $_port.value.associatedNetworks.uri;
											name              = $_port.value.associatedNetworks.name

										}
										
									}

								}

								default
								{

									$Message     = "The provided Storage Port Network value is not a supported object type, {0}.  Please verify the FC or FCoE Network exists." -f $_port.value.GetType().FullName
									$ErrorRecord = New-ErrorRecord InvalidOperationException StorageSystemPortNetworkNotFound ObjectNotFound 'Ports' -TargetType $Ports.GetType().Name -Message $Message
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

							}					

							# Update the ports Expected SAN/Network property
							if ($_sNet.expectedNetorkUri -eq 'Auto' -and $null -eq $_StoragePort.actualSanUri)
							{

								$_StoragePort.mode = 'AutoSelectExpectedSan'

							}

							elseif ($_sNet.expectedNetorkUri -ne 'Auto' -and $null -eq $_StoragePort.actualSanUri)
							{

								$_StoragePort.expectedNetworkUri  = $_sNet.expectedNetorkUri
								$_StoragePort.expectedNetworkName = $_sNet.name
								$_StoragePort.mode                = 'Managed'

							}

							if ($PSBoundParameters['PortGroups'])
							{

								if ($PortGroups.Get_Item($_port.Name))
								{

									"[{0}] Found '{1}' Port Group for '{2}' port." -f $MyInvocation.InvocationName.ToString().ToUpper(), $PortGroups.Get_Item($_port.Name), $_port.Name | Write-Verbose

									$_StoragePort.groupName = $PortGroups.Get_Item($_port.Name)

									# Remove the PortGroup item from the Hashtable so we can Process left overs later
									$PortGroups.Remove($_port.Name)

								}

							}

							$_connectedStorageSystem.ports[$_IndexOf] = $_StoragePort
							
						}

					}

					# Process any of the leftover portgroup collection
					if ($PortGroups)
					{

						"[{0}] {1} PortGroups remain to be configured." -f $MyInvocation.InvocationName.ToString().ToUpper(), $PortGroups.Count | Write-Verbose

						ForEach ($_pg in $PortGroups.GetEnumerator())
						{

							"[{0}] Processing {1} Port for PortGroup assignment." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_pg.Name, $_pg.Value | Write-Verbose

							if ($_connectedStorageSystem.ports | Where-Object name -eq $_pg.Name)
							{

								$_port = $_connectedStorageSystem.ports | Where-Object name -eq $_pg.Name

								"[{0}] Found {1} -> {2}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_pg.Name, $_pg.Value | Write-Verbose

								$_connectedStorageSystem.ports[($_connectedStorageSystem.ports.IndexOf($_port))].groupName = $_pg.Value

							}

							else
							{

								"[{0}] {1} was not found in the unmanagedPorts collection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_pg.Name | Write-Verbose

							}

						}

					}			

					#"[$($MyInvocation.InvocationName.ToString().ToUpper())] Adding {0} managed ports. {1} remaining unmanaged ports to be claimed later." -f $_managedPorts.count,$_connectedStorageSystem.unmanagedPorts.count | Write-Verbose 

					# Validate the $Domain Parameter exists in the list of unmanaged domains returned in the connect call
					if ($_connectedStorageSystem.deviceSpecificAttributes.discoveredDomains -ccontains $Domain)				
					{

						"[{0}] Found Virtual Domain '{1}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Domain| Write-Verbose

						# The domain exists, update the managedDomain property
						$_connectedStorageSystem.deviceSpecificAttributes.managedDomain = $_connectedstoragesystem.deviceSpecificAttributes.discoveredDomains | Where-Object { $_ -eq $Domain }

						[Array]$_connectedStorageSystem.deviceSpecificAttributes.discoveredDomains = @($_connectedStorageSystem.deviceSpecificAttributes.discoveredDomains | Where-Object { $_ -ne $Domain })

					}

					else 
					{

						"[{0}] Domain '{1}' not found (name is Case Sensitive). Cleaning up." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Domain | Write-Verbose

						Try
						{

							$reply = Send-HPOVRequest -uri $_connectedStorageSystem.uri -method DELETE -Hostname $_appliance.Name

						}
						
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}		

						$ErrorRecord = New-ErrorRecord InvalidOperationException StorageDomainResourceNotFound ObjectNotFound 'Domain' -Message "Storage Domain '$Domain' not found (name is Case Sensitive).  Please check the storage domain exist on the storage system."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

			}

			else 
			{

				# ERROR
				$_connectedStorageSystem | Out-Host

				if ($_storageSystemDiscoveryTask.taskErrors.errorCode -eq 'STRM_RESOURCE_ALREADY_PRESENT' -or -not $_storageSystemDiscoveryTask.associatedResource.resourceUri)
				{

					"[{0}] {1} {2} {3}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_storageSystemDiscoveryTask.taskErrors.details, $_storageSystemDiscoveryTask.taskErrors.recommEndedActions, $_storageSystemDiscoveryTask.taskErrors.errorCode| Write-Verbose

					$ErrorRecord = New-ErrorRecord InvalidOperationException $_storageSystemDiscoveryTask.taskErrors[0].errorCode InvalidResult 'StoragSystem' -Message ($_storageSystemDiscoveryTask.taskErrors[0].message + ' ' + $_storageSystemDiscoveryTask.taskErrors[0].recommEndedActions)
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				else
				{

					"[{0}] Task error occurred. Cleaning Up." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$reply = Send-HPOVRequest -uri $_connectedStorageSystem.uri -method DELETE -Hostname $_appliance.Name | Wait-HPOVTaskComplete

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}		

					"[{0}] Generating error message." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
					$ErrorRecord = New-ErrorRecord InvalidOperationException $_storageSystemDiscoveryTask.taskErrors[0].errorCode InvalidResult 'Add-HPOVStorageSystem' -Message "$($_storageSystemDiscoveryTask.taskErrors[0].message)"
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			"[{0}] Sending request to finalize adding Storage System to appliance" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$task = Send-HPOVRequest -method PUT -body $_connectedStorageSystem -uri $_connectedStorageSystem.uri -Hostname $_appliance.Name

			}

			Catch
			{
				
				$task = $null
				
				$PSCmdlet.ThrowTerminatingError($_)

			}			

			if ($PSBoundParameters['Async'])
			{

				$task

			}

			else
			{

				$task | Wait-HPOVTaskComplete

			}

		}
		
	}

	End 
	{

		'{0} Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}
   
}
