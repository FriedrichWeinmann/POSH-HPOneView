function Get-HPOVRackManager
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	param
	(

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[String]$Name,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Label,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = ($ConnectedSessions | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

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

		$_CollectionName = New-Object System.Collections.ArrayList

	}

	Process
	{

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

					"[{0}] Filtering for Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

					[Void]$_Query.Add(("name%3A{0}" -f $Name.Replace("*", "%2A").Replace(',','%2C').Replace(" ", "?")))

				}

				else
				{

					[Void]$_Query.Add(("name:'{0}'" -f $Name))

				}

			}

			if ($Label)
			{

				[Void]$_Query.Add(("labels:'{0}'" -f $Label))

			}

			$_Category = 'category={0}' -f $ResourceCategoryEnum.RackManager

			# Build the final URI
			$_uri = '{0}?{1}&sort=name:asc&query={2}' -f $IndexUri,  [String]::Join('&', $_Category), [String]::Join(' AND ', $_Query.ToArray())

			Try
			{

				[Array]$_ResourcesFromIndexCol = Get-AllIndexResources -Uri $_uri -ApplianceConnection $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if($_ResourcesFromIndexCol.Count -eq 0 -and $Name)
			{

				"[{0}] Rack manager Resource Name '{1}' was not found on appliance {2}.  Generate Error." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name, $_appliance.Name | Write-Verbose

				$ExceptionMessage = "The specified Rack manager '{0}' was not found on '{1}' appliance connection. Please check the name again, and try again." -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord HPOneView.RackManagerResourceException RackManagerResourceNotFound ObjectNotFound "Name" -Message $ExceptionMessage

				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				ForEach ($_member in $_ResourcesFromIndexCol)
				{

					# Get Chassis subresource
					Try
					{

						$_ChassisResources = Send-HPOVRequest -Uri $_member.subResources.chassis.uri -Hostname $ApplianceConnection

						$_ChassisResourceCol = New-Object "System.Collections.Generic.List[HPOneView.Servers.Chassis]"

						ForEach ($_chassis in $_ChassisResources.members)
						{

							$_ChassisResourceCol.Add((New-Object HPOneView.Servers.Chassis($_chassis.name,
																							$_chassis.model,
																							$_chassis.partNumber,
																							$_chassis.chassisType,
																							$_chassis.serialNumber,
																							$_chassis.uPosition,
																							$_chassis.status,
																							$_chassis.state,
																							('/rest/rack-managers/{0}' -f $_chassis.rackManagerId),
																							$_chassis.partitionName,
																							$_chassis.physicalLocationString,
																							('/rest/server-hardware/{0}' -f $_chassis.partitionUuid),
																							$_chassis.uri,
																							$_chassis.ApplianceConnection)))

						}
		
					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					# Get Partition subresources
					Try
					{

						$_PartitionResources = Send-HPOVRequest -Uri $_member.subResources.partitions.uri -Hostname $ApplianceConnection

						$_PartitionResourcesCol = New-Object "System.Collections.Generic.List[HPOneView.Servers.Partition]"

						ForEach ($_partition in $_PartitionResources.members)
						{

							$_PartitionResourcesCol.Add((New-Object HPOneView.Servers.Partition($_partition.name,
																								$_partition.powerState,
																								$_partition.state,
																								$_partition.status,
																								$_partition.partitionId,
																								$_partition.chassisCount,
																								$_partition.totalPartitionMemoryGB,
																								$_partition.totalProcessorCount,
																								$_partition.coreCountPerProcessor,
																								$_partition.redfishUri,
																								('/rest/rack-managers/{0}' -f $_partition.rackManagerId),
																								$_partition.serverHardwareUri,
																								$_partition.uri,
																								$_partition.ApplianceConnection)))

						}

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					# Get Managers subresources
					Try
					{

						$_ChassisManagerResources = Send-HPOVRequest -Uri $_member.subResources.managers.uri -Hostname $ApplianceConnection

						$_ChassisManagerResourcesCol = New-Object "System.Collections.Generic.List[HPOneView.Servers.Manager]"

						ForEach ($_manager in $_ChassisManagerResources.members)
						{

							$_ChassisManagerResourcesCol.Add((New-Object HPOneView.Servers.Manager($_manager.name,
																									$_manager.fwVersion,
																									$_manager.ipv4Address,
																									$_manager.ipv6Address,
																									$_manager.hostname,
																									$_manager.managerType,
																									$_manager.model,
																									$_manager.status,
																									$_manager.state,
																									$_manager.uPosition,
																									('/rest/rack-managers/{0}' -f $_manager.rackManagerId),
																									$_manager.serialNumber,
																									$_manager.partNumber,
																									$_manager.uri,
																									$_manager.ApplianceConnection)))

						}

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)
						
					}

					$_SubResources = New-Object HPOneView.Servers.SubResources($_ChassisResourceCol, $_PartitionResourcesCol, $_ChassisManagerResourcesCol)

					New-Object HPOneView.Servers.RackManager($_member.name,
															 $_member.serialNumber,
															 $_member.partNumber,
															 $_member.licensingIntent,
															 $_member.etag,
															 $_member.state,
															 $_member.status,
															 $_member.model,
															 $_member.location,
															 $_member.refreshState,
															 $_member.remoteSupportUri,
															 $_member.uri,
															 $_member.created,
															 $_member.modified,
															 $_SubResources,
															 $_member.ApplianceConnection)

				}

			}

		}

	}

	end
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
