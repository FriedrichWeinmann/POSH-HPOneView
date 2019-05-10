function Get-HPOVFabricManager
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

		$_FabricManagerCol = New-Object System.Collections.ArrayList

	}

	Process
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			$_Query = New-Object System.Collections.ArrayList

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

			$_Category = 'category={0}' -f $ResourceCategoryEnum.FabricManager

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

			if ($_ResourcesFromIndexCol.Count -eq 0 -and $Name)
			{

				"[{0}] FabricManager Resource Name '{1}' was not found on appliance {2}.  Generate Error." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name, $_appliance.Name | Write-Verbose

				$ExceptionMessage = "The specified FabricManager '{0}' was not found on '{1}' appliance connection. Please check the name again, and try again." -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord HPOneView.Networking.FabricManagerResourceException FabricManagerResourceNotFound ObjectNotFound "Name" -Message $ExceptionMessage

				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				ForEach ($_member in $_ResourcesFromIndexCol)
				{

					$_FabricManagerClusterNodes = New-Object 'System.Collections.Generic.List[HPOneView.Networking.FabricManager+ClusterNodeInfo]'
					$_Tenants = New-Object "System.Collections.Generic.List[HPOneView.Networking.FabricManager+Tenant]";

					# Loop through fabricManagerClusterNodeInfo
					ForEach ($_ClusterNode in $_member.fabricManagerClusterNodeInfo)
					{

						$_ClusterNodeInfo = New-Object HPOneView.Networking.FabricManager+ClusterNodeInfo($_ClusterNode.id,
																										  $_ClusterNode.oobMgmtAddr,
																										  $_ClusterNode.nodeDN,
																										  $_ClusterNode.connected)

						$_FabricManagerClusterNodes.Add($_ClusterNodeInfo)

					}

					# Loop through tenants
					ForEach ($_tenant in $_member.tenants)
					{

						$_TenantInfo = New-Object HPOneView.Networking.FabricManager+Tenant($_tenant.name,
																							$_tenant.description,
																							$_tenant.dn,
																							$_tenant.uri,
																							$_tenant.complianceStatus,
																							$_tenant.state,
																							$_tenant.status,
																							$_tenant.preconfigured,
																							$_tenant.monitored)

						$_Tenants.Add($_TenantInfo)

					}

					New-Object HPOneView.Networking.FabricManager($_member.name,
																  $_member.uri,
																  $_member.eTag,
																  $_member.version,
																  $_FabricManagerClusterNodes,
																  $_Tenants,
																  $_member.state,
																  $_member.status,
																  $_member.created,
																  $_member.modified,
																  $_member.applianceConnection)

				}

			}

		}

	}

	end
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
