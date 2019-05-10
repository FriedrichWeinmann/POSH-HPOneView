function New-HPOVAddressPoolSubnet
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(
	
		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Net.IPAddress]$NetworkId,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$SubnetMask,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Net.IPAddress]$Gateway,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[String]$Domain,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Array]$DNSServers,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		# Validate Parameters before auth
		if (($SubnetMask -lt 1 -or $SubnetMask -gt 32) -and ($SubnetMask -notmatch $IPSubnetAddressPattern))
		{

			$Exceptionmessage = "The provided SubnetID {0} does not appear to be a valid Subnet Mask." -f $SubnetMask
			$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolResourceException InvalidIPv4SubnetMask InvalidArgument 'SubnetMask' -TargetType 'String' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

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

		$_SubnetCollection = New-Object System.Collections.ArrayList
					
	}

	Process
	{

		# Calculate the CIDR bit value to the SubnetMask Address
		if ($PSBoundParameters['SubnetMask'].Length -le 2)
		{

			Try
			{

				"[{0}] Converting Subnet CIDR Bit value to Subnet Mask Address." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[Int64]$_Int64Value = ([convert]::ToInt64(('1' * $SubnetMask + '0' * (32 - $SubnetMask)), 2))

				$SubnetMask = '{0}.{1}.{2}.{3}' -f ([math]::Truncate($_Int64Value / 16777216)).ToString(),
													([math]::Truncate(($_Int64Value % 16777216) / 65536)).ToString(),
													([math]::Truncate(($_Int64Value % 65536)/256)).ToString(),
													([math]::Truncate($_Int64Value % 256)).ToString()

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		$_ExcludedIPSubnetIDBin  = (([Net.IPAddress]$ExcludedIPSubnetID).IPAddressToString -split '\.' | ForEach-Object {[System.Convert]::ToString($_,2).PadLeft(8,'0')}) -join ""
		$_ExcludedIPSubnetEndBin = (([Net.IPAddress]$ExcludedIPSubnetEnd).IPAddressToString -split '\.' | ForEach-Object {[System.Convert]::ToString($_,2).PadLeft(8,'0')}) -join ""
		$_NetworIdDecBin         = (([Net.IPAddress]$NetworkId.IPAddressToString).IPAddressToString -split '\.' | ForEach-Object {[System.Convert]::ToString($_,2).PadLeft(8,'0')}) -join ""

		"[{0}] NetworkID overlaps with Reserved Address: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), (($_NetworIdDecBin -eq $_ExcludedIPSubnetIDBin) -or (($_NetworIdDecBin -ge $_ExcludedIPSubnetIDBin) -and ($_NetworIdDecBin -le $_ExcludedIPSubnetEndBin))) | Write-Verbose
		"[{0}] {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_NetworIdDecBin -eq $_ExcludedIPSubnetIDBin) | Write-Verbose
		"[{0}] {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), (($_NetworIdDecBin -ge $_ExcludedIPSubnetIDBin) -and ($_NetworIdDecBin -le $_ExcludedIPSubnetEndBin)) | Write-Verbose

		"[{0}] {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_NetworIdDecBin | Write-Verbose
		"[{0}] {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ExcludedIPSubnetIDBin | Write-Verbose
		"[{0}] {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ExcludedIPSubnetEndBin | Write-Verbose

		#"[{0}] {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_NetworkIdBin -le $_ExcludedIPSubnetEndBin) | Write-Verbose

		ForEach ($_appliance in $ApplianceConnection)
		{

			if (($_NetworIdDecBin -eq $_ExcludedIPSubnetIDBin) -or (($_NetworIdDecBin -ge $_ExcludedIPSubnetIDBin) -and ($_NetworIdDecBin -le $_ExcludedIPSubnetEndBin)))
			{

					"[{0}] The calculated SubnetID overlaps with the reserved IP Address range, 172.30.254.0/24." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolResourceException InvalidIPv4AddressPoolResource InvalidArgument 'NetworkId' -TargetType 'System.Net.IPAddress' -Message ("The provided SubnetID {0} overlaps with the reserved {1} subnet.  Please choose a different IPv4 SubnetID." -f $NetworkId, $ExcludedIPSubnetID.IPAddressToString)
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_NewSubnet = NewObject -IPv4Subnet

				$_NewSubnet.networkId  = $NetworkId.IPAddressToString
				$_NewSubnet.subnetmask = $SubnetMask
			if ($PSBoundParameters['Gateway'])
			{

				$_NewSubnet.gateway = $Gateway.IPAddressToString

			}
				if ($Domain)
				{

					$_NewSubnet.domain = $Domain

				}				
			
				if ($PSBoundParameters['DnsServers'])
				{

				ForEach ($_dnsServer in $DnsServers)
				{ 

					[void]$_NewSubnet.dnsServers.Add($_dnsServer)

					}

				}

				"[{0}] Sending request" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 			

				Try
				{

					$_resp = Send-HPOVRequest $ApplianceIPv4SubnetsUri POST $_NewSubnet -Hostname $_appliance.Name

					$_resp.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.IPv4AddressSubnet")

					[void]$_SubnetCollection.Add($_resp)

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

		}
	
	}

	End
	{

		Return $_SubnetCollection

	}

}
