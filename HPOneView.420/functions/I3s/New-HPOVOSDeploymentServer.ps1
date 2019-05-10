function New-HPOVOSDeploymentServer
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[string]$Description,

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[Alias ('ImageStreamer','I3S')]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Object]$ManagementNetwork,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[switch]$Async,

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

		if (-not $PSBoundParameters['InputObject'])
		{

			$PipelineInput = $true

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

	}

	Process
	{

		if ($PipelineInput)
		{

			$ApplianceConnection = $ConnectedSessions | Where-Object Name -eq $ApplianceConnection.Name

		}

		If ($ApplianceConnection.ApplianceType -ne 'Composer')
		{

			$ExceptionMessage = 'The ApplianceConnection {0} ({1}) is not a Synergy Composer.  This Cmdlet only support Synergy Composer management appliances.' -f $ApplianceConnection.Name, $ApplianceConnection.ApplianceType
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Validate the Management Network resource
		if ($ManagementNetwork -is [String])
		{

			"[{0}] ManagementNetwork Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ManagementNetwork | Write-Verbose

			Try
			{

				$ManagementNetwork = Get-HPOVNetwork -Name $ManagementNetwork -Type Ethernet -ApplianceConnection $ApplianceConnection -ErrorAction Stop

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		# Validation rules
		if ($ManagementNetwork.category -ne 'ethernet-networks')
		{

			"[{0}] Unsupported Network: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ManagementNetwork.name | Write-Verbose

			$ExceptionMessage = 'The ManagementNetwork {0} is not a valid "ethernet-network".' -f $ManagementNetwork.name
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ImageStreamerManagementNetworkException UnsupportedNetwork InvalidArgument 'ManagementNetwork' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
		}

		if ([System.String]::IsNullOrWhiteSpace($ManagementNetwork.subnetUri))
		{

			$ExceptionMessage = 'The ManagementNetwork {0} resource is not assigned to a valid IPv4 Address Pool.' -f $ManagementNetwork.name
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ImageStreamerManagementNetworkException UnsupportedEthernetNetwork InvalidArgument 'ManagementNetwork' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Get Subnet resource
		Try
		{

			$_ManagementNetworkSubnet = Send-HPOVRequest -Uri $ManagementNetwork.subnetUri -Hostname $ApplianceConnection
			$_ApplianceNetwork        = Send-HPOVRequest -uri $ApplianceNetworkConfigUri -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if ($_ManagementNetworkSubnet.subnetMask -ne $_ApplianceNetwork.applianceNetworks.ipv4Subnet)
		{

			$ExceptionMessage = 'The ManagementNetwork "{0}" resource Subnet Mask "{1}" does not match the appliance Subnet Mask "{2}".' -f $ManagementNetwork.name, $_ManagementNetworkSubnet.subnetMask, $_ApplianceNetwork.applianceNetworks.ipv4Subnet
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ImageStreamerManagementNetworkException UnsupportedEthernetNetwork InvalidArgument 'ManagementNetwork' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if (-not [HPOneView.Appliance.AddressPool]::IsInSameSubnet($_ManagementNetworkSubnet.networkId, $_ApplianceNetwork.applianceNetworks.virtIpv4Addr, $_ApplianceNetwork.applianceNetworks.ipv4Subnet))
		{

			$ExceptionMessage = "The ManagementNetwork's associated IPv4 Subnet {0} is not local to the appliance.  ImageStreamer requires the IPv4 Subnet be on the same NetworkID as the appliance." -f $_ManagementNetworkSubnet.name
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ImageStreamerManagementNetworkException UnsupportedEthernetNetwork InvalidArgument 'ManagementNetwork' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Validate InputObject
		if (-not $InputObject.uri.StartsWith($AvailableDeploymentServersUri))
		{

			$ExceptionMessage = 'The InputObject is not a valid ImageStreamer resource.' -f $InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ImageStreamerManagementNetworkException InvalidInputObject InvalidArgument 'InputObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_AddI3S = NewObject -I3SAdd

		$_AddI3S.description    = $Description
		$_AddI3S.name           = $Name
		$_AddI3S.mgmtNetworkUri = $ManagementNetwork.uri
		$_AddI3S.applianceUri   = $InputObject.uri

		Try
		{

			$_Results = Send-HPOVRequest -Uri $DeploymentServersUri -Method POST -Body $_AddI3S -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not $PSBoundParameters['Async'])
		{

			$_Results | Wait-HPOVTaskComplete

		}

		else
		{

			$_Results

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
