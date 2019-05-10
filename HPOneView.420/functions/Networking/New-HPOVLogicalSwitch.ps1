function New-HPOVLogicalSwitch
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Managed")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Managed")]
		[Parameter (Mandatory, ParameterSetName = "Monitored")]
		[Parameter (Mandatory, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Managed")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Monitored")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateNotNullOrEmpty()]
		[Object]$LogicalSwitchGroup,

		[Parameter (Mandatory, ParameterSetName = "Managed")]
		[Parameter (Mandatory, ParameterSetName = "ManagedSnmpV3")]
		[switch]$Managed,

		[Parameter (Mandatory, ParameterSetName = "Monitored")]
		[Parameter (Mandatory, ParameterSetName = "MonitoredSnmpV3")]
		[switch]$Monitored,

		[Parameter (Mandatory, ParameterSetName = "Managed")]
		[Parameter (Mandatory, ParameterSetName = "Monitored")]
		[Parameter (Mandatory, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateNotNullOrEmpty()]
		[string]$Switch1Address,

		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $false, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $false, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory = $false, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateNotNullOrEmpty()]
		[string]$Switch2Address,

		[Parameter (Mandatory, ParameterSetName = "Managed")]
		[Parameter (Mandatory, ParameterSetName = "Monitored")]
		[Parameter (Mandatory, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateNotNullOrEmpty()]
		[string]$SshUserName,

		[Parameter (Mandatory, ParameterSetName = "Managed")]
		[Parameter (Mandatory, ParameterSetName = "Monitored")]
		[Parameter (Mandatory, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateNotNullOrEmpty()]
		[Object]$SshPassword,

		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $false, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $false, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory = $false, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateNotNullOrEmpty()]
		[int]$SnmpPort = 161,

		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $false, ParameterSetName = "Monitored")]
		[switch]$SnmpV1,

		[Parameter (Mandatory, ParameterSetName = "Managed")]
		[Parameter (Mandatory, ParameterSetName = "Monitored")]
		[ValidateNotNullOrEmpty()]
		[string]$SnmpCommunity,

		[Parameter (Mandatory = $false, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory = $false, ParameterSetName = "MonitoredSnmpV3")]
		[switch]$SnmpV3,

		[Parameter (Mandatory = $false, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory = $false, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateNotNullOrEmpty()]
		[string]$SnmpUserName,

		[Parameter (Mandatory = $false, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory = $false, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateSet ("AuthOnly","AuthAndPriv")]
		[ValidateNotNullOrEmpty()]
		[string]$SnmpAuthLevel = "AuthOnly",

		[Parameter (Mandatory = $false, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory = $false, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateSet ("SHA","MD5")]	
		[ValidateNotNullOrEmpty()]
		[string]$SnmpAuthProtocol = 'SHA',

		[Parameter (Mandatory = $false, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory = $false, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateNotNullOrEmpty()]
		[Object]$SnmpAuthPassword,

		[Parameter (Mandatory = $false, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory = $false, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateSet ("aes128","des56")]	
		[ValidateNotNullOrEmpty()]
		[string]$SnmpPrivProtocol,

		[Parameter (Mandatory = $false, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory = $false, ParameterSetName = "MonitoredSnmpV3")]
		[ValidateNotNullOrEmpty()]
		[Object]$SnmpPrivPassword,

		[Parameter (Mandatory = $False, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $False, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $False, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory = $False, ParameterSetName = "MonitoredSnmpV3")]
		[switch]$Async,
		
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "ManagedSnmpV3")]
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "MonitoredSnmpV3")]
		[Alias ('Appliance')]
		[ValidateNotNullOrEmpty()]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{
		
		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $LogicalSwitchGroup)
		{

			$PipelineInput = $true

		}

		else
		{

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

		}

		# Validate SNMPv3 Parameters that are required
		if ('ManagedSnmpV3','MonitoredSnmpV3' -contains $PSCmdlet.ParameterSetName)
		{

			if ($SnmpAuthLevel -eq "AuthOnly" -and 
			(-not $SnmpAuthProtocol -or 
			-not $SnmpAuthPassword)) 
			{

				# Generate Terminateing error
				$ErrorRecord = New-ErrorRecord HPOneView.LogicalSwitchResourceException MissingRequiredParameters InvalidArgument 'SnmpAuthLevel' -Message "The -SnmpAuthLevel Parameter was set to 'AuthOnly', but did not include both -SnmpAuthProtocol and -SnmpAuthPassword Parameters."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			}

			if ($SnmpAuthLevel -eq "AuthAndPriv" -and (
				-not $SnmpAuthProtocol -or 
				-not $SnmpAuthPassword -or 
				-not $SnmpPrivProtocol -or 
				-not $SnmpPrivPassword )) 
			{

				# Generate Terminateing error
				$ErrorRecord = New-ErrorRecord HPOneView.LogicalSwitchResourceException MissingRequiredParameters InvalidArgument 'SnmpAuthLevel' -Message "The -SnmpAuthLevel Parameter was set to 'AuthAndPriv', but did not include -SnmpAuthProtocol, -SnmpAuthPassword, -SnmpPrivProtocol and -SnmpPrivPassword Parameters."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

	}
	
	Process
	{

		# Create new LIgObject
		$_LogicalSwitch = NewObject -LogicalSwitch 
		$_LogicalSwitch.logicalSwitch.name = $Name
		$_LogicalSwitch.logicalSwitch.managementLevel = $LogicalSwitchManagementLevelEnum[$PSCmdlet.ParameterSetName]

		if ($SshPassword -is [SecureString])
		{

			$SshPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SshPassword))

		}

		if ($PSBoundParameters['SnmpAuthPassword'] -and $SnmpAuthPassword -is [SecureString])
		{

			$SnmpAuthPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SnmpAuthPassword))
			
		}

		if ($PSBoundParameters['SnmpPrivPassword'] -and $SnmpPrivPassword -is [SecureString])
		{

			$SnmpPrivPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SnmpPrivPassword))
			
		}

		# Validate Logic Switch
		if ($LogicalSwitchGroup -isnot [PSCustomObject])
		{

			# Generate Error
			"[{0}] Invalid LogicalSwitchGroup resource.  Generating Terminating Error" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_Message = 'The provided Logical Switch Group {0} is not a supported object type.  Expected [PSCustomObject], Received "{1}".' -f $LogicalSwitchGroup.name, $SwitchType.GetType().FullName

			$ErrorRecord = New-ErrorRecord HPOneView.SwitchTypeResourceException InvalidSwitchTypeResource InvalidArgument 'LogicalSwitchGroup' -TargetType $LogicalSwitchGroup.GetType().Name -Message $_Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($LogicalSwitchGroup.category -ne 'logical-switch-groups')
		{

			# Generate error
			"[{0}] Invalid LogicalSwitchGroup resource.  Generating Terminating Error" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_Message = 'The provided Logical Switch Group {0} is not a supported object category type.  Expected logical-switch-groups", Received "{1}".' -f $LogicalSwitchGroup.name, $LogicalSwitchGroup.category

			$ErrorRecord = New-ErrorRecord HPOneView.SwitchTypeResourceException InvalidSwitchTypeResource InvalidArgument 'LogicalSwitchGroup' -TargetType 'PSObject' -Message $_Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_LogicalSwitch.logicalSwitch.logicalSwitchGroupUri = $LogicalSwitchGroup.uri
		$NumberOfSwitches = $LogicalSwitchGroup.switchMapTemplate.switchMapEntryTemplates.count

		"[{0}] Processing number of switches from Switch Group: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $NumberOfSwitches | Write-Verbose

		# Add Switch Credentials to connection Object
		For ($i = 1; $i -le $NumberOfSwitches; $i++)
		{

			"[{0}] Processing switch: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $i | Write-Verbose

			# SNMP and Management Address
			$_SwitchCredentialConfig = NewObject -LogicalSwitchCredentials
			$_SwitchCredentialConfig.snmpPort = $SnmpPort

			if ($i -eq 1)
			{

				$_SwitchCredentialConfig.logicalSwitchManagementHost = $Switch1Address

			}
			
			elseif ($i -eq 2)
			{

				$_SwitchCredentialConfig.logicalSwitchManagementHost = $Switch2Address

			}

			if ($PSBoundParameters['SnmpV1'])
			{
				
				$_SwitchCredentialConfig.snmpV1Configuration.communityString = $SnmpCommunity

			}

			else
			{

				$_SwitchCredentialConfig.snmpVersion = 'SNMPv3'

			}

			[void]$_LogicalSwitch.logicalSwitch.switchCredentialConfiguration.Add($_SwitchCredentialConfig)

			# SSH
			$_LogialSwitchConnectionProperties = NewObject -LogialSwitchConnectionProperties

			# SSH User Account
			$_LogicalSwitchConnectionProperty              = NewObject -LogicalSwitchConnectionProperty
			$_LogicalSwitchConnectionProperty.propertyName = 'SshBasicAuthCredentialUser'
			$_LogicalSwitchConnectionProperty.value        = $SshUserName
			$_LogicalSwitchConnectionProperty.valueType    = 'String'

			[void]$_LogialSwitchConnectionProperties.connectionProperties.Add($_LogicalSwitchConnectionProperty)

			# SSH User Password
			$_LogicalSwitchConnectionProperty              = NewObject -LogicalSwitchConnectionProperty
			$_LogicalSwitchConnectionProperty.propertyName = 'SshBasicAuthCredentialPassword'
			$_LogicalSwitchConnectionProperty.value        = $SshPassword
			$_LogicalSwitchConnectionProperty.valueFormat  = 'SecuritySensitive'
			$_LogicalSwitchConnectionProperty.valueType    = 'String'

			[void]$_LogialSwitchConnectionProperties.connectionProperties.Add($_LogicalSwitchConnectionProperty)

			# Add
			[Void]$_LogicalSwitch.logicalSwitchCredentials.Add($_LogialSwitchConnectionProperties)			

		}
	
		# Handle Device SNMP Configuration
		if ('ManagedSnmpV3','MonitoredSnmpV3' -contains $PSCmdlet.ParameterSetName)
		{

			For ($i = 0; $i -lt $NumberOfSwitches; $i++)
			{

				"[{0}] Processing SNMPv3 Auth credentials" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Add SNMPv3 AuthOnly Protocol
				$_LogicalSwitch.logicalSwitch.switchCredentialConfiguration[$i].snmpV3Configuration.authorizationProtocol = $SnmpAuthProtocolEnum[$SnmpAuthProtocol]
				$_LogicalSwitch.logicalSwitch.switchCredentialConfiguration[$i].snmpV3Configuration.securityLevel = 'Auth'

				# Add SNMPv3 Credentials
				$_LogicalSwitchConnectionProperty              = NewObject -LogicalSwitchConnectionProperty
				$_LogicalSwitchConnectionProperty.propertyName = 'SnmpV3User'
				$_LogicalSwitchConnectionProperty.value        = $SnmpUserName
				$_LogicalSwitchConnectionProperty.valueType    = 'String'
				[void]$_LogicalSwitch.logicalSwitchCredentials[$i].connectionProperties.Add($_LogicalSwitchConnectionProperty)

				$_LogicalSwitchConnectionProperty              = NewObject -LogicalSwitchConnectionProperty
				$_LogicalSwitchConnectionProperty.propertyName = 'SnmpV3AuthorizationPassword'
				$_LogicalSwitchConnectionProperty.value        = $SnmpAuthPassword
				$_LogicalSwitchConnectionProperty.valueFormat  = 'SecuritySensitive'
				$_LogicalSwitchConnectionProperty.valueType    = 'String'
				[void]$_LogicalSwitch.logicalSwitchCredentials[$i].connectionProperties.Add($_LogicalSwitchConnectionProperty)

				# Add SNMPv3 Privacy settings if specified
				if ($SnmpAuthLevel -eq "AuthAndPriv") 
				{

					"[{0}] Processing SNMPv3 AuthAndPrivacy credentials" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_LogicalSwitch.logicalSwitch.switchCredentialConfiguration[$i].snmpV3Configuration.privacyProtocol = $SnmpPrivProtocolEnum[$SnmpPrivProtocol]
					$_LogicalSwitch.logicalSwitch.switchCredentialConfiguration[$i].snmpV3Configuration.securityLevel   = 'AuthPrivacy'

					$_LogicalSwitchConnectionProperty              = NewObject -LogicalSwitchConnectionProperty
					$_LogicalSwitchConnectionProperty.propertyName = 'SnmpV3PrivacyPassword'
					$_LogicalSwitchConnectionProperty.value        = $SnmpPrivPassword
					$_LogicalSwitchConnectionProperty.valueFormat  = 'SecuritySensitive'
					$_LogicalSwitchConnectionProperty.valueType    = 'String'
					[void]$_LogicalSwitch.logicalSwitchCredentials[$i].connectionProperties.Add($_LogicalSwitchConnectionProperty)

				}

			}

		}

		"[{0}] LS: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), (ConvertTo-Json -Depth 99 $_LogicalSwitch | out-string) | Write-Verbose 

		"{0}] Sending request to create '{1}'..." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_LogicalSwitch.name | Write-Verbose 
	
		Try
		{
		
			$_Task = Send-HPOVRequest -Uri $LogicalSwitchesUri -Method POST -Body $_LogicalSwitch -Hostname $ApplianceConnection
		
		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not $Async.IsPresent)
		{

			Try
			{

				$_Task = Wait-HPOVTaskComplete -InputObject $_Task

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		$_Task

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
