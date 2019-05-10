function Get-HPOVStoragePool 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ('pool', 'PoolName')]
		[string]$Name,

		[Parameter (Mandatory = $false, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ('systemName', 'system')]
		[object]$StorageSystem,	

		[Parameter (Mandatory = $false)]
		[switch]$Managed,

		[Parameter (Mandatory = $false)]
		[switch]$Unmanaged,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Label,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName)]
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

		$colStoragePools = New-Object System.Collections.ArrayList

	}

	Process 
	{

		# Check if StorageSystem is a PSCustomObject
		if ($StorageSystem -is [PSCustomObject] -and $StorageSystem.category -eq 'storage-systems')
		{

			"[{0}] StorageSystem Object provided.  Using ApplianceConnection property of object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$ApplianceConnection = $ConnectedSessions | Where-Object Name -eq $StorageSystem.ApplianceConnection.Name

		}

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			$_Query = New-Object System.Collections.ArrayList

			# Handle default cause of AllResourcesInScope
            if ($Scope -eq 'AllResourcesInScope')
            {

                "[{0}] Processing AllResourcesInScope." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

                $_Scopes = $_appliance.ActivePermissions | Where-Object Active

                # If one scope contains 'AllResources' ScopeName "tag", then all resources should be returned regardless.
                if ($_Scopes | Where-Object ScopeName -eq 'AllResources')
                {

                    $_ScopeNames = [String]::Join(', ', ($_Scopes | Where-Object ScopeName -eq 'AllResources').ScopeName)

                    "[{0}] Scope(s) {1} is set to 'AllResources'.  Will not add scope to URI query parameter." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeNames | Write-Verbose

                }

                # Process ApplianceConnection ActivePermissions collection
                else
                {

					"[{0}] Getting list of Scope names to pass into query." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

                    Try
                    {

                        $_ScopeQuery = Join-Scope $_Scopes

                    }

                    Catch
                    {

                        $PSCmdlet.ThrowTerminatingError($_)

                    }

                    [Void]$_Query.Add(("({0})" -f $_ScopeQuery))

                }

            }

            elseif ($Scope | Where-Object ScopeName -eq 'AllResources')
            {

                $_ScopeNames = [String]::Join(', ', ($_Scopes | Where-Object ScopeName -eq 'AllResources').ScopeName)

                "[{0}] Scope(s) {1} is set to 'AllResources'.  Will not add scope to URI query parameter." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeNames | Write-Verbose

            }

            elseif ($Scope -eq 'AllResources')
            {

                "[{0}] Requesting scope 'AllResources'.  Will not add scope to URI query parameter." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeNames | Write-Verbose

            }

            else
            {

                Try
                {

                    $_ScopeQuery = Join-Scope $Scope

                }

                Catch
                {

                    $PSCmdlet.ThrowTerminatingError($_)

                }

                [Void]$_Query.Add(("({0})" -f $_ScopeQuery))

            }

			if ($Name)
			{

				"[{0}] Filtering for Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

				if ($Name.Contains('*'))
				{

					[Void]$_Query.Add(("name%3A{0}" -f $Name.Replace("*", "%2A").Replace(',','%2C').Replace(" ", "?")))

				}

				else
				{

					[Void]$_Query.Add(("name:'{0}'" -f $Name))

				}                
				
			}

			if ($Label)
			{

				"[{0}] Filtering for Label: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Label | Write-Verbose

				[Void]$_Query.Add(("labels:'{0}'" -f $Label))

			}

			if ($PSBoundParameters['Managed'])
			{
			
				"[{0}] Filtering for unmanaged pools." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[Void]$_Query.Add("isManaged:'true'")

			}

			if ($PSBoundParameters['Unmanaged'])
			{
			
				"[{0}] Filtering for unmanaged pools." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[Void]$_Query.Add("isManaged:'false'")

			}

			if ($PSBoundParameters['StorageSystem'])
			{

				if ($StorageSystem -is [String] -and (-not $storageSystem.startswith($StorageSystemsUri)))
				{ 
		
					"[{0}] Storage system name was provided: '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StorageSystem | Write-Verbose

					Try
					{

						$StorageSystem = Get-HPOVStorageSystem -SystemName $StorageSystem -ApplianceConnection $_appliance.Name -ErrorAction Stop

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
			
				}

				elseif ($StorageSystem -is [PsCustomObject] -and $StorageSystem.category -eq "storage-systems") 
				{ 
		
					"[{0}] StorageSystem Object provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] StorageSystem Name: '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StorageSystem.name | Write-Verbose
					"[{0}] StorageSystem Uri: '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StorageSystem.uri | Write-Verbose

				}

				[Void]$_Query.Add(("storageSystemUri:'{0}'" -f $StorageSystem.uri))

			}

			$_Category = 'category=storage-pools'

			# Build the final URI
			$_uri = '{0}?{1}&sort=name:asc&query={2}' -f $IndexUri,  [String]::Join('&', $_Category), [String]::Join(' AND ', $_Query.ToArray())

			Try
			{

				[Array]$_ResourcesFromIndexCol = Get-AllIndexResources -Uri $_uri -ApplianceConnection $_appliance

				"[{0}] {1} returned objects" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ResourcesFromIndexCol.Count | Write-Verbose 

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# Look for empty return and write error
			if ($_ResourcesFromIndexCol.Count -gt 0)
			{
			
				ForEach ($_member in $_ResourcesFromIndexCol)
				{

					"[{0}] Adding Storage System '{1}' to collection" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_member.name | Write-Verbose 

					# StoreServ pool
					if ($_member.deviceSpecificAttributes.domain)
					{

						$_DeviceAttrib = new-object HPOneView.Storage.StoreServeDeviceSpecificAttributes($_member.deviceSpecificAttributes.uuid, 
																										 $_member.deviceSpecificAttributes.domain, 
																										 $_member.deviceSpecificAttributes.deviceType, 
																										 $_member.deviceSpecificAttributes.deviceSpeed, 
																										 $_member.deviceSpecificAttributes.supportedRAIDLevel, 
																										 $_member.deviceSpecificAttributes.capacityLimit, 
																										 $_member.deviceSpecificAttributes.capacityWarningLimit,
																										 (New-Object HPOneView.Storage.AllocatedCapacity($_member.deviceSpecificAttributes.allocatedCapacity.totalAllocatedCapacity, $_member.deviceSpecificAttributes.allocatedCapacity.volumeAllocatedCapacity,$_member.deviceSpecificAttributes.allocatedCapacity.snapshotAllocatedCapacity)))

					}

					# StoreVirtual pool
					else
					{

						$_VolumeCreationSpacePolicyCol = New-Object 'System.Collections.Generic.List[HPOneView.Storage.VolumeCreationSpace]'

						ForEach ($_Policy in $_member.deviceSpecificAttributes.volumeCreationSpace)
						{

							$_VolumeCreationSpacePolicyCol.Add((New-Object HPOneView.Storage.VolumeCreationSpace($_Policy.availableSpace, $_Policy.replicationLevel)))
							
						}

						$_DeviceAttrib = new-object HPOneView.Storage.StoreVirtualDeviceSpecificAttributes($_member.deviceSpecificAttributes.isMlptEnabled, 
																										   $_VolumeCreationSpacePolicyCol)

					}

					New-Object HPOneView.Storage.StoragePool($_member.name, 
															 $_member.description, 
															 $_member.scopesUri, 
															 $_member.storageSystemUri, 
															 $_member.isManaged, 
															 $_member.totalCapacity,
															 $_member.freeCapacity, 
															 $_member.allocatedCapacity, 
															 $_member.requestingRefresh,
															 $_member.lastRefreshTime,
															 $_DeviceAttrib, 
															 $_member.status, 
															 $_member.state, 
															 $_member.uri,
															 $_member.eTag, 
															 $_member.created, 
															 $_member.modified,
															 $_member.ApplianceConnection)

				}
			
			}

			elseif ($_ResourcesFromIndexCol.Count -eq 0 -and $Name)
			{

				"[{0}] Storage Pool '{1}' not found." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose
				
				$ExceptionMessage = "Storage Pool '{0}' not found on '{1}' appliance connection.  Please check the name and try again." -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord InvalidOperationException StoragePoolResourceNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)    

			}

			else
			{

				"[{0}] No Storage Pools found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

	}

}
