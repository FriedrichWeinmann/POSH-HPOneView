function Add-HPOVSanManager 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "BNA")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory, ParameterSetName = "BNA")]
		[ValidateSet ("Brocade","BNA","Brocade Network Advisor","HP","HPE","Cisco")]
		[string]$Type,

		[Parameter (Mandatory, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory, ParameterSetName = "BNA")]
		[ValidateNotNullOrEmpty()]
		[string]$Hostname,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory = $false, ParameterSetName = "BNA")]
		[ValidateNotNullOrEmpty()]
		[ValidateRange(1,65535)]
		[int]$Port = 0,
		 
		[Parameter (Mandatory, ParameterSetName = "BNA")]
		[ValidateNotNullOrEmpty()]
		[string]$Username,

		[Parameter (Mandatory, ParameterSetName = "BNA")]
		[ValidateNotNullOrEmpty()]
		[Object]$Password,

		[Parameter (Mandatory, ParameterSetName = "HPCisco")]
		[string]$SnmpUserName,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[ValidateSet ("None","AuthOnly","AuthAndPriv")]
		[ValidateNotNullOrEmpty()]
		[string]$SnmpAuthLevel = "None",

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[ValidateSet ("sha","md5")]	
		[ValidateNotNullOrEmpty()]
		[string]$SnmpAuthProtocol,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[ValidateNotNullOrEmpty()]
		[Object]$SnmpAuthPassword,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[ValidateSet ("aes-128","des56","3des")]	
		[ValidateNotNullOrEmpty()]
		[string]$SnmpPrivProtocol,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[ValidateNotNullOrEmpty()]
		[Object]$SnmpPrivPassword,

		[Parameter (Mandatory = $false, ParameterSetName = "BNA")]
		[switch]$UseSsl,
		
		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory = $false, ParameterSetName = "BNA")]
		[switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory = $false, ParameterSetName = "BNA")]
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

		$TaskCollection = New-Object System.Collections.ArrayList

		if ($SnmpAuthLevel -eq "AuthOnly" -and 
			(-not $SnmpAuthProtocol -or 
			-not $SnmpAuthPassword)) 
		{

			# Generate Terminateing error
			$ErrorRecord = New-ErrorRecord HPOneView.SanManagerResourceException MissingRequiredParameters InvalidArgument 'Add-HPOVSanManager' -Message "The -SnmpAuthLevel Parameter was set to 'AuthOnly', but did not include both -SnmpAuthProtocol and -SnmpAuthPassword Parameters."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($SnmpAuthLevel -eq "AuthAndPriv" -and (
			-not $SnmpAuthProtocol -or 
			-not $SnmpAuthPassword -or 
			-not $SnmpPrivProtocol -or 
			-not $SnmpPrivPassword )) 
		{

			# Generate Terminateing error
			$ErrorRecord = New-ErrorRecord HPOneView.SanManagerResourceException MissingRequiredParameters InvalidArgument 'Add-HPOVSanManager' -Message "The -SnmpAuthLevel Parameter was set to 'AuthAndPriv', but did not include -SnmpAuthProtocol, -SnmpAuthPassword, -SnmpPrivProtocol and -SnmpPrivPassword Parameters."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Cisco MDS/Nexus SNMP Auth Parameter validation
		if ($type -eq 'Cisco' -and $SnmpAuthLevel -eq 'None')
		{

			$ErrorRecord = New-ErrorRecord HPOneView.SanManagerResourceException UnsupportedSnmpAuthLevel InvalidArgument 'SnmpAuthLevel' -Message "The -SnmpAuthLevel Parameter value $($SnmpAuthLevel) is invalid for configuring a Cisco SAN Manager.  Please specify either 'AuthOnly' or 'AuthAndPriv' and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Cisco MDS/Nexus SNMP Auth Parameter validation
		if ($type -eq 'Cisco' -and $SnmpPrivProtocol -eq '3DES')
		{

			$ErrorRecord = New-ErrorRecord HPOneView.SanManagerResourceException UnsupportedSnmpPrivProtocol InvalidArgument 'SnmpPrivProtocol' -Message "The -SnmpPrivProtocol Parameter value $($SnmpPrivProtocol) is invalid for configuring a Cisco SAN Manager.  Please specify either 'des56' or 'aes-128' and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($Password -is [System.Security.SecureString])
		{

			$Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

		}

		if ($SnmpPrivPassword -is [SecureString])
		{

			$SnmpPrivPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SnmpPrivPassword))

		}

		if ($SnmpAuthPassword -is [SecureString])
		{

			$SnmpAuthPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SnmpAuthPassword))

		}

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			if ($Type -eq 'HP') { $Type = 'HPE' }

			"[{0}] SAN Manager Type requested: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Type | Write-Verbose

			#Basic SAN Manager Object
			$_sanmanager = NewObject -SanManager

			$_sanmanagerhostconnectinfo = NewObject -SanManagerConnectInfo
			$_sanmanagerhostconnectinfo.name = "Host"
			$_sanmanagerhostconnectinfo.Value = $Hostname
			[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)

			# Get SAN Manager Providers
			"[{0}] Getting available SAN Manager Providers" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_SanManagerProviders = Send-HPOVRequest -Uri $FcSanManagerProvidersUri -Hostname $_appliance.Name

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			switch ($type) 
			{
				
				{ @('Brocade','BNA','Brocade Network Advisor') -contains $_ } 
				{ 
					
					if ($Port -eq 0) 
					{ 
						
						$Port = 5989 
					
					}

					$_SanManagerProviderUri = ($_SanManagerProviders.members | Where-Object name -eq 'Brocade San Plugin').deviceManagersUri

					$_sanmanagerhostconnectinfo = NewObject -SanManagerConnectInfo
					$_sanmanagerhostconnectinfo.name = "Username"
					$_sanmanagerhostconnectinfo.Value = $Username
					[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)

					$_sanmanagerhostconnectinfo = NewObject -SanManagerConnectInfo
					$_sanmanagerhostconnectinfo.name = "Password"
					$_sanmanagerhostconnectinfo.Value = $Password
					[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)

					$_sanmanagerhostconnectinfo       = NewObject -SanManagerConnectInfo
					$_sanmanagerhostconnectinfo.name  = "UseSsl"
					$_sanmanagerhostconnectinfo.Value = [bool]$UseSsl
					[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)
					
					$_sanmanagerhostconnectinfo       = NewObject -SanManagerConnectInfo
					$_sanmanagerhostconnectinfo.name  = "Port"
					$_sanmanagerhostconnectinfo.Value = $Port
					[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)

				}

				{ @("HPE","Cisco") -contains $_ } 
				{ 

					if ($Port -eq 0) 
					{ 
						
						$Port = 161 
					
					}

					$_SanManagerProviderUri = ($_SanManagerProviders.members | Where-Object name -eq ($Type + ' San Plugin')).deviceManagersUri

					$_sanmanagerhostconnectinfo       = NewObject -SanManagerConnectInfo
					$_sanmanagerhostconnectinfo.name  = "SnmpPort"
					$_sanmanagerhostconnectinfo.Value = [int]$Port
					[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)

					$_sanmanagerhostconnectinfo       = NewObject -SanManagerConnectInfo
					$_sanmanagerhostconnectinfo.name  = "SnmpUserName"
					$_sanmanagerhostconnectinfo.Value = $SnmpUserName
					[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)

					$_sanmanagerhostconnectinfo       = NewObject -SanManagerConnectInfo
					$_sanmanagerhostconnectinfo.name  = "SnmpAuthLevel"
					$_sanmanagerhostconnectinfo.Value = $SnmpAuthLevelEnum[$SnmpAuthLevel].ToUpper()
					[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)

					if ($SnmpAuthLevel -ne "None")
					{

						$_sanmanagerhostconnectinfo       = NewObject -SanManagerConnectInfo
						$_sanmanagerhostconnectinfo.name  = "SnmpAuthProtocol"
						$_sanmanagerhostconnectinfo.Value = $SnmpAuthProtocolEnum[$SnmpAuthProtocol]
						[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)

						$_sanmanagerhostconnectinfo       = NewObject -SanManagerConnectInfo
						$_sanmanagerhostconnectinfo.name  = "SnmpAuthString"
						$_sanmanagerhostconnectinfo.Value = $SnmpAuthPassword
						[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)
						
					}

					if ($SnmpAuthLevel -eq "AuthAndPriv")
					{

						$_sanmanagerhostconnectinfo       = NewObject -SanManagerConnectInfo
						$_sanmanagerhostconnectinfo.name  = "SnmpPrivProtocol"
						$_sanmanagerhostconnectinfo.Value = $SnmpPrivProtocolEnum[$SnmpPrivProtocol]
						[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)

						$_sanmanagerhostconnectinfo       = NewObject -SanManagerConnectInfo
						$_sanmanagerhostconnectinfo.name  = "SnmpPrivString"
                        $_sanmanagerhostconnectinfo.Value = $SnmpPrivPassword
						[void]$_sanmanager.connectionInfo.Add($_sanmanagerhostconnectinfo)

					}

				}

			}

			"[{0}] SAN Manager Provider URI: $($_SanManagerProviderUri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			try 
			{
			
				$resp = Send-HPOVRequest $_SanManagerProviderUri POST $_sanmanager -Hostname $_appliance.Name

				"[{0}] Received async task, calling Wait-HPOVTaskComplete" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$resp = Wait-HPOVTaskComplete $resp

			}

			catch 
			{

				if ($_.FullyQualifiedErrorId -eq 'RESOURCE_CONFLICT_ERROR')
				{

					$ErrorRecord = New-ErrorRecord HPOneView.SanManagerResourceException SanManagerAlreadyExists ResourceExists 'Hostname' -Message "The SAN Manager $($Hostname) already exists on appliance $($_appliance.Name)." -InnerException $_.Exception

				}

				else
				{

					$ErrorRecord = $_

				}
				
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			[void]$TaskCollection.Add($resp)

		}

	}

	End
	{

		Return $TaskCollection

	}

}
