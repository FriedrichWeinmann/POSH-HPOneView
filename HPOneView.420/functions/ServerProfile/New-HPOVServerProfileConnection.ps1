function New-HPOVServerProfileConnection 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdLetBinding (DefaultParameterSetName = "Common")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Common")]
		[Parameter (Mandatory, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory, ParameterSetName = "FC")]
		[Parameter (Mandatory, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[Alias ('id')]
		[int]$ConnectionID = 1,

		[Parameter (Mandatory = $false, ParameterSetName = "Common")]
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[ValidateSet ("Ethernet", "FibreChannel", "Eth", "FC", 'FCoE', 'iSCSI', IgnoreCase)]
		[Alias ('type')]
		[string]$ConnectionType = "Ethernet",

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Common")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "FC")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[object]$Network,

		[Parameter (Mandatory = $false, ParameterSetName = "Common")]
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[string]$PortId = "Auto",

		[Parameter (Mandatory = $false, ParameterSetName = "Common")]
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Common")]
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateScript( { [string]$_ -eq 'Auto' -or ([int]$_ -le 20000 -and [int]$_ -ge 100) })]
        [String]$RequestedBW = 2500,
	
		[Parameter (Mandatory = $false, ParameterSetName = "Common")]
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[switch]$UserDefined,

		[Parameter (Mandatory = $false, ParameterSetName = "Common")]
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateScript({$_ -match $MacAddressPattern})]
		[string]$MAC,
	
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[ValidateScript({$_ -match $WwnAddressPattern})]
		[string]$WWNN,
		
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[ValidateScript({$_ -match $WwwnAddressPattern})]
		[string]$WWPN,

		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[ValidateScript( { [int]$_ -ge 0 -or [String]$_ -eq 'Auto' } )] 
		[String]$Virtualfunctions,
	
		[Parameter (Mandatory = $false, ParameterSetName = "Common")]
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[switch]$Bootable,
	
		[Parameter (Mandatory = $false, ParameterSetName = "Common")]
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateSet ('LAG1', 'LAG2', 'LAG3', 'LAG4', 'LAG5', 'LAG6', 'LAG7', 'LAG8', 'LAG9', 'LAG10', 'LAG11', 'LAG12', 'LAG13', 'LAG14', 'LAG15', 'LAG16', 'LAG17', 'LAG18', 'LAG19', 'LAG20', 'LAG21', 'LAG22', 'LAG23', 'LAG24')]
		[String]$LagName,

		[Parameter (Mandatory = $false, ParameterSetName = "Common")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateSet ('AdapterBIOS', 'ManagedVolume', 'UserDefined', IgnoreCase = $false)]
		[String]$BootVolumeSource = 'AdapterBIOS',
	
		[Parameter (Mandatory = $false, ParameterSetName = "Common")]
		[Parameter (Mandatory = $false, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[ValidateSet ('NotBootable', 'Primary', 'Secondary', 'IscsiPrimary', 'IscsiSecondary', 'LoadBalanced', IgnoreCase)]
		[string]$Priority = "NotBootable",
	
		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Alias ('ArrayWwpn')]
		[ValidateScript({$_ -match $WwnAddressPattern})]
		[string]$TargetWwpn,

		[Parameter (Mandatory = $false, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateRange(0,254)]
		[int]$LUN = 0,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateSet ('DHCP', 'UserDefined', 'SubnetPool', IgnoreCase)]
		[string]$IscsiIPv4AddressSource,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[string]$ISCSIInitatorName,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[Net.IPAddress]$IscsiIPv4Address,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[String]$IscsiIPv4SubnetMask,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[Net.IPAddress]$IscsiIPv4Gateway,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[string]$IscsiBootTargetIqn,
	
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[Net.IPAddress]$IscsiPrimaryBootTargetAddress,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateRange(1,65535)]
		[int]$IscsiPrimaryBootTargetPort = 3260,
		
		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[Net.IPAddress]$IscsiSecondaryBootTargetAddress,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateRange(1,65535)]
		[int]$IscsiSecondaryBootTargetPort = 3260,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateSet ('None','CHAP','MutualCHAP')]
		[String]$IscsiAuthenticationProtocol,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[String]$ChapName,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[SecureString]$ChapSecret,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[String]$MutualChapName,

		[Parameter (Mandatory = $false, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[SecureString]$MutualChapSecret,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Common")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Ethernet")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "FC")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "ISCSI")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)
	
	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		"[{0}] ParameterSetName: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PSCmdlet.ParameterSetName | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection) -and -not(${Global:ConnectedSessions}))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command agian."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif ($PSBoundParameters['Network'])
		{

			if ($ApplianceConnection -is [System.Collections.IEnumerable] -and $ApplianceConnection -isnot [System.String])
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

		else
		{

			$Pipeline = $true

		}		

		# Validate Boot settings
		if (('FC','FibreChannel' -contains $ConnectionType) -and $BootVolumeSource -eq 'UserDefined' -and (-not $TargetWwpn))
		{

			$Message     = 'A bootable Fibre Channel connection that is set for "UserDefined" must have the -TargetWwpn Parameter specified.'
			$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException NoTargetWwpnParam InvalidArgument 'BootVolumeSource' -Message $Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}
				
		# Init object collection
		$_Connections = New-Object System.Collections.ArrayList

	}

	Process 
	{	

		if ($Pipeline)
		{

			$ApplianceConnection = ($ConnectedSessions | Where-Object Name -eq $Network.ApplianceConnection.Name)
			
		}

		# Also sets connection functionType property
		switch ($Network.Gettype().Name) 
		{

			"PSCustomObject" 
			{

				if ("fcoe-networks", "fc-networks", "ethernet-networks", "network-sets" -contains $Network.category) 
				{
				
					"[{0}] Network resource provided via Parameter" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
					"[{0}] Network Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Network.name | Write-Verbose 
					"[{0}] Network Category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Network.category | Write-Verbose 
					"[{0}] Creating ConnectionType: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ConnectionType | Write-Verbose 

					switch ($Network.category)
					{

						{"ethernet-networks", "network-sets" -contains $_}
						{

							if ($ConnectionType -eq 'iSCSI' -or ('IscsiPrimary', 'IscsiSecondary' -contains $Priority) -or $PSCmdlet.ParameterSetName -eq "ISCSI")
							{

								$_conn = NewObject -ServerProfileIscsiConnection

							}

							else
							{

								$_conn = NewObject -ServerProfileEthernetConnection

							}

						}

						{"fcoe-networks", "fc-networks" -contains $_}
						{

							$_conn = NewObject -ServerProfileFCConnection

						}

					}
						
					$_conn.id = [Int]$connectionId;

					if (-not $PSBoundParameters['ConnectionType'])
					{

						$_conn.functionType = [String]$ServerProfileConnectionTypeEnum[$Network.category];

					}

					else
					{

						$_conn.functionType = [String]$ServerProfileConnectionTypeEnum[$ConnectionType];

					}
					
					$_conn.name                = [String]$name;
					$_conn.portId              = [String]$portId; 
					$_conn.requestedMbps       = [Int]$requestedBW; 
					$_conn.ApplianceConnection = $Network.ApplianceConnection
					$_conn.networkUri          = $Network.uri

					if ($PSBoundParameters['LagName'] -and $_conn.functionType -eq 'Ethernet' -and $ApplianceConnection.ApplianceType -eq 'Composer')
					{

						$_conn.lagName = $LagName

					}

					elseif ($PSBoundParameters['LagName'] -and $ApplianceConnection.ApplianceType -ne 'Composer')
					{

						$ExceptionMessage = 'The ApplianceConnection {0} is not a Synergy Composer.  The LagName is only supported with HPE Synergy.' -f $ApplianceConnection.Name
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					elseif ($PSBoundParameters['LagName'])
					{

						$ExceptionMessage = "The -Network value category '{0}' does not support LAG configuration.  The LagName parameter is only supported with Ethernet connections." -f $Network.category
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException InvalidLagConfiguration InvalidArgument 'Network' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}
				
				}

				# Generate Error due to incorrect cagtegory
				else 
				{

					$ExceptionMessage = "The -Network value category '{0}' is not 'ethernet-networks', 'fc-networks' or 'network-sets'.  Please check the value and try again." -f $Network.category
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException InvalidNetworkCategory InvalidArgument 'Network' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			default 
			{

				$ExceptionMessage = "The -Network paramter is an invalid type, {0}. Please supply a network object or object collection." -f $Network.GetType().Name
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException InvalidNetworkCategory InvalidArgument 'Network' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		# Set conneciton boot settings
		if ($PSboundParameters['Bootable'])
		{

			if ($Priority -eq 'NotBootable')
			{

				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException InvalidBootPriority InvalidArgument 'Priority' -Message "The Connection is set to be bootable, however no priority value was set.  Please provide either 'Primary' or 'Secondary'."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if ($_conn.functionType -eq 'FibreChannel') 
			{

				"[{0}] FibreChannel Connection.  Processing boot settings." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_conn.boot = NewObject -ServerProfileFcBootableConnection
				$_conn.boot.bootVolumeSource = $BootVolumeSource

				If((-not $PSBoundParameters['TargetWwpn']) -and $BootVolumeSource -eq "UserDefined")
				{
				
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException InvalidFcBootTargetParameters InvalidArgument 'TargetWwpn' -Message "FC Boot specified, and no array target WWPN is provided."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				if ($PSBoundParameters['TargetWwpn'])
				{

					$_conn.boot.bootVolumeSource = 'UserDefined'

					$bootTarget = NewObject -ServerProfileConnectionFcBootTarget
					
					$bootTarget.arrayWwpn = $TargetWwpn
					$bootTarget.lun       = $lun.ToString()

					[void]$_conn.boot.targets.Add($bootTarget)

				}

			}

			else
			{

				if ($PSCmdlet.ParameterSetName -eq 'ISCSI' -or $ConnectionType -eq 'iSCSI')
				{

					# Software iSCSI only supported with Synergy
					if ($ConnectionType -eq 'Ethernet' -and $ApplianceConnection.ApplianceType -ne 'Composer')
					{

						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message ('The ApplianceConnection {0} is not a Synergy Composer.  The LogicalDisk within the StorageController contains a SasLogicalJbod configuration with is only supported with HPE Synergy.' -f $ApplianceConnection.Name)
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					# HW iSCSI Connection
					if ($ConnectionType -eq 'ISCSI')
					{

						"[{0}] Connection will be HW iSCSI type." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_conn.boot = NewObject -ServerProfileIscsiBootableConnectionWithTargets

					}

					# SW iSCSI Connection
					elseif ($ConnectionType -eq 'Ethernet')
					{

						"[{0}] Connection will be SW iSCSI type." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_conn.boot                  = NewObject -ServerProfileEthBootableConnectionWithTargets
						$_conn.boot.ethernetBootType = 'iSCSI'						

					}

					$_conn.boot.iscsi = NewObject -IscsiBootEntry
					# $_conn.ipv4 | Add-Member -NotePropertyName ipv4 -NotePropertyValue (NewObject -IscsiIPv4Configuration)
					$_conn.ipv4 = NewObject -IscsiIPv4Configuration

					if ($PSBoundParameters['BootVolumeSource'])
					{

						$_conn.boot.bootVolumeSource = $BootVolumeSource

					}

					elseif ($_conn.functionType -eq 'Ethernet')
					{

						$_conn.boot.bootVolumeSource = 'UserDefined'

					}

					else
					{

						$ExceptionMessage = 'The connection is bootable, but the -BootVolumeSource parameter was not provided.  Please specify a BootVOlumeSource value.'
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException InvalidBootableConnectionParameters InvalidArgument 'Bootable' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)						

					}

					if ($PSBoundParameters['IscsiIPv4AddressSource'])
					{

						switch ($IscsiIPv4AddressSource)
						{

							'UserDefined'
							{

								"[{0}]Setting iSCSI connection IPv4 settings will be 'UserDefined'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								$_conn.ipv4.ipAddressSource = 'UserDefined'

								if ($PSBoundParameters['IscsiIPv4Address'] -or $PSBoundParameters['IscsiIPv4SubnetMask'])
								{					

									"[{0}]Setting iSCSI connection IPv4 Address: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $IscsiIPv4Address.IPAddressToString | Write-Verbose
									"[{0}]Setting iSCSI connection IPv4 Gateway: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $IscsiIPv4Gateway.IPAddressToString | Write-Verbose

									if ($PSBoundParameters['IscsiIPv4SubnetMask'].Length -le 2)
									{

										Try
										{

											"[{0}] Converting Subnet CIDR Bit value to Subnet Mask Address." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

											[Int64]$_Int64Value = ([convert]::ToInt64(('1' * $IscsiIPv4SubnetMask + '0' * (32 - $IscsiIPv4SubnetMask)), 2))

											[IPAddress]$IscsiIPv4SubnetMask = '{0}.{1}.{2}.{3}' -f ([math]::Truncate($_Int64Value / 16777216)).ToString(),
																				([math]::Truncate(($_Int64Value % 16777216) / 65536)).ToString(),
																				([math]::Truncate(($_Int64Value % 65536)/256)).ToString(),
																				([math]::Truncate($_Int64Value % 256)).ToString()

										}

										Catch
										{

											$PSCmdlet.ThrowTerminatingError($_)

										}

									}

									$_conn.ipv4.ipAddress  = $IscsiIPv4Address.IPAddressToString
									$_conn.ipv4.subnetMask = ([IPAddress]$IscsiIPv4SubnetMask).IPAddressToString
									$_conn.ipv4.gateway    = $IscsiIPv4Gateway.IPAddressToString

								}

							}
							
							default
							{

								if ($IscsiIPv4AddressSource -eq 'SubnetPool' -and $ApplianceConnection.ApplianceType -ne 'Composer')
								{

									$ExceptionMessage = 'The ApplianceConnection {0} is not a Synergy Composer.  The LogicalDisk within the StorageController contains a SasLogicalJbod configuration with is only supported with HPE Synergy.' -f $ApplianceConnection.Name
									$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								$_conn.ipv4.ipAddressSource = $IscsiIPv4AddressSource

							}

						}

					}

					if ($PSBoundParameters['ISCSIInitatorName'])
					{

						$_conn.boot.iscsi.initiatorNameSource = "UserDefined"
						$_conn.boot.iscsi.initiatorName       = $ISCSIInitatorName

					}

					if ($PSBoundParameters['IscsiAuthenticationProtocol'])
					{

						"[{0}] Setting iSCSI auth protocol" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
						
						$_conn.boot.iscsi.chapLevel = $IscsiAuthenticationProtocol
						
						switch ($IscsiAuthenticationProtocol)
						{

							'Chap'
							{

								"[{0}] CHAP" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

								$_conn.boot.iscsi.chapName = $ChapName

								if ($PSBoundParameters['ChapSecret'])
								{

									"[{0}] Setting CHAP secret." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
									$_conn.boot.iscsi.chapSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ChapSecret))

								}						

							}

							'MutualChap'
							{

								"[{0}] MutualCHAP" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

								$_conn.boot.iscsi.chapName       = $ChapName
								$_conn.boot.iscsi.mutualChapName = $MutualChapName

								if ($PSBoundParameters['ChapSecret'])
								{

									"[{0}] Setting CHAP secret." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

									$_conn.boot.iscsi.chapSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ChapSecret))

								}	

								if ($PSBoundParameters['MutualChapSecret'])
								{

									"[{0}] Setting MutualCHAP secret." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

									$_conn.boot.iscsi.mutualChapSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($MutualChapSecret))

								}						

							}

						}

					}
					
					if ($PSBoundParameters['IscsiPrimaryBootTargetAddress'])
					{

						"[{0}] Setting iSCSI Primary boot target: {1}:{2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $IscsiPrimaryBootTargetAddress.IPAddressToString, $IscsiPrimaryBootTargetPort | Write-Verbose 

						$_conn.boot.bootVolumeSource          = 'UserDefined'
						$_conn.boot.iscsi.firstBootTargetIp   = $IscsiPrimaryBootTargetAddress.IPAddressToString
						$_conn.boot.iscsi.firstBootTargetPort = $IscsiPrimaryBootTargetPort

					}
					

					if ($PSBoundParameters['IscsiSecondaryBootTargetAddress'])
					{

						"[{0}] Setting iSCSI Secondary boot target: {1}:{2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $IscsiSecondaryBootTargetAddress.IPAddressToString, $IscsiSecondaryBootTargetPort | Write-Verbose 

						$_conn.boot.iscsi.secondBootTargetIp   = $IscsiSecondaryBootTargetAddress.IPAddressToString
						$_conn.boot.iscsi.secondBootTargetPort = $IscsiSecondaryBootTargetPort

					}

					"[{0}] Setting iSCSI boot target name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $IscsiBootTargetIqn | Write-Verbose 
					"[{0}] Setting iSCSI boot target LUN: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LUN | Write-Verbose 
					
					$_conn.boot.iscsi.bootTargetName = $IscsiBootTargetIqn
					$_conn.boot.iscsi.bootTargetLun  = $LUN

				}

				else
				{

					"[{0}] Ethernet type Connection.  Processing boot settings." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					$_conn.boot = NewObject -ServerProfileEthBootableConnection

				}
				
			}

			"[{0}] Connection object boot priority: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerProfileConnectionBootPriorityEnum[$Priority] | Write-Verbose 

			$_conn.boot.priority = $ServerProfileConnectionBootPriorityEnum[$Priority]			

		}		

		if ($PSboundParameters['Virtualfunctions'] -and $_conn.functionType -eq 'Ethernet' -and $PSCmdlet.ParameterSetName -ne 'ISCSI') 
		{

			$_conn.requestedVFs = $Virtualfunctions

		}

		if ($PSboundParameters['UserDefined'])
		{

			if ($_conn.functionType -eq 'Ethernet')
			{

				$_conn.macType = "UserDefined"
				$_conn.mac     = $mac

			}

			if ($_conn.functionType -eq "FibreChannel")
			{

				if($PSBoundParameters['mac'])
				{

					$_conn.macType  = "UserDefined" 
					$_conn.mac      = $mac 

				}

				$_conn.wwpnType = "UserDefined" 
				$_conn.wwnn     = $wwnn
				$_conn.wwpn     = $wwpn 

			}

		}

		# $_conn = $_conn | Select-Object * -Exclude requestedVFs

		"[{0}] Connection object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_conn | ConvertTo-Json) | Write-Verbose 

		$_conn
 
	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

	}

}
