function Set-HPOVApplianceNetworkConfig 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	   
	[CmdletBinding (DefaultParameterSetName = "VMA")]
	Param 
	(
	   
		[Parameter (Mandatory, ParameterSetName = "VMA")]
		[Parameter (Mandatory, ParameterSetName = "Composer")]
		[ValidateNotNullorEmpty()]
		[string]$Hostname,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[ValidateSet ('DHCP','STATIC')]
		[string]$IPv4Type = 'STATIC',

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory, ParameterSetName = "Composer")]
		[ValidateScript({ [string]::IsNullOrEmpty($_) -or
			$_ -match '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' +
			'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' +
			'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' +
			'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' +
			'(/0*([1-9]|[12][0-9]|3[0-2]))?$' })]
		[Net.IPAddress]$IPv4Addr,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory, ParameterSetName = "Composer")]
		[ValidateScript({
		
			($_ -ge 1 -and $_ -le 32) -or
			($_ -match [Net.IPAddress]$_)			
		
		})]
		[String]$IPv4Subnet,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory, ParameterSetName = "Composer")]
		[ValidateScript({ [string]::IsNullOrEmpty($_) -or
			$_ -match [Net.IPAddress]$_})]
		[Net.IPAddress]$IPv4Gateway,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[ValidateSet ('DHCP','STATIC','UNCONFIGURE')]
		[string]$IPv6Type = 'UNCONFIGURE',

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[ValidateScript({ [string]::IsNullOrEmpty($_) -or
			$_ -match [Net.IPAddress]$_})]
		[Net.IPAddress]$IPv6Addr,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[ValidateNotNullorEmpty()]
		[string]$IPv6Subnet,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[ValidateScript({ [string]::IsNullOrEmpty($_) -or
			$_ -match [Net.IPAddress]$_})]
		[string]$IPv6Gateway,

		[Parameter (Mandatory, ParameterSetName = "Composer")]
		[ValidateScript({ [string]::IsNullOrEmpty($_) -or
			$_ -match [Net.IPAddress]$_})]
		[Net.IPAddress]$ServiceIPv4Node1,

		[Parameter (Mandatory, ParameterSetName = "Composer")]
		[ValidateScript({ [string]::IsNullOrEmpty($_) -or
			$_ -match [Net.IPAddress]$_})]
		[Net.IPAddress]$ServiceIPv4Node2,

		[Parameter (Mandatory= $false, ParameterSetName = "Composer")]
		[ValidateScript({ [string]::IsNullOrEmpty($_) -or
			$_ -match [Net.IPAddress]$_})]
		[Net.IPAddress]$ServiceIPv6Node1,
		
		[Parameter (Mandatory= $false, ParameterSetName = "Composer")]
		[ValidateScript({ [string]::IsNullOrEmpty($_) -or
			$_ -match [Net.IPAddress]$_})]
		[Net.IPAddress]$ServiceIPv6Node2,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[Alias ('overrideDhcpDns')]
		[switch]$OverrideIPv4DhcpDns,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[switch]$OverrideIPv6DhcpDns,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[ValidateNotNullorEmpty()]
		[string]$DomainName,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[ValidateNotNullorEmpty()]
		[Array]$SearchDomains,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[ValidateNotNullorEmpty()]
		[Alias ('nameServers')]
		[Array]$IPv4NameServers,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[ValidateNotNullorEmpty()]
		[Array]$IPv6NameServers,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Object]$NtpServers,

		[Parameter (Mandatory, ParameterSetName = "importFile")]
		[Alias ("i", "import")]
		[ValidateScript({Test-Path $_})]
		[Object]$importFile,

		[Parameter (Mandatory = $false, ParameterSetName = "VMA")]
		[Parameter (Mandatory = $false, ParameterSetName = "Composer")]
		[Parameter (Mandatory = $false, ParameterSetName = "importFile")]
		[ValidateNotNullOrEmpty()]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($PSBoundParameters['NtpServers'])
		{

			Write-Warning 'The -NtpServer Parameter has been deprecated, and is now controlled in the Set-HPOVApplianceDateTime Cmdlet.  Please update your scripts accordingly.'

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

		if  ($ApplianceConnection.Count -gt 1)
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException MultipleApplianceConnections InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter contains multiple Appliance Connections.  This CMDLET only supports 1 Appliance Connection in the ApplianceConnect Parameter value.  Please correct this and try again.'
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$colStatus = New-Object System.Collections.ArrayList

	}

	Process 
	{

		# Locate the Enclosure Group specified
		"[{0}] - Starting" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if ($ApplianceConnection.ApplianceType -eq 'Composer' -and (-not($PSBoundParameters['ServiceIPv4Node1']) -or -not($PSBoundParameters['ServiceIPv4Node2'])))
		{

			$ErrorRecord = New-ErrorRecord InvalidOperationException MissingParameterValues InvalidOperation $ApplianceConnection.Name -Message 'The connected appliance type is a Synergy Composer, however the required -ServiceIPv4Node1 and/or -ServiceIPv4Node2 Parameter (s) was(were) not provided. Please correct the call and try again.'
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Validate the appliance can Begin Network configuration of the appliance
		Try
		{

			"[{0}] Validating Network can be configured on the appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_resp = Send-HPOVRequest -Uri $ApplianceNetworkStatusUri -Hostname $ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if (-not($_resp.networkingAllowed))
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException UnableToEditApplianceNetwork InvalidOperation $ApplianceConnection.Name -Message ($_resp.disabledReason -join "  ")
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		# Get the current config (to get ETag & ensure we don't overwrite anything):
		Try
		{

			$_currentconfig = Send-HPOVRequest -Uri $ApplianceNetworkConfigUri -Hostname $ApplianceConnection.Name

		}
		
		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		Switch ($PSCmdlet.ParameterSetName) 
		{
	
			{"VMA",'Composer' -contains $_}
			{

				 "[{0}] Looking for Primary interface configuration." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				[int]$i = 0
				
				$_deviceIndex = $null
				
				For ($i -eq 0; $i -le ($_currentconfig.applianceNetworks.Count - 1); $i++)
				{

					if($_currentconfig.applianceNetworks[$i].interfaceName -eq "Appliance")
					{
						
						"[{0}] Found interface: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_currentconfig.applianceNetworks[$i].interfaceName | Write-Verbose
						
						$_deviceIndex = $i

						$_configured = $true
						
						#break out of for loop
						break

					}

				}

			}

			"importFile" 
			{

				try 
				{

					$_importConfig = [string]::Join("", (Get-Content $importfile -ErrorAction Stop))

					$_importConfig = $_importConfig -replace "\s","" | convertfrom-json -ErrorAction Stop

				}

				catch [System.Management.Automation.ItemNotFoundException] 
				{
	
					$ErrorRecord = New-ErrorRecord System.Management.Automation.ItemNotFoundException ImportFileNotFound ObjectNotFound 'Set-HPOVApplianceNetworkConfig' -Message "$importFile not found!"
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
	
				}
	
				catch [System.ArgumentException] 
				{
	
					$ErrorRecord = New-ErrorRecord System.ArgumentException InvalidJSON ParseErrror 'Set-HPOVApplianceNetworkConfig' -Message "Input JSON format incorrect!"
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)    

				}

	
				[int]$i = 0

				For ($i -eq 0; $i -le ($_importConfig.applianceNetworks.Count - 1); $i++)
				{

					if ($_importConfig.applianceNetworks[$i].IPv4Gateway -eq "127.0.0.1")
					{

						$_importConfig.applianceNetworks[$i].IPv4Gateway = $null

					}

					if ($_importConfig.applianceNetworks[$i].nameServers -is [String])
					{

						$_importConfig.applianceNetworks[$i].nameServers = New-Object.System.Collections.ArrayList

					}

					if ($_importConfig.applianceNetworks[$i].searchDomains -is [String])
					{

						$importConfig.applianceNetworks[$i].searchDomains = New-Object.System.Collections.ArrayList

					}
					
					if (-not($_importConfig.applianceNetworks[$i].macAddress)) 
					{

						#$_macAddr = ($_importConfig.applianceNetworks | ? { $_.device -eq $_importConfig.applianceNetworks[$i].device }).macAddress

						if (-not $_importConfig.applianceNetworks[$i].macAddress) 
						{

							$_macAddr = ($_currentconfig.applianceNetworks | Where-Object { $_.device -eq $_importConfig.applianceNetworks[$i].device }).macAddress

						}

						if(-not $_macAddr)
						{

							$ErrorRecord = New-ErrorRecord InvalidOperationException ApplianceNICResourceNotFound ObjectNotFound 'Device' -Message ($_importConfig.applianceNetworks[$i].device + "does not exist on the appliance.")
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						$_importConfig.applianceNetworks[$i] | Add-Member -NotePropertyName macAddress -NotePropertyValue $_macAddr
	
					}

					if ($_importConfig.applianceNetworks[$i].interfaceName -eq 'Appliance' -and $_importConfig.applianceNetworks[$i].ipv4Type -eq 'STATIC')
					{

						# Clear non-virtIpv4Addr value for non-Composer appliances
						if ($ApplianceConnection.ApplianceType -ne 'Composer')
						{

							$_importConfig.applianceNetworks[$i].virtIpv4Addr = $null
							$_importConfig.applianceNetworks[$i].app2Ipv4Addr = $null

						}

						# This is needed for when we attempt to reconnect back to the appliance
						[IPAddress]$IPv4Addr = $_importConfig.applianceNetworks[$i].app1Ipv4Addr

					}

				}

				#zero the $currentConfig.applianceNetworks array so we can sEnd it all new values
				$_currentConfig.applianceNetworks = $_importConfig.applianceNetworks

			}

		}

		if ($_configured)
		{

			# Update any non-null values that were passed-in:
			
			if ($Hostname) 
			{

				if ($DomainName)
				{

					$Hostname += '.{0}' -f $DomainName

				}

				$_currentconfig.applianceNetworks[$_deviceIndex].hostname = $Hostname 

			}

			if ($DomainName)    { $_currentconfig.applianceNetworks[$_deviceIndex].domainName    = $DomainName }
			if ($SearchDomains) { $_currentconfig.applianceNetworks[$_deviceIndex].searchDomains = $SearchDomains }

			$_currentconfig.applianceNetworks[$_deviceIndex].IPv4Type = $IPv4Type.ToUpper()
			$_currentconfig.applianceNetworks[$_deviceIndex].IPv6Type = $IPv6Type.ToUpper() 

			switch ($IPv4Type)
			{

				'DHCP'
				{

					if ($ApplianceConnection.ApplianceType -eq 'Composer')
					{

						$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidIPv4AddressType InvalidOperation 'IPv4Type' -Message 'The connected appliance type is a Synergy Composer, only Static IPv4Address configurations are allowed.'
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					'[{0}] Configuring DHCP for NIC' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

					$_currentconfig.applianceNetworks[$_deviceIndex].app1IPv4Addr = $null

					# If $overrideIPv4DhcpDns is true, set it, if not make sure it is fale
					if ($PSBoundParameters['OverrideIPv4DhcpDns']) 
					{ 
						
						$_currentconfig.applianceNetworks[$_deviceIndex].overrideIPv4DhcpDnsServers = [bool]$OverrideIPv4DhcpDns 
					
					}

					else 
					{ 
						
						$_currentconfig.applianceNetworks[$_deviceIndex].overrideIPv4DhcpDnsServers = $false 
					
					}

				}

				'STATIC'
				{

					'[{0}] Configuring STATIC for NIC' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

					# Make sure override.. is false if STATIC ip addresses are in use.
					$_currentconfig.applianceNetworks[$_deviceIndex].overrideIPv4DhcpDnsServers = $false 

					if ((-not($PSBoundParameters['IPv4Subnet'])) -or ([Net.IPAddress]$IPv4Subnet -eq 0.0.0.0) -or $null -eq $IPv4Subnet)
					{

						$Message = 'A static IPv4 Address was provided, but not a valid IPv4Subnet Parameter value.  Please correct this and try again.'
						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.NetworkConfigurationException InvalidIPv4Subnet InvalidArgument 'IPv4Subnet' -Message $Message
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)   

					}
					
					# Calculate the CIDR bit value to the SubnetMask Address
					if ($PSBoundParameters['IPv4Subnet'].Length -le 2)
					{

						Try
						{

							"[{0}] Converting Subnet CIDR Bit value to Subnet Mask Address." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							[Int64]$_Int64Value = ([convert]::ToInt64(('1' * $IPv4Subnet + '0' * (32 - $IPv4Subnet)), 2))

							$IPv4Subnet = '{0}.{1}.{2}.{3}' -f ([math]::Truncate($_Int64Value / 16777216)).ToString(),
															   ([math]::Truncate(($_Int64Value % 16777216) / 65536)).ToString(),
															   ([math]::Truncate(($_Int64Value % 65536)/256)).ToString(),
															   ([math]::Truncate($_Int64Value % 256)).ToString()

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

					$_currentconfig.applianceNetworks[$_deviceIndex].IPv4Subnet  = $IPv4Subnet
					$_currentconfig.applianceNetworks[$_deviceIndex].IPv4Gateway = $IPv4Gateway.IPAddressToString

					if ($PSBoundParameters['IPv4NameServers']) 
					{ 
						
						$_currentconfig.applianceNetworks[$_deviceIndex].IPv4NameServers = $IPv4NameServers 
					
					}

					if ($ApplianceConnection.ApplianceType -eq 'Composer')
					{

						'[{0}] Appliance is Composer, setting Service IP1 and Service IP2' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

						$_currentconfig.applianceNetworks[$_deviceIndex].virtIPv4Addr = $IPv4Addr.IPAddressToString
						$_currentconfig.applianceNetworks[$_deviceIndex].app1IPv4Addr = $ServiceIPv4Node1.IPAddressToString
						$_currentconfig.applianceNetworks[$_deviceIndex].app2IPv4Addr = $ServiceIPv4Node2.IPAddressToString

					}

					else
					{

						$_currentconfig.applianceNetworks[$_deviceIndex].app1IPv4Addr = $IPv4Addr.IPAddressToString

					}

				}

			}

			switch ($IPv6Type)    
			{ 

				'STATIC'
				{

					if ($ApplianceConnection.ApplianceType -eq 'Composer')
					{

						$_currentconfig.applianceNetworks[$_deviceIndex].virtIPv6Addr = $IPv6Addr.IPAddressToString

						if ($ServiceIPv6Node1 -and $ServiceIPv6Node2)
						{

							'[{0}] Appliance is Composer, setting Service IPv6 1' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

							$_currentconfig.applianceNetworks[$_deviceIndex].app1IPv6Addr = $ServiceIPv6Node1.IPAddressToString

							'[{0}] Appliance is Composer, setting Service IPv6 2' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

							$_currentconfig.applianceNetworks[$_deviceIndex].app2IPv6Addr = $ServiceIPv6Node2.IPAddressToString

						}

					}

					else
					{

						$_currentconfig.applianceNetworks[$_deviceIndex].app1IPv6Addr = $IPv6Addr.IPAddressToString

					}

					$_currentconfig.applianceNetworks[$_deviceIndex].IPv6Subnet   = $IPv6Subnet 
					$_currentconfig.applianceNetworks[$_deviceIndex].IPv6Gateway  = $IPv6Gateway.IPAddressToString					

					if ($PSBoundParameters['IPv6NameServers']) 
					{ 
						
						$_currentconfig.applianceNetworks[$_deviceIndex].IPv6NameServers = $IPvV6NameServers 
					
					}

				}

				'DHCP'
				{

					# If setting DHCP, clear any existing IP address:
					if ($IPv6Type -ieq "DHCP") 
					{ 
						
						$_currentconfig.applianceNetworks[$_deviceIndex].app1IPv6Addr = $null 
					
					}

					if ($PSBoundParameters['OverrideIPv6DhcpDns']) 
					{ 
						
						$_currentconfig.applianceNetworks[$_deviceIndex].overrideIPv6DhcpDnsServers = [bool]$overrideIPv6DhcpDns 
						$_currentconfig.applianceNetworks[$_deviceIndex].IPv6NameServers            = $IPv6NameServers
					
					}

				}
				
			}

			# Hard code the following settings, for now:
			$_currentconfig.applianceNetworks[$_deviceIndex].confOneNode = "true"  # Always "true", for now
			$_currentconfig.applianceNetworks[$_deviceIndex].activeNode = "1"      # Always "1", for now
		
		}

		"[{0}] Configuration to be applied: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_currentconfig | ConvertTo-Json -Depth 99 | out-string) | Write-Verbose

		# Remove MAC Address value or DHCP setting will break
		if ($_currentconfig.macAddress -and $ApplianceConnectionApplianceType -ne 'Composer')
		{ 
			
			$_currentconfig.macAddress = $null 
		
		}

		# This is an asynch method, so get the returned Task object
		Try
		{

			$_task = Send-HPOVRequest -uri $ApplianceNetworkConfigUri -Method POST  -Body $_currentconfig -Hostname $ApplianceConnection | Wait-HPOVTaskStart

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		# Validate status code 200, even though it should be HTTP/202
		if ($_task.category -eq "tasks" -and $_task.taskState -eq "Running") 
		{
		
			# Start a new stopwatch object
			$sw = [diagnostics.stopwatch]::StartNew()
				
			Do 
			{

				# Should I make this 120 seconds instead of 90?
				$_PercentComplete = [Math]::Round(((($sw.Elapsed.Minutes * 60) + $sw.Elapsed.Seconds) / 90) * 100,$MathMode)
				
				if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
				{ 
					
					"[{0}] Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Percent Complete: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_PercentComplete | Write-Verbose
					Start-Sleep -s 1

				}
				  
				else 
				{

					# Display progress-bar
					Write-Progress -activity "Update Appliance Network Configuration" -Status "Processing $_PercentComplete%" -percentComplete $_PercentComplete 

				}

			} until ($_PercentComplete -eq 100)

			# Stop the stopwatch
			$sw.stop()
			
			Write-Progress -activity "Update Appliance Network Configuration" -Completed
		
		}

		# Task failed validation
		elseif ($_task.taskState -eq "Error") 
		{

			if ($_task.taskErrors -is [Array] -and $_task.taskErrors.count -gt 1 ) 
			{

				for ($e = 0; $e -gt $_task.taskErrors.count; $e++) 
				{

					if ($e -ne $_task.taskErrors.length) 
					{
						
						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.NetworkConfigurationException NoAuthSession AuthenticationError 'Set-HPOVApplianceNetworkConfig' -Message "No valid session ID found.  Please use Connect-HPOVMgmt to connect and authenticate to an appliance."
						$PSCmdlet.WriteError($ErrorRecord)    

					}

					else 
					{

						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoAuthSession AuthenticationError 'Set-HPOVApplianceNetworkConfig' -Message "No valid session ID found.  Please use Connect-HPOVMgmt to connect and authenticate to an appliance."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)    

					}

				}

			}

		}

		if ($IPv4Type -eq "static") 
		{

			Start-Sleep -Seconds 5

			"[{0}] Connecting to new static IP address {1} to validate it is an HPE OneView appliance." -f $MyInvocation.InvocationName.ToString().ToUpper(), $IPv4Addr.IPAddressToString | Write-Verbose

			"[{0}] Add appliance address {1} to TrustedHosts collection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $IPv4Addr.IPAddressToString | Write-Verbose

			# $Validator.AddTrustedHost($IPv4Addr.IPAddressToString)
			[HPOneView.PKI.SslValidation]::AddTrustedHost($IPv4Addr.IPAddressToString)
			
			# Check to make sure we connect to a OneView appliance
			Try
			{

				$Url = "https://{0}" -f $IPv4Addr.IPAddressToString

				$_WebClient = (New-Object HPOneView.Utilities.Net).RestClient($Url, 'GET', 0)

				[System.Net.WebResponse]$_response = $_WebClient.GetResponse()
				$_reader = New-Object IO.StreamReader($_response.GetResponseStream())
				$_resp = $_reader.ReadToEnd()
				$_reader.close()

			}

			Catch
			{

				"[{0}] Exception caught: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_.Exception | Write-Verbose

				# Try to connect to the appliance with the original address
				Try
				{

					$_task = Send-HPOVRequest -uri $_task.uri -Hostname $ApplianceConnection

					if ($_task.taskState -eq 'Error')
					{

						$_task.taskErrors | ForEach-Object { $Message += ('{0} {1} ({2}) {3}' -f $_.message, $_.details, $_.errorCode, ($_.recommEndedActions -Join ' ')) }
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.NetworkConfigurationException InvalidApplianceNetworkConfigResult InvalidResult 'Set-HPOVApplianceNetworkConfig' -Message $Message
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					else
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# If successful, update current POSH session
			if ($_resp -match "<title>OneView</title>") 
			{ 

				"[{0}] Updating Global Connection Sessions appliance object with new appliance address: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $IPv4Addr.IPAddressToString | Write-Verbose
				
				# if ($Validator.TrustedHosts.ContainsKey($ApplianceConnection.Name))
				if ([HPOneView.PKI.SslValidation]::TrustedHosts.ContainsKey($ApplianceConnection.Name))
				{

					"[{0}] Removing appliance address {1} from TrustedHosts collection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $ApplianceConnection.Name | Write-Verbose

					# $Validator.RemoveTrustedHost($ApplianceConnection.Name)
					[HPOneView.PKI.SslValidation]::RemoveTrustedHost($ApplianceConnection.Name)

				}			

				"[{0}] Updating ConnectedSessions Name property with updated address value: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $IPv4Addr.IPAddressToString | Write-Verbose

				($Global:ConnectedSessions | Where-Object name -eq $ApplianceConnection.Name).SetName($IPv4Addr.IPAddressToString)

			}

			else 
			{

				# Unable to connect to new appliance address or connection failed.  Need to generate error here.
				$ExceptionMessage = "Unable to reconnect to the appliance.  Please check to make sure there are no IP Address conflicts or your set the IP Address and Subnet Mask correctly."
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.NetworkConnectionException ApplianceUnreachable ConnectionError 'IPv4Addr' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)    

			}

		}

		# Check to see if we can get the final status of the task resource
		Try
		{

			$Task = Send-HPOVRequest $_task.uri -Hostname $ApplianceConnection.Name | Wait-HPOVTaskComplete 

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		[void]$colStatus.Add($Task)

	}

	End
	{

		Return $colStatus

	}

}
