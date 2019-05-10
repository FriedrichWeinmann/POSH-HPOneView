function New-HPOVServerProfileTemplate 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[Parameter (Mandatory, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")] 
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[string]$Description,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")] 
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[string]$ServerProfileDescription,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Boolean]$ManageConnections = $true,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[array]$Connections = @(),

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[Alias ('eg')]
		[object]$EnclosureGroup,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[Parameter (Mandatory, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[Alias ('sht')]
		[object]$ServerHardwareType,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[switch]$Firmware,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Alias ('FirmwareMode')]
		[ValidateSet ('FirmwareOnly', 'FirmwareAndSoftware', 'FirmwareOffline', 'FirmwareAndOSDrivers', 'FirmwareOnly', 'FirmwareOnlyOfflineMode')]
		[string]$FirmwareInstallMode = 'FirmwareAndSoftware',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ('Immediate', 'Scheduled', 'NotScheduled')]
		[string]$FirmwareActivationMode = 'Immediate',
	
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[object]$Baseline,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[switch]$ForceInstallFirmware,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.OSDeploymentPlan]$OSDeploymentPlan,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[HPOneView.ServerProfile.OSDeployment.OSDeploymentParameter[]]$OSDeploymentPlanAttributes,
	
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[switch]$Bios,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[array]$BiosSettings=@(),
		
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]        
		[ValidateSet ("UEFI", "UEFIOptimized", "BIOS", 'Unmanaged', IgnoreCase = $False)]
		[string]$BootMode = "BIOS",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]        
		[ValidateSet ("Auto", "IPv4", "IPv6", "IPv4ThenIPv6", "IPv6ThenIPv4", IgnoreCase = $False)]
		[string]$PxeBootPolicy = "Auto",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Alias ('boot')]
		[bool]$ManageBoot = $true,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[array]$BootOrder,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ("Unmanaged", "Enabled", "Disabled", IgnoreCase = $False)]
		[String]$SecureBoot = 'Unmanaged',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[switch]$LocalStorage,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Alias('LogicalDisk')]
		[ValidateNotNullorEmpty()]
		[Object]$StorageController,

		[Parameter (Mandatory, ParameterSetName = "SANStorageAttach")]
		[switch]$SANStorage,

		[Parameter (Mandatory, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ('CitrixXen','CitrixXen7','AIX','IBMVIO','RHEL4','RHEL3','RHEL','RHEV','RHEV7','VMware','Win2k3','Win2k8','Win2k12','Win2k16','OpenVMS','Egenera','Exanet','Solaris9','Solaris10','Solaris11','ONTAP','OEL','HPUX11iv1','HPUX11iv2','HPUX11iv3','SUSE','SUSE9','Inform', IgnoreCase = $true)]
		[Alias ('OS')]
		[string]$HostOStype,

		[Parameter (Mandatory, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[object]$StorageVolume,

		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Alias ('Even')]
		[switch]$EvenPathDisabled,

		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Alias ('Odd')]
		[switch]$OddPathDisabled,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ("Bay","BayAndServer", IgnoreCase=$false)]
		[string]$Affinity = "Bay",
	
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ("Virtual", "Physical", "UserDefined", IgnoreCase = $true)]
		[string]$MacAssignment = "Virtual",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ("Virtual", "Physical", "'UserDefined", IgnoreCase = $true)]
		[string]$WwnAssignment = "Virtual",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ("Virtual", "Physical", "UserDefined", IgnoreCase = $true)]
		[string]$SnAssignment = "Virtual",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ("Virtual", "UserDefined", IgnoreCase = $true)]
		[string]$IscsiInitiatorNameAssignmet = "Virtual",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[bool]$HideUnusedFlexNics = $True,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Switch]$PassThru,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
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

		# Check for URI values in Parameters and validate that only one appliance connection is provided in the call
		if($ApplianceConnection.Count -gt 1)
		{
			
			# SHT
			if($serverHardwareType -is [string] -and $serverHardwareType.StartsWith($script:serverHardwareTypesUri))
			{
				
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerHardwareTypeObject InvalidArgument 'New-HPOVPropfile' -Message "Server Hardware Type as URI is not supported for multiple appliance connections"
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}
			
			if($serverHardwareType -is [string] -and $serverHardwareType.StartsWith("/rest"))
			{
			
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerHardwareTypeObject InvalidArgument 'New-HPOVPropfile' -Message "Server Hardware Type as URI is not supported for multiple appliance connections."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

			# EG
			if(($enclosureGroup -is [string] -and $enclosureGroup.StartsWith("/rest")))
			{
			
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerHardwareTypeObject InvalidArgument 'New-HPOVPropfile' -Message "Enclosure Group as URI is not supported for multiple appliance connections."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

			#Baseline
			if (($baseline -is [string]) -and ($baseline.StartsWith('/rest'))) 
			{
				
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerHardwareTypeObject InvalidArgument 'New-HPOVPropfile' -Message "Baseline as URI is not supported for multiple appliance connections."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

		}

		ForEach ($_key in $PSBoundParameters.keys.GetEnumerator())
		{

			if ('ImportLogicalDisk','Initialize','ControllerMode','Bootable','RaidLevel' -contains $_key)
			{

				Write-Warning ("The -{0} parameter is deprecated.  To configure local storage, please use the New-HPOVServerProfileLogicalDisk and New-HPOVServerProfileLogicalDiskController Cmdlets." -f $_key)

			}

		}

		$uri = $ServerProfileTemplatesUri

		$colStatus = New-Object System.Collections.ArrayList

	}
	
	Process 
	{
		
		# New Server Resource Object
		$_spt = NewObject -ServerProfileTemplate
			
		$_spt.name                          = $Name
		$_spt.description                   = $Description
		$_spt.serverProfileDescription      = $ServerProfileDescription		
		$_spt.affinity                      = $Affinity

		if (-not $ManageBoot -and ($PSBoundParameters['BootMode'] -or $PSBoundParameters['BootOrder'] -or $PSBoundParameters['PxeBootPolicy']))
		{

			$ExceptionMessage = "Attempting to set Boot Mode or Boot Order and not enabling ManageBoot is not supported.  Either remove the -BootOrder,-PxeBootPolicy and/or -BootMode parameters, or add -ManageBoot switch parameter."
			$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileTemplateResourceException InvalidManageBootModeState InvalidArgument 'ManageBoot' -TargetType 'Boolean' -Message	$ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}
							
		# Check to see if the serverHardwareType or enclosureGroup is null, and generate error(s) then break.
		if (-not($ServerHardwareType))
		{

			$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerHardwareTypeObject InvalidArgument 'ServerHardwareType' -Message "Server Hardware Type is missing.  Please provide a Server Hardware Type using the -sht Parameter and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}
		
		# If the URI is passed as the Server Hardware Type, then set the serverHardwareTypeUri variable
		If ($ServerHardwareType -is [string])
		{

			if ($ServerHardwareType.StartsWith($script:ServerHardwareTypesUri))
			{ 
						
				"[{0}] SHT URI Provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerHardwareType | Write-Verbose

				$_spt.serverHardwareTypeUri = $ServerHardwareType

				Try
				{
						
					$ServerHardwareType = Send-HPOVRequest -Uri $ServerHardwareType -Hostname $ApplianceConnection
						
				}
						
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}
				
			# Otherwise, perform a lookup ofthe SHT based on the name
			else 
			{

				"[{0}] SHT Name Provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerHardwareType | Write-Verbose

				Try
				{

					$ServerHardwareType = Get-HPOVServerHardwareType -Name $ServerHardwareType -Appliance $ApplianceConnection -ErrorAction Stop

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				"[{0}] SHT URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerHardwareType.uri | Write-Verbose
				
				$_spt.serverHardwareTypeUri = $ServerHardwareType.uri

			}

		}
		
		# Else the SHT object is passed
		else 
		{ 

			"[{0}] ServerHardwareType object provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			"[{0}] ServerHardwareType Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerHardwareType.name | Write-Verbose
			"[{0}] ServerHardwareType Uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerHardwareType.uri | Write-Verbose

			$_spt.serverHardwareTypeUri = $serverHardwareType.uri
					
		}

		if ($ServerHardwareType.model -notmatch "DL")
		{

			$_spt.hideUnusedFlexNics = $PSBoundParameters['HideUnusedFlexNics']
			$_spt.serialNumberType   = $SnAssignment 
			$_spt.macType            = $MacAssignment
			$_spt.wwnType            = $WwnAssignment

			if ($PSBoundParameters['IscsiInitiatorNameAssignmet'])
			{

				$_spt.iscsiInitiatorNameType = $IscsiInitiatorNameAssignmetEnum[$IscsiInitiatorNameAssignmet]

			}
			

			if (-not($EnclosureGroup))
			{
				
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidEnclosureGroupObject InvalidArgument 'EnclosureGroup' -Message "Enclosure Group is missing.  Please provide an Enclosure Group using the -eg Parameter and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			elseif ($EnclosureGroup -is [string])
			{

				# If the URI is passed as the Enclosure Group, then set the enclosureGroupUri variable
				if ($EnclosureGroup.StartsWith('/rest'))
				{ 
				
					$_spt.enclosureGroupUri = $EnclosureGroup
			
				}

				# Otherwise, perform a lookup ofthe Enclosure Group
				else
				{

					Try
					{

						$EnclosureGroup = Get-HPOVEnclosureGroup -name $EnclosureGroup -appliance $ApplianceConnection

					}
				
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					"[{0}] EG URI: $enclosureGroupUri" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose					    
				
					$_spt.enclosureGroupUri = $EnclosureGroup.uri
				
				}

			}
				
			# Else the EG object is passed
			elseif (($EnclosureGroup -is [PSObject]) -and ($EnclosureGroup.category -eq "enclosure-groups")) 
			{ 

				# Retrieve only EG from this appliance connection
				"[{0}] Enclosure Group object provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] Enclosure Group Name: $($EnclosureGroup.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] Enclosure Group Uri: $($EnclosureGroup.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Retrieve only EG from this appliance connection
				$_spt.enclosureGroupUri = $EnclosureGroup.uri

			}

			else 
			{ 

				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidEnclosureGroupObject InvalidArgument 'EnclsoureGroup' -TargetType $EnclosureGroup.GetType().Name -Message "Enclosure Group is invalid.  Please specify a correct Enclosure Group name, URI or object and try again."

				# Generate Terminating Error
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

		}            

		# Handle DL Server Profiles by setting BL-specific properties to NULL
		else
		{

			"[{0}]] Server Hardware Type is a DL, setting 'macType', 'wwnType', 'serialNumberType', 'affinity' and 'hideUnusedFlexNics' to supported values." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_spt.macType            = 'Physical'
			$_spt.wwnType            = 'Physical'
			$_spt.serialNumberType   = 'Physical'
			$_spt.hideUnusedFlexNics = $true
			$_spt.affinity           = $Null

		}

		# Handle Boot Order and BootManagement
		switch ($ServerHardwareType.model)
		{
				
			{$_ -match 'Gen7|Gen8'}
			{

				# User provided UEFI or UEFIOptimized for a non-Gen9 platform.
				if ('Unmanaged','BIOS' -notcontains $BootMode)
				{

					$ExceptionMessage = "The -BootMode Parameter was provided and the Server Hardware model '{0}' does not support this Parameter.  Please verify the Server Hardware Type is at least an HPE ProLiant Gen9." -f $ServerHardwareType.model
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException BootModeNotSupported InvalidArgument 'BootMode' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)    

				}

				if (-not($PSboundParameters['BootOrder']) -and $ManageBoot)
				{

					"[{0}] No boot order provided for Gen8 Server resource type.  Defaulting to 'CD','Floppy','USB','HardDisk','PXE'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					[System.Collections.ArrayList]$_spt.boot.order = ('CD','Floppy','USB','HardDisk','PXE')

				}

			}

			{$_ -match 'Gen9|Gen10'}
			{

				"[{0}] Gen 9/10 Server, setting BootMode to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $BootMode | Write-Verbose 

				if ($ManageBoot)
				{

					$_spt.bootMode = NewObject -ServerProfileBootMode

					switch ($BootMode) 
					{

						'Unmanaged'
						{

							$_spt.bootMode.manageMode = $false						

						}

						"BIOS" 
						{

							$_spt.bootMode = NewObject -ServerProfileBootModeLegacyBios

							$_spt.bootMode.manageMode = $true;
							$_spt.bootMode.mode       = $BootMode;						
							
						}

						{ "UEFI","UEFIOptimized" -match $_ } 
						{
							
							$_spt.bootMode.manageMode    = $true;
							$_spt.bootMode.mode          = $BootMode;
							$_spt.bootMode.pxeBootPolicy = $PxeBootPolicy
							
							if ($ServerHardwareType.model -match 'DL|XL|ML')
							{

								$_spt.boot.manageBoot = $false

							}

							if ($ServerHardwareType.model -match "Gen9" -and -not $PSBoundParameters['SecureBoot'])
							{

								$_spt.bootMode.secureBoot = 'Unmanaged'

							}
							
						}

					}

					"[{0}] Processing Gen 9 Server BootOrder settings." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

					if ($_spt.boot.manageBoot -and ($BootOrder -contains "Floppy") -and ($BootMode -match "UEFI"))
					{
							
						$ExceptionMessage = "The -BootOrder Parameter contains 'Floppy' which is an invalid boot option for a UEFI-based system."
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidUEFIBootOrderParameterValue InvalidArgument 'BootOrder' -TargetType 'Array' -Message	$ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					elseif ((-not ($PSBoundParameters["BootOrder"])) -and $_spt.boot.manageBoot -and $BootMode -eq "BIOS") 
					{

						"[{0}] No boot order provided for Gen9 Server resource type.  Defaulting to 'CD','USB','HardDisk','PXE'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						[System.Collections.ArrayList]$_spt.boot.order = @('CD','USB','HardDisk','PXE')
				
					}

					elseif ((-not ($PSBoundParameters["BootOrder"])) -and $_spt.boot.manageBoot -and $BootMode -match 'UEFI' -and $ServerHardwareType.model -notmatch 'DL')
					{

						"[{0}] No boot order provided for BL Gen9 Server resource type.  Defaulting to 'HardDisk'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						[System.Collections.ArrayList]$_spt.boot.order = @('HardDisk')
				
					}

					elseif (($BootOrder.count -gt 1) -and $_spt.boot.manageBoot -and $BootMode -match 'UEFI')
					{

						$ExceptionMessage = "The -BootOrder Parameter contains more than 1 entry, and the system BootMode is set to {0}, which is invalud for a UEFI-based system.  Please check the -BootOrder Parameter and make sure either 'HardDisk' or 'PXE' are the only option." -f $BootMode
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidUEFIBootOrderParameterValue InvalidArgument 'BootOrder' -TargetType 'Array' -Message	$ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
					}

					elseif ($BootOrder -and $_spt.boot.manageBoot -and $BootMode -match 'UEFI' -and $ServerHardwareType.model -notmatch 'DL')
					{

						"[{0}] Adding provided BootOrder {1} to Server Profile object." -f $MyInvocation.InvocationName.ToString().ToUpper(), [String]::Join(', ', $BootOrder) | Write-Verbose 

						[System.Collections.ArrayList]$_spt.boot.order = $BootOrder

					}

				}

				else
				{

					$_spt.boot.manageBoot = $false
					$_spt.boot.order = $null

				}
				
			}

		}

		if ($PSBoundParameters['OSDeploymentPlan'])
		{

			If ($ApplianceConnection.ApplianceType -ne 'Composer')
			{

				$ExceptionMessage = 'The ApplianceConnection {0} is not a Synergy Composer.  OS Deployment Plans are only supported with HPE Synergy.' -f $ApplianceConnection.Name
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			"[{0}] Setting OS Deployment Plan." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_spt | Add-Member -NotePropertyName osDeploymentSettings -NotePropertyValue (NewObject -SPTOSDeploymentSettings)
			
			"[{0}] Setting OS Deployment Plan URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $OSDeploymentPlan.uri | Write-Verbose
			$_spt.osDeploymentSettings.osDeploymentPlanUri = $OSDeploymentPlan.uri

			"[{0}] Number of OS Deployment Plan Custom Attributes to set: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $OSDeploymentPlanAttributes.Count | Write-Verbose
			"[{0}] Setting OS Deployment Plan Custom Attributes: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($OSDeploymentPlanAttributes | Out-String) | Write-Verbose
			$_spt.osDeploymentSettings.osCustomAttributes  = $OSDeploymentPlanAttributes

		}

		# Exmamine the profile connections Parameter and pull only those connections for this appliance connection
		If ($PSBoundParameters['Connections'] -and $ManageConnections -and $ServerHardwareType.capabilities -contains "VCConnections")
		{

			"[{0}] Getting available Network resources based on SHT and EG." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Get avaialble Networks based on the EG and SHT
			$_AvailableNetworksUri = $ServerProfilesAvailableNetworksUri + '?serverHardwareTypeUri={0}&enclosureGroupUri={1}' -f $ServerHardwareType.uri,$EnclosureGroup.uri

			Try
			{

				$_AvailableNetworkResources = Send-HPOVRequest -Uri $_AvailableNetworksUri -Hostname $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_c = 0

			$BootableConnections = New-Object System.Collections.ArrayList

			ForEach ($c in $Connections)
			{

				$Message = $null

				# Remove connection Parameters not permitted in Template
				$c = $c | Select-Object -property * -ExcludeProperty macType, wwnType, wwpnType, mac, wwnn, wwpn, ApplianceConnection
				$c.boot = $c.boot | Select-Object -property * -ExcludeProperty bootTargetName, bootTargetLun, initiatorName, initiatorIp, chapName, mutualChapName, chapSecret, mutualChapSecret

				switch (($c.networkUri.Split('\/'))[2])
				{

					'ethernet-networks'
					{
					
						if (-not($_AvailableNetworkResources.ethernetNetworks | Where-Object uri -eq $c.networkUri))
						{

							$Message = "The Ethernet network {0} specified in Connection {1} was not found to be provisioned to the provided Enclosure Group, {2}, and SHT, {3}.  Please verify that the network is a member of an Uplink Set in the associated Logical Interconnect Group." -f (Send-HPOVRequest $c.networkUri -Hostname $ApplianceConnection).name, $c.id, $EnclosureGroup.name, $ServerHardwareType.name

						}

						else
						{

							"[{0}] {1} is available for Connection {2} in this SPT." -f $MyInvocation.InvocationName.ToString().ToUpper(), $c.networkUri, $c.id | Write-Verbose 

						}
					
					}

					'network-sets'
					{
					
						if (-not($_AvailableNetworkResources.networkSets | Where-Object uri -eq $c.networkUri))
						{

							$Message = "The network set {0} specified in Connection {1} was not found to be provisioned to the provided Enclosure Group, {2}, and SHT, {3}.  Please verify that the network is a member of an Uplink Set in the associated Logical Interconnect Group." -f (Send-HPOVRequest $c.networkUri -Hostname $ApplianceConnection).name, $c.id, $EnclosureGroup.name, $ServerHardwareType.name

						}
					
						else
						{

							"[{0}] {1} is available for Connection {2} in this SPT." -f $MyInvocation.InvocationName.ToString().ToUpper(), $c.networkUri, $c.id | Write-Verbose 

						}

					}

					{'fc-networks','fcoe-networks' -contains $_}
					{
					
						if (-not($_AvailableNetworkResources.fcNetworks | Where-Object uri -eq $c.networkUri))
						{

							$Message = "The FC/FCoE network {0} specified in Connection {1} was not found to be provisioned to the provided Enclosure Group, {2}, and SHT, {3}.  Please verify that the network is a member of an Uplink Set in the associated Logical Interconnect Group." -f (Send-HPOVRequest $c.networkUri -Hostname $ApplianceConnection).name, $c.id, $EnclosureGroup.name, $ServerHardwareType.name

						}
					
						else
						{

							"[{0}] {1} is available for Connection {2} in this SPT." -f $MyInvocation.InvocationName.ToString().ToUpper(), $c.networkUri, $c.id | Write-Verbose 

						}

					}

				}

				if ($Message)
				{

					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException NetworkResourceNotProvisioned InvalidArgument 'Connections' -TargetType 'PSObject' -Message $Message
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

				}

				if ($null -ne $c.boot -and $c.boot.priority -ne "NotBootable") 
				{

					"[{0}] Found bootable connection ID: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $c.id | Write-Verbose

					[void]$BootableConnections.Add($c.id)

				}
				
				[void]$_spt.connectionSettings.connections.Add($c)

				$_c++
			
			}
		
			"[{0}] Server Profile Template Connections to add: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_spt.connectionSettings.connections | Format-List * -force | Out-String) | Write-Verbose 

			if (-not $PSBoundParameters['ManageBoot'] -and $BootableConnections.count -gt 0) 
			{

				$ExceptionMessage = "Bootable Connections {0} were found, however the -ManageBoot switch Parameter was not provided.  Please correct your command syntax and try again." -f [String]::Join(', ', $BootableConnections.ToArray())
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException BootableConnectionsFound InvalidArgument 'manageBoot' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

			} 

		}

		else
		{

			"[{0}] Setting SPT to not track Connections with derived Server Profiles: {1}." -f $MyInvocation.InvocationName.ToString().ToUpper(), (-not [Bool]$ManageConnections.IsPresent) | Write-Verbose

			$_spt.connectionSettings.manageConnections = $ManageConnections.IsPresent

		}

		# Check to make sure Server Hardware Type supports Firmware Management (OneView supported G7 blade would not support this feature)
		if ($PSBoundParameters['Firmware'])
		{

			"[{0}] Firmware Baseline: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline | Write-Verbose

			if ($serverHardwareType.capabilities -contains "FirmwareUpdate" ) 
			{

				"[{0}] SHT is capable of firmware management" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				$_spt.firmware.manageFirmware         = [bool]$firmware
				$_spt.firmware.forceInstallFirmware   = [bool]$forceInstallFirmware
				$_spt.firmware.firmwareInstallType    = $ServerProfileFirmwareControlModeEnum[$FirmwareInstallMode]
				$_spt.firmware.firmwareActivationType = $ServerProfileFirmareActivationModeEnum[$FirmwareActivationMode]

				if ('FirmwareOffline', 'FirmwareOnlyOfflineMode' -contains $_spt.firmware.firmwareInstallType -and $FirmwareActivationMode -eq 'Scheduled')
				{

					$ExceptionMessage = "The specifying a scheduled firmware installation and performing offline method is not supported.  Please choose an online method."
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileTemplateResourceException InvalidFirmwareInstallMode InvalidArgument 'FirmwareActivateDateTime' -TargetType 'Switch' -Message	$ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
				}

				# Validating that the baseline value is a string type and that it is an SPP name.
				if (($baseline -is [string]) -and (-not ($baseline.StartsWith('/rest'))) -and ($baseline -match ".iso")) 
				{
					
					try 
					{
						
						$FirmwareBaslineName = $Baseline.Clone()

						$Baseline = Get-HPOVBaseline -FileName $Baseline -ApplianceConnection $ApplianceConnection -ErrorAction SilentlyContinue

						If (-not $_BaseLinePolicy)
						{

							$ExceptionMessage = "The provided Baseline '{0}' was not found." -f $FirmwareBaslineName
							$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'Baseline' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}
						
						$_spt.firmware.firmwareBaselineUri = $Baseline.uri
					
					}

					catch 
					{
						
						"[{0}] Error caught when looking for Firmware Baseline." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$PSCmdlet.ThrowTerminatingError($_)
					
					}
				
				}

				# Validating that the baseline value is a string type and that it is an SPP name.
				elseif (($baseline -is [string]) -and (-not ($baseline.StartsWith('/rest')))) 
				{

					try 
					{

						$FirmwareBaslineName = $Baseline.Clone()

						$Baseline = Get-HPOVBaseline -SppName $Baseline -ApplianceConnection $ApplianceConnection -ErrorAction SilentlyContinue

						If (-not $_BaseLinePolicy)
						{

							$ExceptionMessage = "The provided Baseline '{0}' was not found." -f $FirmwareBaslineName
							$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'Baseline' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						$_spt.firmware.firmwareBaselineUri = $baseline.uri

					}

					catch 
					{

						"[{0}] Error caught when looking for Firmware Baseline." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}
		
				# Validating that the baseline value is a string type and that it is the Baseline URI
				elseif (($Baseline -is [string]) -and ($Baseline.StartsWith('/rest'))) 
				{
			
					Try
					{

						$baselineObj = Send-HPOVRequest -Uri $Baseline -Hostname $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}		                

					if ($baselineObj.category -eq "firmware-drivers") 
					{
					
						"[{0}] Valid Firmware Baseline provided: $($baselineObj.baselineShortName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						$_spt.firmware.firmwareBaselineUri = $baselineObj.uri 
					
					}

					else 
					{

						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidBaselineResource ObjectNotFound 'Baseline' -Message "The provided SPP Baseline URI '$($baseline)' is not valid or the correct resource category (expected 'firmware-drivers', received '$($baselineObj.category)'.  Please check the -baseline Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				# Else we are expecting the SPP object that contains the URI.
				elseif (($Baseline) -and ($Baseline -is [object])) 
				{

					$_spt.firmware.firmwareBaselineUri = $Baseline.uri
				
				}

				elseif (!$baseline)
				{

					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerHardwareMgmtFeatureNotSupported NotImplemented 'New-HPOVServerProfileTemplate' -Message "Baseline is required if manage firmware is set to true."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
				}
				
			}

			else 
			{

				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerHardwareMgmtFeatureNotSupported NotImplemented 'Firmware' -Message "`"$($serverHardwareType.name)`" Server Hardware Type does not support Firmware Management."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
			}

		}
		
		# Check to make sure Server Hardware Type supports Bios Management (OneView supported G7 blade do not support this feature)
		if ($PSBoundParameters['Bios']) 
		{

			if ($serverHardwareType.capabilities -match "ManageBIOS" ) 
			{
					
				if ($BiosSettings.GetEnumerator().Cout -gt 0)
				{

						# Check for any duplicate keys
						$biosFlag = $false
						$hash = @{}
						$BiosSettings.id | ForEach-Object { $hash[$_] = $hash[$_] + 1 }

						foreach ($biosItem in ($hash.GetEnumerator() | Where-Object {$_.value -gt 1} | ForEach-Object {$_.key} )) 
						{
								
							$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException BiosSettingsNotUnique InvalidOperation 'BiosSettings' -TargetType 'Array' -Message "'$(($serverHardwareType.biosSettings | where { $_.id -eq $biosItem }).name)' is being set more than once. Please check your BIOS Settings are unique.  This setting might be a depEndency of another BIOS setting/option."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}
					
					$_spt.bios.manageBios = $True
					$_spt.bios.overriddenSettings = $BiosSettings

				}

				else 
				{ 

					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerHardwareMgmtFeatureNotSupported NotImplemented 'New-HPOVServerProfile' -Message "`"$($serverHardwareType.name)`" Server Hardware Type does not support BIOS Management."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)                
				
				}

		}

		# Manage Secure Boot settings
		if ($PSBoundParameters['SecureBoot'])
		{

			# Check to make sure Server Hardware supports SecureBoot
			if ($ServerHardwareType.capabilities.Contains('SecureBoot') -and $BootMode -eq 'UEFIOptimized')
			{

				$_spt.bootMode.secureBoot = $SecureBoot

			}

			# Generate exception if not
			elseif ($ServerHardwareType.capabilities.Contains('SecureBoot') -and $BootMode -ne 'UEFIOptimized')
			{

				$ExceptionMessage = 'The Server Hardware Type "{0}" supports managing SecureBoot, but BootMode was not set to "UEFIOptimized".' -f $ServerHardwareType.name
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidBootModeManageValue InvalidArgument 'BootMode' -TargetType 'Bool' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			elseif (-not $ServerHardwareType.capabilities.Contains('SecureBoot') -and $BootMode -eq 'UEFIOptimized')
			{

				$ExceptionMessage = 'The Server Hardware Type "{0}" does not support managing SecureBoot.' -f $ServerHardwareType.name
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidSecureBootManageValue InvalidArgument 'SecureBoot' -TargetType 'Bool' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		# Set Local Storage Management and Check to make sure Server Hardware Type supports it (OneView supported G7 blade would not support this feature)
		if (($PSBoundParameters['StorageController']) -and ($ServerHardwareType.capabilities.Contains("ManageLocalStorage"))) 
		{

			# Loop through Controllers provided by user, which should have LogicalDisks attached.
			ForEach ($_Controller in $StorageController)
			{

				# Copy the object so PowerShell doesn't modify the original object from the caller
				$__controller = $_Controller.PSObject.Copy()

				"[{0}] Processing {1} Controller" -f $MyInvocation.InvocationName.ToString().ToUpper(), $__controller.slotNumber | Write-Verbose
				
				# Check if controll has imporrtConfiguration set to True, which is unsupported with SPT
				if ($__controller.importConfiguration)
				{

					$Message = "The StorageController configuration contains the -ImportExistingConfiguration option set, which is not supported with Server Profile Templates."
					$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedImportConfigurationSetting InvalidOperation "StorageController" -TargetType 'PSObject' -Message $Message
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)						

				}

				"[{0}] SHT supports Controller RAID mode: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($__controller.mode -eq 'RAID' -and ('Mixed','RAID' -notcontains $ServerHardwareType.storageCapabilities.controllerModes)) | Write-Verbose

				# Validate the SHT.storageCapabilities controllerModes -> mode, raidLevels -> logicalDrives.raidLevel and maximumDrives -> numPhysicalDrives
				if ($__controller.mode -eq 'RAID' -and ($ServerHardwareType.storageCapabilities.controllerModes -notcontains 'Mixed' -and $ServerHardwareType.storageCapabilities.controllerModes -notcontains 'RAID'))
				{
					
					$_ExceptionMessage = "Unsupported LogicalDisk policy with Virtual Machine Appliance.  The requested Controller Mode '{0}' is not supported with the expected Server Hardware Type, which only supports '{1}'" -f $__controller.mode, ([System.String]::Join("', '", $ServerHardwareType.storageCapabilities.controllerModes)) 
					$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedImportConfigurationSetting InvalidOperation "StorageController" -TargetType 'PSObject' -Message $_ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# Controller mode needs to be set to Mixed
				elseif ($__controller.mode -eq 'RAID' -and 'Mixed' -eq $ServerHardwareType.storageCapabilities.controllerModes)
				{

					$__controller.mode = 'Mixed'

				}

				$_l = 1

				"[{0}] Storage Controller has {1} LogicalDrives to Process" -f $MyInvocation.InvocationName.ToString().ToUpper(), $__controller.logicalDrives.count | Write-Verbose

				"[{0}] Server Hardware supports '{1}' drives." -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerHardwareType.storageCapabilities.maximumDrives | Write-Verbose

				$_NewLogicalDisksCollection = New-Object System.Collections.ArrayList

				# Validate the SHT.storageCapabilities .raidLevels -> logicalDrives.raidLevel and .maximumDrives -> numPhysicalDrives
				ForEach ($_ld in $__controller.logicalDrives)
				{

					"[{0}] Processing {1} of {2} LogicalDisk: {3}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_l, $__controller.logicalDrives.count, $_ld.name | Write-Verbose

					"[{0}] {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ld | Out-String) | Write-Verbose

					if ($_ld.PSObject.Properties.Match('SasLogicalJBOD').Count)
					{

						"[{0}] Processing SasLogicalJbod {1} (ID:{2}) in Controller {3}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ld.SasLogicalJBOD.name, $_ld.SasLogicalJbodId, $__controller.deviceSlot | Write-Verbose

						If ($ApplianceConnection.ApplianceType -ne 'Composer')
						{

							$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message ('The ApplianceConnection {0} is not a Synergy Composer.  The LogicalDisk within the StorageController contains a SasLogicalJbod configuration with is only supported with HPE Synergy.' -f $ApplianceConnection.Name)
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						[void]$_spt.localStorage.sasLogicalJBODs.Add($_ld.SasLogicalJBOD)

						# Needed for D3940 RAID drive attachment
						if (-not [String]::IsNullOrEmpty($_ld.raidLevel))
						{

							$_ld = $_ld | Select-Object * -ExcludeProperty SasLogicalJBOD

							[Void]$_NewLogicalDisksCollection.Add($_ld)

						}

					}

					else
					{

					if ($ServerHardwareType.storageCapabilities.raidLevels -notcontains $_ld.raidLevel)
					{

						$_ExceptionMessage = "Unsupported LogicalDisk RAID Level '{0}' policy with '{1}' logical disk.  The Server Hardware Type only supports '{2}' RAID level(s). " -f $_ld.raidLevel, $_ld.name, [System.String]::Join("', '", $ServerHardwareType.storageCapabilities.raidLevels) 
						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedLogicalDriveRaidLevel InvalidOperation "StorageController" -TargetType 'PSObject' -Message $_ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if ($_ld.numPhysicalDrives -gt $ServerHardwareType.storageCapabilities.maximumDrives)
					{

						$_ExceptionMessage = "Invalid number of drives requested '{0}'.  The Server Hardware Type only supports a maximum of '{1}'." -f $_ld.numPhysicalDrives, $ServerHardwareType.storageCapabilities.maximumDrives 
						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedNumberofDrives InvalidOperation "StorageController" -TargetType 'PSObject' -Message $_ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					$_ld = $_ld | Select-Object * -ExcludeProperty SasLogicalJBOD

					[Void]$_NewLogicalDisksCollection.Add($_ld)

					}
					
					$_l++

				}

				$__controller.logicalDrives = $_NewLogicalDisksCollection

				$__controller = $__controller | Select-Object * -Exclude importConfiguration

				[void]$_spt.localStorage.controllers.Add($__controller)	
			
			}
														
		}

		# StRM Support
		if ($PSBoundParameters['SANStorage'] -and $ServerHardwareType.capabilities -Contains 'VCConnections')
		{ 

			"[{0}] SAN Storage being requested" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_spt.sanStorage = [pscustomobject]@{
				
				hostOSType        = $ServerProfileSanManageOSType[$HostOsType];
				manageSanStorage  = [bool]$SANStorage;
				volumeAttachments = New-Object System.Collections.ArrayList
			
			}

			$_AllNetworkUrisCollection  = New-Object System.Collections.ArrayList

			#Build list of network URI's from connections
			ForEach ($_Connection in ($_spt.connectionSettings.connections | Where-Object { -not $_.networkUri.StartsWith($NetworkSetsUri)})) 
			{

				[void]$_AllNetworkUrisCollection.Add($_Connection.networkUri)

			}

			# Copy the Parameter array into a new object
			$_VolumesToAttach = New-Object System.Collections.ArrayList

			$StorageVolume | ForEach-Object { 

				if ($_)
				{
				
					[void]$_VolumesToAttach.Add($_)

				}
				
			}
			
			"[{0}] Number of Volumes to Attach: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_VolumesToAttach.Count | Write-Verbose

			$_v = 0
			
			foreach ($_Volume in $_VolumesToAttach) 
			{  

				$_v++

				"[{0}] Processing Volume {1} of {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_v, $_VolumesToAttach.Count | Write-Verbose

				# Ephemeral Volume Support
				if ($null -eq $_Volume.volumeUri -and $_Volume.volume.properties.storagePool)
				{

					$_uri        = "{0}?networks='{1}'&filter=uri='{2}'" -f $ReachableStoragePoolsUri, ([String]::Join(',', $_AllNetworkUrisCollection.ToArray())), $_Volume.volume.properties.storagePool
					$_VolumeName = $_Volume.volume.properties.name
					$_VolumeUri  = 'StoragePoolUri:{0}' -f $_Volume.volumeStoragePoolUri

				}

				# Provisioned Volume Support
				else
				{

					Try
					{

						$_VolumeName = (Send-HPOVRequest -uri $_Volume.volumeUri).Name

					}

					catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$_uri = "{0}?networks='{1}'&filter=name='{2}'" -f $AttachableStorageVolumesUri, ([String]::Join(',', $_AllNetworkUrisCollection.ToArray())), $_VolumeName
					$_VolumeUri = $_Volume.uri										

				}

				"[{0}] Processing Volume ID: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Volume.id | Write-Verbose 
				"[{0}] Looking to see if volume '{1} ({2})' is attachable" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_VolumeName, $_VolumeUri |Write-Verbose 

				try
				{

					$_resp = Send-HPOVRequest -Uri $_uri -appliance $ApplianceConnection

				}

				catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				# Members found
				if ($_resp.count -gt 0)
				{

					"[{0}] '{1} ({2})' volume is attachable" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_VolumeName, $_VolumeUri | Write-Verbose

					if (($_Volume.id -eq 0) -or (-not($_Volume.id)))
					{

						"[{0}] No VolumeID value provided.  Getting next volume id value." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$id = 1

						$Found = $false

						While (-not $Found -and $id -lt 256)
						{

							if (-not($_VolumesToAttach | Where-Object id -eq $id))
							{

								"[{0}] Setting Volume ID to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $id | Write-Verbose

								$_Volume.id = $id

								$Found = $true

							}

							$id++

						}

					}

					# If the storage paths array is null, Process connections to add mapping
					if ($_Volume.storagePaths.Count -eq 0)
					{

						"[{0}] Storage Paths value is Null. Building connection mapping." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						# This should only be 1 within members array
						foreach ($_member in $_resp.members) 
						{

							if ($_Member.deviceSpecificAttributes.iqn -or $_Member.family -eq 'StoreVirtual')
							{

								"[{0}] Looking for Ethernet connections." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								$_StorageTypeUri = '/rest/ethernet-networks'
								
							}

							else
							{

								"[{0}] Looking for FC/FCoE connections." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								$_StorageTypeUri = '/rest/fc'

							}

							# Figure out which connections "should" map based on identified storage connectivity type
							[Array]$_ProfileConnections = $_spt.connectionSettings.connections | Where-Object { $_.networkUri.StartsWith($_StorageTypeUri) }

							"[{0}] Number of connections that match the volume connectivity type: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ProfileConnections.Count | Write-Verbose

							if ($_ProfileConnections.Count -gt 0)
							{

								"[{0}] Connections that match the volume connectivity type: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [String]::Join(', ', [Array]$_ProfileConnections.id) | Write-Verbose

							}

							[Array]$_ReachableNetworkUris = $_Member.reachableNetworks | Where-Object { $_.StartsWith($_StorageTypeUri) }

							"[{0}] Number of reachable networks that match the volume connectivity type: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ReachableNetworkUris.Count | Write-Verbose

							if ($_ReachableNetworkUris.Count -gt 0)
							{

								"[{0}] Reachable networks that match the volume connectivity type: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [String]::Join(', ', [Array]$_ReachableNetworkUris) | Write-Verbose

							}

							ForEach ($_ReachableNetworkUri in $_ReachableNetworkUris)
							{

								"[{0}] Processing reachable network URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ReachableNetworkUri | Write-Verbose

								ForEach ($_ProfileConnection in ($_ProfileConnections | Where-Object { $_.networkUri -eq $_ReachableNetworkUri }))
								{

									"[{0}] Mapping connectionId '{1}' -> volumeId '{2}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ProfileConnection.id, $_Volume.id | Write-Verbose

									$_StoragePath = NewObject -StoragePath

									$_StoragePath.connectionId = $_ProfileConnection.id
									$_StoragePath.isEnabled    = $True

									if ($_Volume.TargetPortAssignmentType)
									{

										"[{0}] Getting FC network to get associated SAN." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

										#$_uri = "{0}/reachable-ports?query=expectedNetworkUri EQ '{1}'" -f $_VolumeToStorageSystem.uri, $profileConnection.networkUri
										$_StoragePath.targetSelector = 'TargetPorts'

										Try
										{

											$_ServerProfileConnectionNetwork = Send-HPOVRequest -Uri $profileConnection.networkUri -Hostname $ServerProfile.ApplianceConnection

										}

										Catch
										{

											$PSCmdlet.ThrowTerminatingError($_)

										}

										# // TODO: Need to get storage system ports to finalize initiator to target port mapping
										$_StorageSystemExpectedMappedPorts = $_AvailStorageSystems.ports | Where-Object expectedSanUri -eq $_ServerProfileConnectionNetwork.managedSanUri

										ForEach ($_PortID in $_Volume.TargetAddresses)
										{

											"[{0}] Looking for {1} host port from available storage system." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_PortID | Write-Verbose

											if ($WwnAddressPattern.Match($_PortID))
											{

												$_PortType = 'name'

											}

											elseif ($StoreServeTargetPortIDPattern.Match($_PortID))
											{

												$_PortType = 'address'

											}

											ForEach ($_HostPort in ($_StorageSystemExpectedMappedPorts | Where-Object $_PortType -match $_PortID))
											{

												"[{0}] Adding {1} ({2}) host port to targets." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_HostPort.address, $_HostPort.name | Write-Verbose

												[void]$_StoragePath.targets.Add($_HostPort.address)

											}

										}

									}

									[void]$_Volume.storagePaths.Add($_StoragePath)

								}

							}

							if ($_Volume.storagePaths.Count -eq 0)
							{

								Write-Warning ('No available connections were found that could attach to {0} Storage Volume.  Storage Volumes may not be attached.' -f $_VolumeName)

							}

							[void]$_spt.sanStorage.volumeAttachments.Add($_Volume)

						}

					}

					else
					{
					
						[void]$_spt.sanStorage.volumeAttachments.Add($_Volume)
					
					}

				}

				# No members found, generate exception
				else
				{

					$ExceptionMessage = "'{0}' Volume is not available to be attached to the profile. Please check the volume or available storage pools and try again." -f $_VolumeName
					$ErrorRecord = New-ErrorRecord InvalidOperationException StorageVolumeUnavailableForAttach ResourceUnavailable 'StorageVolume' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

		}

		"[{0}] Profile JSON Object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_spt | ConvertTo-Json -depth 99) | Write-Verbose

		if ($PassThru.IsPresent)
		{

			$_spt

		}

		else
		{

			Try
			{

				$resp = Send-HPOVRequest -uri $ServerProfileTemplatesUri -Method POST -Body $_spt -appliance $ApplianceConnection

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($PSBoundParameters['Async'])
			{

				$Resp

			}

			else
			{

				Try
				{

					$Resp | Wait-HPOVTaskComplete -OutVariable Resp

					if ($Resp.taskState -eq 'Error')
					{

						$ExceptionMessage = $resp.taskErrors.message
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileTemplateResourceException InvalidOperation InvalidOperation 'AsyncronousTask' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

					}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
			}

		}		

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
	}    

}
