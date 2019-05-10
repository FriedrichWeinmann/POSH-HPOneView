function Set-HPOVHypervisorManager
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Alias('Name')]
		[HPOneView.Cluster.HypervisorManager]$InputObject,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Hostname,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$DisplayName,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateRange (1, 65535)]
		[Int]$Port,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateSet ('Distributed', 'Standard')]
		[String]$VirtualSwitchType,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateSet ('AllNetworks', 'GeneralNetworks')]
		[String]$DistributedSwitchUsage,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateSet ('4.0', '4.1.0', '5.0.0', '5.1.0', '5.5.0', '6.0', '6.7')]
		[String]$DistributedSwitchVersion,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]$HAEnabled,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Bool]$DRSEnabled,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Bool]$MultiNicVMotionEnabled,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
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

		$_UpdateHypervisorManagerDetails = [PSCustomObject]@{
			type        = 'HypervisorManagerV2';
			name        = $InputObject.Name
			username    = $InputObject.Username;
			password    = $InputObject.Password;
			displayName = $InputObject.DisplayName;
			preferences = [PSCustomObject]@{
				type = 'Vmware';
				virtualSwitchType        = $InputObject.Preferences.VirtualSwitchType
				distributedSwitchVersion = $InputObject.Preferences.DistributedSwitchVersion
				distributedSwitchUsage   = $InputObject.Preferences.DistributedSwitchUsage
				multiNicVMotion          = $InputObject.Preferences.MultiNicVMotion
				drsEnabled               = $InputObject.Preferences.DRSEnabled
				haEnabled                = $InputObject.Preferences.HAEnabled
			}
		}

		Switch ($PSBoundParameters.Keys)
		{

			'DisplayName'
			{

				"[{0}] Updating displayname to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $DisplayName | Write-Verbose

				$_UpdateHypervisorManagerDetails.displayName = $DisplayName

			}

			'Hostname'
			{

				"[{0}] Updating name to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Hostname | Write-Verbose

				$_UpdateHypervisorManagerDetails.name = $Hostname

			}

			'Credential'
			{

				"[{0}] Updating credential to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Credential.Username | Write-Verbose
				
				$_UpdateHypervisorManagerDetails.username = $Credential.Username
				$_UpdateHypervisorManagerDetails.password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

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

				if (-not $PSBoundParameters['DistributedSwitchUsage'])
				{

					$ExceptionMessage = "Setting the hypervisor VirtualSwitchType to 'Distributed' requires the -DistributedSwitchUsage parameter."
					$ErrorRecord = New-ErrorRecord HPOneView.HypervisorManagerException InvalidVirtualSwitchTypeParameters InvalidOperation 'VirtualSwitchType' -Message $ExceptionMessage

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				if (-not $PSBoundParameters['DistributedSwitchVersion'])
				{

					$ExceptionMessage = "Setting the hypervisor VirtualSwitchType to 'Distributed' requires the -DistributedSwitchVersion parameter."
					$ErrorRecord = New-ErrorRecord HPOneView.HypervisorManagerException InvalidVirtualSwitchTypeParameters InvalidOperation 'VirtualSwitchType' -Message $ExceptionMessage

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				"[{0}] Updating VirtualSwitchType to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VirtualSwitchType | Write-Verbose

				$_UpdateHypervisorManagerDetails.preferences.virtualSwitchType = $VirtualSwitchType

			}

			'DistributedSwitchVersion'
			{

				# Error due to VirtualSwitchType not set to 'Distributed'
				if ($InputObject.Preferences.VirtualSwitchType -eq 'Standard' -and -not $PSBoundParameters['VirtualSwitchType'])
				{

					$ExceptionMessage = "The Hypervisor Manager '{0}' is not currently configured to manage distributed virtual switch type.  You must specify to use Distributed virtual switch type before setting the version." -f $InputObject.name
					$ErrorRecord = New-ErrorRecord HPOneView.HypervisorManagerException InvalidVirtualSwitchType InvalidOperation 'DistributedSwitchVersion' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# Check to make sure provided version is within $InputObject.AvailableDvsVersions.Contains($DistributedSwitchVersion)
				if (-not $InputObject.AvailableDvsVersions.Contains($DistributedSwitchVersion))
				{

					$ExceptionMessage = "The Hypervisor Manager '{0}' does not support the requested DistributedSwitchVersion '{1}'.  Please specify one of the valid supported versions: {2}" -f $InputObject.name, $DistributedSwitchVersion, [String]::Join(', ', $InputObject.AvailableDvsVersions)
					$ErrorRecord = New-ErrorRecord HPOneView.HypervisorManagerException UnsupportedVirtualSwitchVersion InvalidOperation 'DistributedSwitchVersion' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				"[{0}] Updating DistributedSwitchVersion to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $DistributedSwitchVersion | Write-Verbose
				
				$_UpdateHypervisorManagerDetails.preferences.distributedSwitchVersion = $DistributedSwitchVersion

			}

			'DistributedSwitchUsage'
			{

				# If supplied, and existing manager does not have virtualSwitchType set to Distributed or if $PSBoundParameters['VirtualSwitchType'] not supplied, error
				if ($InputObject.Preferences.VirtualSwitchType -eq 'Standard' -and -not $PSBoundParameters['VirtualSwitchType'])
				{

					$ExceptionMessage = "The Hypervisor Manager '{0}' is not currently configured to manage distributed virtual switch type.  You must specify to use Distributed virtual switch type before setting the version." -f $InputObject.name
					$ErrorRecord = New-ErrorRecord HPOneView.HypervisorManagerException InvalidVirtualSwitchType InvalidOperation 'DistributedSwitchVersion' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				"[{0}] Updating DistributedSwitchUsage to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $DistributedSwitchUsage | Write-Verbose

				$_UpdateHypervisorManagerDetails.preferences.distributedSwitchUsage = $DistributedSwitchUsage

			}

			'HAEnabled'
			{

				$_UpdateHypervisorManagerDetails.preferences.haEnabled = $HAEnabled

			}

			'DRSEnabled'
			{

				"[{0}] Updating DRSEnabled to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $DRSEnabled | Write-Verbose

				$_UpdateHypervisorManagerDetails.preferences.drsEnabled = $DRSEnabled

			}

			'MultiNicVMotionEnabled'
			{

				"[{0}] Updating MultiNicVMotionEnabled to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $MultiNicVMotionEnabled | Write-Verbose

				$_UpdateHypervisorManagerDetails.preferences.multiNicVMotion = $MultiNicVMotionEnabled

			}

		}

		Try
		{
		
			$_resp = Send-HPOVRequest -Uri $InputObject.Uri -Method PUT -Body $_UpdateHypervisorManagerDetails -AddHeader @{'If-Match' = "*"} -Hostname $InputObject.ApplianceConnection
		
		}
		
		Catch
		{
		
			$PSCmdlet.ThrowTerminatingError($_)
		
		}

		if (-not $Async)
		{

			$_resp = Wait-HPOVTaskComplete -InputObject $_resp

		}

		$_resp

	}

	end
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
