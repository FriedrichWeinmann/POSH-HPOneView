function New-HPOVClusterProfile
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	param
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'OverrideHypervisorManager')]
		[String]$Description,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'OverrideHypervisorManager')]
		[String]$ClusterPrefix,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'OverrideHypervisorManager')]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Cluster.HypervisorManager]$ClusterManager,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'OverrideHypervisorManager')]
		[ValidateNotNullOrEmpty()]
		[String]$ClusterManagerLocation,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'OverrideHypervisorManager')]
		[ValidateNotNullOrEmpty()]
		[Object]$ServerProfileTemplate,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'OverrideHypervisorManager')]
		[ValidateNotNullOrEmpty()]
		[Object]$StorageVolume,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'OverrideHypervisorManager')]
		[ValidateNotNullOrEmpty()]
		[Switch]$UnmanageVSwitch,

		[Parameter (ParameterSetName = 'OverrideHypervisorManager', Mandatory = $false)]
		[ValidateSet ('Distributed', 'Standard')]
		[String]$VirtualSwitchType,

		[Parameter (ParameterSetName = 'OverrideHypervisorManager', Mandatory = $false)]
		[ValidateSet ('AllNetworks', 'GeneralNetworks')]
		[String]$DistributedSwitchUsage,

		[Parameter (ParameterSetName = 'OverrideHypervisorManager', Mandatory = $false)]
		[ValidateSet ('4.0', '4.1.0', '5.0.0', '5.1.0', '5.5.0', '6.0', '6.7')]
		[String]$DistributedSwitchVersion,

		[Parameter (ParameterSetName = 'OverrideHypervisorManager', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]$HAEnabled,

		[Parameter (ParameterSetName = 'OverrideHypervisorManager', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Bool]$DRSEnabled,

		[Parameter (ParameterSetName = 'OverrideHypervisorManager', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Bool]$MultiNicVMotionEnabled,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[Parameter (ParameterSetName = 'OverrideHypervisorManager', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.ScopeCollection]$Scope,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[Parameter (ParameterSetName = 'OverrideHypervisorManager', Mandatory = $false)]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'OverrideHypervisorManager')]
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

	}

	Process
	{

		# When processing connections in the SPT, look to see if a subnetUri is provided for the network with Management purpose, 
		# and pull mask, gateway, and DNS from it. Or error the user hasn't provided that information.

		$_NewClusterProfile = NewObject -ClusterProfile

		switch ($PSBoundParameters.Key)
		{

			'Name'
			{

				$_NewClusterProfile.name = $Name

				if (-not $PSBoundParameters['ClusterPrefix'])
				{

					$_NewClusterProfile.hypervisorHostProfileTemplate.hostPrefix = $Name

				}

			}

			'Description'
			{

				$_NewClusterProfile.description = $Description

			}

			'ClusterPrefix'
			{

				$_NewClusterProfile.hypervisorHostProfileTemplate.hostPrefix = $ClusterPrefix

			}

			'Scope'
			{

				ForEach ($_Scope in $Scope)
				{

					"[{0}] Adding resource to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

					[void]$_NewClusterProfile.initialScopeUris.Add($_Scope.Uri)

				}

			}

			'VirtualSwitchType'
			{

				# If Standard, check if $PSBoundParameters['DistributedSwitchUsage'] is provided, error if true
				if ($PSBoundParameters['VirtualSwitchType'] -eq 'Standard' -and $PSBoundParameters['DistributedSwitchUsage'])
				{

					$ExceptionMessage = "Setting the hypervisor VirtualSwitchType to 'Standard' and also setting the DistributeSwitchUsage is not supported."
					$ErrorRecord = New-ErrorRecord HPOneView.HypervisorManagerException InvalidVirtualSwitchTypeParameters InvalidOperation 'VirtualSwitchType' -Message $ExceptionMessage

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				if ($PSBoundParameters['VirtualSwitchType'] -eq 'Standard' -and $PSBoundParameters['DistributedSwitchVersion'])
				{

					$ExceptionMessage = "Setting the hypervisor VirtualSwitchType to 'Standard' and also setting the DistributedSwitchVersion is not supported."
					$ErrorRecord = New-ErrorRecord HPOneView.HypervisorManagerException InvalidVirtualSwitchTypeParameters InvalidOperation 'VirtualSwitchType' -Message $ExceptionMessage

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				"[{0}] Setting VirtualSwitchType to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VirtualSwitchType | Write-Verbose

				$_NewClusterProfile.hypervisorClusterSettings.virtualSwitchType = $VirtualSwitchType

			}

			'DistributedSwitchVersion'
			{

				# Error due to VirtualSwitchType not set to 'Distributed'
				if (-not $PSBoundParameters['VirtualSwitchType'])
				{

					$ExceptionMessage = "The Hypervisor Manager '{0}' is not currently configured to manage distributed virtual switch type.  You must specify to use Distributed virtual switch type before setting the version." -f $InputObject.name
					$ErrorRecord = New-ErrorRecord HPOneView.HypervisorManagerException InvalidVirtualSwitchType InvalidOperation 'DistributedSwitchVersion' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# Check to make sure provided version is within $InputObject.AvailableDvsVersions.Contains($DistributedSwitchVersion)
				if (-not $ClusterManager.AvailableDvsVersions.Contains($DistributedSwitchVersion))
				{

					$ExceptionMessage = "The Hypervisor Manager '{0}' does not support the requested DistributedSwitchVersion '{1}'.  Please specify one of the valid supported versions: {2}" -f $InputObject.name, $DistributedSwitchVersion, [String]::Join(', ', $InputObject.AvailableDvsVersions)
					$ErrorRecord = New-ErrorRecord HPOneView.HypervisorManagerException UnsupportedVirtualSwitchVersion InvalidOperation 'DistributedSwitchVersion' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				"[{0}] Setting DistributedSwitchVersion to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $DistributedSwitchVersion | Write-Verbose
				
				$_NewClusterProfile.hypervisorClusterSettings.distributedSwitchVersion = $DistributedSwitchVersion

			}

			'DistributedSwitchUsage'
			{

				# If supplied, and existing manager does not have virtualSwitchType set to Distributed or if $PSBoundParameters['VirtualSwitchType'] not supplied, error
				if (-not $PSBoundParameters['VirtualSwitchType'])
				{

					$ExceptionMessage = "The Hypervisor Manager '{0}' is not currently configured to manage distributed virtual switch type.  You must specify to use Distributed virtual switch type before setting the version." -f $InputObject.name
					$ErrorRecord = New-ErrorRecord HPOneView.HypervisorManagerException InvalidVirtualSwitchType InvalidOperation 'DistributedSwitchVersion' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				"[{0}] Setting DistributedSwitchUsage to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $DistributedSwitchUsage | Write-Verbose

				$_NewClusterProfile.hypervisorClusterSettings.distributedSwitchUsage = $DistributedSwitchUsage

			}

			'HAEnabled'
			{

				$_NewClusterProfile.hypervisorClusterSettings.haEnabled = $HAEnabled

			}

			'DRSEnabled'
			{

				"[{0}] Updating DRSEnabled to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $DRSEnabled | Write-Verbose

				$_NewClusterProfile.hypervisorClusterSettings.drsEnabled = $DRSEnabled

			}

			'MultiNicVMotionEnabled'
			{

				"[{0}] Updating MultiNicVMotionEnabled to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $MultiNicVMotionEnabled | Write-Verbose

				$_NewClusterProfile.hypervisorClusterSettings.multiNicVMotion = $MultiNicVMotionEnabled

			}

			'ClusterManager'
			{

				if ($PSCmdlet.ParameterSetName -eq 'Default')
				{

					"[{0}] Using hypervisor managers default networking preferences" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_NewClusterProfile.hypervisorClusterSettings.distributedSwitchVersion = $ClusterManager.Preferences.DistributedSwitchVersion
					$_NewClusterProfile.hypervisorClusterSettings.distributedSwitchUsage   = $ClusterManager.Preferences.DistributedSwitchUsage
					$_NewClusterProfile.hypervisorClusterSettings.drsEnabled               = $ClusterManager.Preferences.DrsEnabled
					$_NewClusterProfile.hypervisorClusterSettings.haEnabled                = $ClusterManager.Preferences.HaEnabled
					$_NewClusterProfile.hypervisorClusterSettings.multiNicVMotion          = $ClusterManager.Preferences.MultiNicVMotion
					$_NewClusterProfile.hypervisorClusterSettings.virtualSwitchType        = $ClusterManager.Preferences.VirtualSwitchType

				}

				$_NewClusterProfile.hypervisorManagerUri = $ClusterManager.Uri

			}

			'ClusterManagerLocation'
			{

				# Generate error that path is not valid
				if (-not $ClusterManager.ResourcePaths.Contains($ClusterManagerLocation))
				{

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				"[{0}] Setting hypervisor manager location: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ClusterManagerLocation | Write-Verbose

				$_NewClusterProfile.path = $ClusterManagerLocation

			}

		}

		
		


	}

	end
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Namreposie, $_appliance.Name | Write-Verbose

	}

}
