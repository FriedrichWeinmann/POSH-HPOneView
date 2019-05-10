function Show-HPOVHypervisorCluster
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false)]
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

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command agian."
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

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing Appliance Connection '{1}' (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance, $ApplianceConnection.count | Write-Verbose

			$_HypervisorManagerUris = New-Object System.Collections.ArrayList

			# Get all hypervisor managers on the appliance
			try
			{

				$_HypervisorManagers = Send-HPOVRequest -Uri $HypervisorManagersUri -Hostname $_appliance

			}

			catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			ForEach ($_manager in $_HypervisorManagers)
			{

				$_uri = "hypervisorManagerUri='{0}'" -f $_manager.uri

				[void]$_HypervisorManagerUris.Add($_uri)

			}

			$_Filter = New-Object System.Collections.ArrayList

			if ($Name)
			{

				"[{0}] Filtering for Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

				if ($Name.Contains('*'))
				{

					"[{0}] Filtering for Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

					[Void]$_Filter.Add(("name%3A{0}" -f $Name.Replace("*", "%2A").Replace(',','%2C').Replace(" ", "?")))

				}

				else
				{

					[Void]$_Filter.Add(("name:'{0}'" -f $Name))

				}

			}

			# Build the final URI
			$_uri = '{0}?filter="{1}{2}{3}"' -f $HypervisorClustersUri, [String]::Join(' OR ', $_HypervisorManagerUris.ToArray()), [String]::Join(' AND ', $_Filter.ToArray()), " AND state = 'Unmanaged'"

			

			# Build URI to look for all managers containing unmanaged clusters.  include cluster name if provided.
			# $HypervisorClustersUri
			# /rest/hypervisor-clusters

			# Return custom object
			New-Object HPOneView.Cluster.HypervisorCluster

		}

	}
	
}
