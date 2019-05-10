function New-HPOVServerProfile 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[Parameter (Mandatory, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory, ParameterSetName = "SPT")]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[ValidateSet ("Bay", "Server", "Unassigned")]
		[Alias ('assign')]
		[String]$AssignmentType = 'Server',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[ValidateNotNullOrEmpty()]
		[object]$Enclosure,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[ValidateRange(1,16)]
		[Alias ('bay')]
		[int32]$EnclosureBay,

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "SPT")]
		[ValidateNotNullOrEmpty()]
		[object]$Server,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")] 
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[string]$Description,

		[Parameter (Mandatory, ParameterSetName = "SPT")]
		[Object]$ServerProfileTemplate,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[ValidateNotNullOrEmpty()]
		[array]$Connections,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[Alias ('eg')]
		[object]$EnclosureGroup,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[Alias ('sht')]
		[object]$ServerHardwareType,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[ValidateNotNullOrEmpty()]
		[switch]$Firmware,
	
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[ValidateNotNullOrEmpty()]
		[object]$Baseline,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[Alias ('FirmwareMode')]
		[ValidateSet ('FirmwareOnly', 'FirmwareAndSoftware', 'FirmwareOffline', 'FirmwareAndOSDrivers', 'FirmwareOnlyOfflineMode')]
		[string]$FirmwareInstallMode = 'FirmwareAndSoftware',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[ValidateSet ('Immediate', 'Scheduled', 'NotScheduled')]
		[string]$FirmwareActivationMode = 'Immediate',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[ValidateNotNullOrEmpty()]
		[DateTime]$FirmwareActivateDateTime,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[switch]$ForceInstallFirmware,
	
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[switch]$Bios = $false,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[array]$BiosSettings = @(),
		
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]        
		[ValidateSet ("UEFI","UEFIOptimized","BIOS",'Unmanaged', IgnoreCase = $False)]
		[string]$BootMode = "BIOS",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]        
		[ValidateSet ("Auto","IPv4","IPv6","IPv4ThenIPv6","IPv6ThenIPv4", IgnoreCase = $False)]
		[string]$PxeBootPolicy = "Auto",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[Alias ('boot')]
		[switch]$ManageBoot,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[array]$BootOrder,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ("Unmanaged", "Enabled", "Disabled", IgnoreCase = $False)]
		[String]$SecureBoot = 'Unmanaged',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[switch]$LocalStorage,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[Alias ('LogicalDisk')]
		[ValidateNotNullorEmpty()]
		[Object]$StorageController,

		[Parameter (Mandatory, ParameterSetName = "SANStorageAttach")]
		[switch]$SANStorage,

		[Parameter (Mandatory, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ('CitrixXen','CitrixXen7','AIX','IBMVIO','RHEL4','RHEL3','RHEL','RHEV','RHEV7','VMware','Win2k3','Win2k8','Win2k12','Win2k16','OpenVMS','Egenera','Exanet','Solaris9','Solaris10','Solaris11','ONTAP','OEL','HPUX11iv1','HPUX11iv2','HPUX11iv3','SUSE','SUSE9','Inform', IgnoreCase = $true)]
		[Alias ('OS')]
		[string]$HostOStype,

		[Parameter (Mandatory, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullorEmpty()]
		[object]$StorageVolume,

		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Alias ('Even')]
		[switch]$EvenPathDisabled,

		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Alias ('Odd')]
		[switch]$OddPathDisabled,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ("Bay","BayAndServer", IgnoreCase = $false)]
		[string]$Affinity = "Bay",
	
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ("Virtual", "Physical", "UserDefined", IgnoreCase)]
		[string]$MacAssignment = "Virtual",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ("Virtual", "Physical", "'UserDefined", IgnoreCase)]
		[string]$WwnAssignment = "Virtual",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateSet ("Virtual", "Physical", "UserDefined", IgnoreCase)]
		[string]$SnAssignment = "Virtual",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[string]$SerialNumber,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[string]$Uuid,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullOrEmpty()]
		[bool]$HideUnusedFlexNics = $True,

		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPTEmptyBay")]
		[ValidateNotNullOrEmpty()]
		[Array]$IscsiIPv4Address,

		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[ValidateScript ({
			
			[RegEx]::Match($_,$iQNPattern).Success
			
			})]
		[string]$ISCSIInitatorName,

		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[ValidateNotNullOrEmpty()]
		[SecureString]$ChapSecret,

		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[ValidateNotNullOrEmpty()]
		[SecureString]$MutualChapSecret,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[Object]$OSDeploymentPlan,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[Array]$OSDeploymentAttributes,

		[Parameter (Mandatory = $false, ParameterSetName = "Import")]
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "SPT")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "SANStorageAttach")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory, ParameterSetName = "Import")]
		[switch]$Import,
		
		[Parameter (Mandatory, ParameterSetName = "Import", ValueFromPipeline)]
		[ValidateNotNullorEmpty()]
		[Alias ("location","file")]
		[Object]$ProfileObj,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SANStorageAttach")]
		[Parameter (Mandatory = $false, ParameterSetName = "SPT")]
		[Switch]$Passthru

	)
	
	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($PSBoundParameters['Bootable'])
		{

			Write-Warning 'The -Bootable Parameter has been deprecated. In order to configure local storage, please read Help New-HPOVServerProfile and the LocalDisk Parameter.'

		}

		if ($PSBoundParameters['RaidLevel'])
		{

			Write-Warning 'The -RaidLevel Parameter has been deprecated. In order to configure local storage, please read Help New-HPOVServerProfile and the LocalDisk Parameter.'

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

		if (-not($PSBoundParameters['ServerProfileTemplate']))
		{

			if ($snAssignment -eq "UserDefined" -and (-not($serialnumber)) -and (-not($uuid))) 
			{
		
				$ErrorRecord = New-ErrorRecord HPOneview.ServerProfileResourceException InvalidArgument InvalidArgument 'snAssignment' -Message "The -snAssignment paramter was set to 'UserDefined', however both -serialnumber and -uuid are Null.  You must specify a value for both Parameters."
		
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
		
			}
		
			elseif ($snAssignment -eq "UserDefined" -and $serialnumber -and (-not($uuid))) 
			{
		
				$ErrorRecord = New-ErrorRecord HPOneview.ServerProfileResourceException InvalidArgument InvalidArgument 'uuid' -Message "The -snAssignment paramter was set to 'UserDefined', however -uuid is Null.  You must specify a value for both Parameters."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			elseif ($snAssignment -eq "UserDefined" -and (-not($serialnumber)) -and $uuid) 
			{
			
				$ErrorRecord = New-ErrorRecord HPOneview.ServerProfileResourceException InvalidArgument InvalidArgument 'serialnumber' -Message "The -snAssignment paramter was set to 'UserDefined', however -serialnumber is Null.  You must specify a value for both Parameters."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
		
			}

			# Update the error information
			switch ($AssignmentType) 
			{ 

				"server" 
				{

					if (-not($server))
					{
						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfileResourceException InvalidArgument InvalidArgument 'Server' -Message "The -AssignmentType Parameter is set to 'server', but no server Parameter was supplied."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				"bay" 
				{

					if (-not($enclosureBay))
					{

						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfileResourceException InvalidArgument InvalidArgument 'AssignmentType' -Message "The -AssignmentType Parameter is set to 'bay', but no bay Parameter was supplied."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if (-not($enclosure))
					{

						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfileResourceException InvalidArgument InvalidArgument 'AssignmentType' -Message "The -AssignmentType Parameter is set to 'bay', but no Enclosure Parameter was supplied."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if (-not($ServerHardwareType))
					{

						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfileResourceException InvalidArgument InvalidArgument 'AssignmentType' -Message "The -AssignmentType Parameter is set to 'bay', but no ServerHardwareType Parameter was supplied."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if ($ApplianceConnection.Count -gt 1)
					{

						if($enclosure -is [string] -and $enclosure.StartsWith("/rest"))
						{

							$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerHardwareTypeObject InvalidArgument 'Enclosure' -Message "Enclosure as URI is not supported for multiple appliance connections."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

				}

				"unassigned" 
				{
				
					# If the profile is not based on a template, the SHT is required
					if ((-not($PSBoundParameters['Template'])) -and (-not($PSBoundParameters['ServerHardwareType'])))
					{

						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfileResourceException InvalidArgument InvalidArgument 'ServerHardwareType' -Message "The -AssignmentType Parameter is set to 'unassigned', but no server hardware type was supplied."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if ($PSBoundParameters['Server'])
					{

						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfileResourceException InvalidArgument InvalidArgument 'ServerHardwareType' -Message "The -AssignmentType Parameter is set to 'unassigned', and a Server object/name was provided. You cannot both assign and unassign a Server Profile."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

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

				# Server
				if ($server -is [string] -and $server.StartsWith("/rest")) 
				{
				
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerHardwareTypeObject InvalidArgument 'New-HPOVPropfile' -Message "Server as URI is not supported for multiple appliance connections."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
				}

				#Baseline
				if (($baseline -is [string]) -and ($baseline.StartsWith('/rest'))) 
				{
				
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerHardwareTypeObject InvalidArgument 'New-HPOVPropfile' -Message "Baseline as URI is not supported for multiple appliance connections."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
				}

				# Import
				if($Import) 
				{
				
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerHardwareTypeObject InvalidArgument 'New-HPOVPropfile' -Message "Import functionality is not supported for multiple appliance connections."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

		}

		if ($PSBoundParameters['IscsiIPv4Address'])
		{

			$_TmpCollection = New-Object System.Collections.ArrayList

			$IscsiIPv4Address | ForEach-Object { [void]$_TmpCollection.Add($_) }

			$IscsiIPv4Address = $_TmpCollection.Clone()

		}	

		$uri = $ServerProfilesUri

		$colStatus = New-Object System.Collections.ArrayList

	}
	
	Process 
	{

		if ($AssignmentType -eq 'Server' -and -not $Server)
		{

			$ExcpetionMessage = 'A Server resource object or name must be provided when using the "Server" AssignmentType parameter.'
			$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException NullServerNotAllowed InvalidArgument 'Server' -Message $ExcpetionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Import Server Profile JSON to appliance
		if ($PSBoundParameters['Import']) 
		{

			"[{0}] Import server profile" -f $($MyInvocation.InvocationName.ToString().ToUpper()) | Write-Verbose

			if (($ProfileObj -is [System.String]) -and (Test-Path $ProfileObj)) 
			{

				# Received file location
				"[{0}] Received JSON file as input: {1}" -f $($MyInvocation.InvocationName.ToString().ToUpper()), $ProfileObj | Write-Verbose
			
				$ServerProfile = (get-content $ProfileObj) -join "`n" | convertfrom-json
				
				# Remove unique values with Select-Object
				$ServerProfile = $ServerProfile | Select-Object * -Exclude uri,created,modified,eTag,ApplianceConnection

			}

			# Input object could be the JSON object, which is type [System.String]
			elseif ($ProfileObj -is [System.String]) 
			{

				"[{0}] Received JSON resource object as input {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($ProfileObj | out-string) | Write-Verbose
				
				$ServerProfile = $ProfileObj -join "`n" | convertfrom-json

			}

			# Input object is PsCustomObject of a Server Profile
			elseif ($ProfileObj -is [PsCustomObject]) 
			{

				"[{0}] Received JSON PsCustomObject as input {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($ProfileObj | out-string) | Write-Verbose

				$ServerProfile = $ProfileObj.PSObject.Copy()

			}

			# Inavlid input type for $ProfileObj and Generate Terminating Error
			else 
			{ 

				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidImportObject InvalidArgument 'ProfileObj' -Message "Invalid `$Import input object.  Please check the object you provided for ProfileObj Parameter and try again"
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

		}

		else
		{

			if ($PSBoundParameters['ServerProfileTemplate'])
			{

				# Validate ServerProfileTemplate Parameter value
				switch ($ServerProfileTemplate.GetType().Name)
				{

					'PSCustomObject'
					{

						"[{0}] Received PSCustomObject for ServerProfileTemplate." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						"[{0}] Resource Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerProfileTemplate.name | Write-Verbose

						"[{0}] Resource Category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerProfileTemplate.category | Write-Verbose

						if ($ServerProfileTemplate.category -ne $ResourceCategoryEnum.ServerProfileTemplate)
						{

							$ExceptionMessage = "Invalid ServerProfileTemplate input object.  The input object category '{0}' is not the expected value '{1}'.  Please check the value and try again." -f $ServerProfileTemplate.category, $ResourceCategoryEnum.ServerProfileTemplate
							$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileTemplateResourceException InvalidServerProfileTemplateObject InvalidArgument 'ServerProfileTemplate' -TargetType 'PSObject' -Message $ExceptionMessage

							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

					# Validate the String data value
					'String'
					{

						if ($ServerProfileTemplate.StartsWith($ServerProfileTemplatesUri))
						{

							"[{0}] Resource URI Received. Getting resource object from API." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							Try
							{

								$ServerProfileTemplate = Send-HPOVRequest -Uri $ServerProfileTemplate -Hostname $ApplianceConnection.Name

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

						}

						else
						{

							"[{0}] Resource Name Received." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							Try
							{

								$ServerProfileTemplate = Get-HPOVServerProfileTemplate -Name $ServerProfileTemplate -ApplianceConnection $ApplianceConnection.Name -ErrorAction Stop

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

						}

					}
					
				}

				"[{0}] Requesting new Server Profile from API." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$ServerProfile = Send-HPOVRequest -Uri ($ServerProfileTemplate.uri + "/new-profile") -Hostname $ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				$ServerProfile = $ServerProfile | Select-Object * -ExcludeProperty templateCompliance,uri,serialnumber,uuid,taskUri,inProgress,state,status,modified,created,associatedServer,eTag,category

				# If there are existing connections, handle the iSCSI ones for IPAddress and CHAP password
				if ($ServerProfile.connectionSettings.connections)
				{

					# Rebuild Connections into an ArrayList
					$_TmpConnections = $ServerProfile.connectionSettings.connections.Clone()

					$ServerProfile.connectionSettings.connections = New-Object System.Collections.ArrayList

					ForEach ($_con in $_TmpConnections)
					{

						[void]$ServerProfile.connectionSettings.connections.Add($_con)

					}

					# ForEach ($_conn in $ServerProfile.connections)
					For ([int]$c = 0; $c -lt $ServerProfile.connectionSettings.connections.Count; $c++) 
					{

						# Perform Param validation
						if ($ServerProfile.connectionSettings.connections[$c].functionType -eq 'iSCSI')
						{

							# ISCSI Connection is Bootable
							if ($ServerProfile.connectionSettings.connections[$c].boot.priority -ne 'NotBootable')
							{

								# An IPv4 Address was not provided, generate error
								if (-not($PSBoundParameters['IscsiIPv4Address']) -and $ApplianceConnection.Type -ne 'Composer')
								{

									$Message     = 'Connection ID {0} is configured for {1}, but the -IscsiIPv4Address Parameter was not provided.  Please specify an IPv4Address in your command.' -f $ServerProfile.connections[$c].id , $ServerProfile.connections[$c].boot.priority
									$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException IscsiIPv4AddressParamRequired InvalidArgument 'Connections' -TargetType 'PSObject' -Message $Message
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

								}

								# This is NOT an error, do don't generate one.  Set initiatorNameSource -> UserDefined, and also need to set Profile to 
								if ($PSBoundParameters['ISCSIInitatorName'])
								{

									$ServerProfileTemplate.iscsiInitiatorNameType           = 'UserDefined'
									$ServerProfile.connectionSettings.connections[$c].boot.initiatorName       = $ISCSIInitatorName
									$ServerProfile.connectionSettings.connections[$c].boot.initiatorNameSource = 'UserDefined'

								}

								switch ($ServerProfile.connectionSettings.connections[$c].boot.chapLevel)
								{

									'Chap'
									{

										if (-not($PSBoundParameters['ChapSecret']))
										{

											$Message     = 'Connection ID {0} is configured for "CHAP" Authentication, but the -ChapSecret Parameter was not provided.' -f $ServerProfile.connections[$c].id 
											$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException ChapSecretParamRequired InvalidArgument 'Connections' -TargetType 'PSObject' -Message $Message
											$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

										}

										$ServerProfile.connectionSettings.connections[$c].boot.chapPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ChapSecret))

									}

									'MutualChap'
									{

										if (-not($PSBoundParameters['ChapSecret']))
										{

											$Message     = 'Connection ID {0} is configured for "CHAP" Authentication, but the -ChapSecret Parameter was not provided.'
											$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException ChapSecretParamRequired InvalidArgument 'Connections' -TargetType 'PSObject' -Message $Message
											$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

										}

										if (-not($PSBoundParameters['MutualChapSecret']))
										{

											$Message     = 'Connection ID {0} is configured for "MutualChap" Authentication, but the -MutualChapSecret Parameter was not provided.'
											$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException MutualChapSecretParamRequired InvalidArgument 'Connections' -TargetType 'PSObject' -Message $Messag
											$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

										}

										$ServerProfile.connectionSettings.connections[$c].boot.chapSecret       = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ChapSecret))
										$ServerProfile.connectionSettings.connections[$c].boot.mutualChapSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($MutualChapSecret))

									}

								}

								if ($IscsiIPv4Address.count -gt 0)
								{

									"[{0}] Assigning {1} IPv4Address to Connection ID {2}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $IscsiIPv4Address[0], $ServerProfile.connections[$c].id | Write-Verbose

									$_IPv4Address = $IscsiIPv4Address[0]

									[void]$IscsiIPv4Address.Remove($_IPv4Address)

									$ServerProfile.connectionSettings.connections[$c].boot.initiatorIp = $_IPv4Address

								}

								else
								{

									$Message = 'Connection ID {0} is configured as a Bootable iSCSI Connection, however no additional IPv4Address is available to allocate.' -f $ServerProfile.connections[$c].id
									$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException MutualChapSecretParamRequired InvalidArgument 'Connections' -TargetType 'PSObject' -Message $Messag
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

								}

							}

						}

					}

				}

				else
				{

					$ServerProfile.connectionSettings.connections = New-Object System.Collections.ArrayList

				}

				# Handle firmware differently
				if ($ServerProfile.firmware.manageFirmware -and $ServerProfile.firmware.firmwareActivationType -eq 'Scheduled')
				{

					$ServerProfile.firmware.forceInstallFirmware = [bool]$ForceInstallFirmware

					if ($PSBoundParameters['FirmwareInstallMode'])
					{

						"[{0}] Overriding SPT Firmware Install Type: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerProfileFirmwareControlModeEnum[$FirmwareInstallMode] | Write-Verbose
						$ServerProfile.firmware.firmwareInstallType = $ServerProfileFirmwareControlModeEnum[$FirmwareInstallMode]
				
					}

					if ($PSBoundParameters['FirmwareActivationMode'])
					{

						$ServerProfile.firmware.firmwareActivationType = $ServerProfileFirmareActivationModeEnum[$FirmwareActivationMode]

					}

					if ('FirmwareOffline', 'FirmwareOnlyOfflineMode' -contains $ServerProfile.firmware.firmwareActivationType -and $PSBoundParameters['FirmwareActivateDateTime'])
					{

						$ExceptionMessage = "The Server Profile Template is not configured to schedule firmware activation, and the use of -FirmwareActivationDateTime parameter is not supported.  Please choose a different Server Profile Template with Online updates, or overrride using the -FirmwareInstallMode parameter."
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidFirmwareInstallMode InvalidArgument 'FirmwareActivateDateTime' -TargetType 'Switch' -Message	$ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
					}

					elseif ($ServerProfile.firmware.firmwareActivationType -eq 'Scheduled' -and -not $PSBoundParameters['FirmwareActivateDateTime'])
					{

						$ExceptionMessage = "The Server Profile Template provided is set to schedule firmware activation, which requires the -FirmwareActivateDateTime parameter."
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidFirmwareInstallMode InvalidArgument 'FirmwareActivateDateTime' -TargetType 'Switch' -Message	$ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
					}

					elseif ($ServerProfile.firmware.firmwareActivationType -eq 'Scheduled' -and $PSBoundParameters['FirmwareActivateDateTime'])
					{

						# Convert DateTime to UTC time for the appliance
						"[{0}] Setting firmware activation schedule: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $FirmwareActivateDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ") | Write-Verbose
						$ServerProfile.firmware.firmwareScheduleDateTime = $FirmwareActivateDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

					}	

				}

				# Get SHT from Template
				# Get the SHT of the SH that we are going to assign.
				Try
				{

					$ServerHardwareType = Send-HPOVRequest -Uri $ServerProfile.serverHardwareTypeUri -appliance $ApplianceConnection

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($ServerProfile.enclosureGroupUri)
				{

					Try
					{

						$EnclosureGroup = Send-HPOVRequest -Uri $ServerProfile.enclosureGroupUri -appliance $ApplianceConnection

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				# Process OSDeploymentAttributes for SP from SPT
				# Do we need to first look at the osDeploymentSettings at all for Constraints?
				if ($PSBoundParameters['OSDeploymentAttributes'])
				{

					If ($ApplianceConnection.ApplianceType -ne 'Composer')
					{

						$ExceptionMessage = 'The ApplianceConnection {0} is not a Synergy Composer.  The OSDeploymentAttributes parameter is only supported with HPE Synergy and HPE ImageStreamer.' -f $ApplianceConnection.Name
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					ForEach ($_PlanAttribute in $ServerProfile.osDeploymentSettings.osCustomAttributes)
					{

                        			if (($ServerProfile.osDeploymentSettings.osCustomAttributes | Where-Object { $_.Name -match ('{0}.constraint' -f $_PlanAttribute.name)}) -and 'Auto', 'DHCP' -notcontains $_PlanAttribute.value -and -not ($OSDeploymentAttributes | Where-Object name -eq $_PlanAttribute.name))
						{

							$ExceptionMessage = 'The attribute {0} requires a value and is not provided in the OSDeploymentAttributes.' -f $_PlanAttribute.name
							$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.OSDeploymentAttributeResourceException InvalidOperation InvalidArgument 'OSDeploymentAttributes' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
						}

						'[{0}] Setting {1} attribute to {2}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_PlanAttribute.name, ($OSDeploymentAttributes | Where-Object name -eq $_PlanAttribute.name).value | Write-Verbose

						($ServerProfile.osDeploymentSettings.osCustomAttributes | Where-Object name -eq $_PlanAttribute.name).value = ($OSDeploymentAttributes | Where-Object name -eq $_PlanAttribute.name).value

					}

				}

			}

			else
			{

				"[{0}] Get generic Server Profile object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

				# New Server Resource Object
				$ServerProfile = NewObject -ServerProfile
				
				$ServerProfile.affinity           = $Affinity
				$ServerProfile.hideUnusedFlexNics = [bool]$HideUnusedFlexNics
				$ServerProfile.bios.manageBios    = [bool]$Bios
				$ServerProfile.boot.manageBoot    = $ManageBoot.IsPresent
				$ServerProfile.boot.order         = $BootOrder
				$ServerProfile.serialNumberType   = $SnAssignment 
				$ServerProfile.macType            = $MacAssignment
				$ServerProfile.wwnType            = $WwnAssignment
				$ServerProfile.serialNumber       = $Serialnumber
				$ServerProfile.uuid               = $Uuid

				# Process OSDeploymentPlan
				if ($PSBoundParameters['OSDeploymentPlan'])
				{

					If ($ApplianceConnection.ApplianceType -ne 'Composer')
					{

						$ExceptionMessage = 'The ApplianceConnection {0} is not a Synergy Composer.  The OSDeploymentPlan parameter is only supported with HPE Synergy and HPE ImageStreamer.' -f $ApplianceConnection.Name
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if ($OSDeploymentPlan.type -ne 'Osdp')
					{

						$ExceptionMessage = 'The provided OSDeploymentPlan parameter value is not a valid OS Deployment Plan resource.' -f $ApplianceConnection.Name
						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.OSDeploymentPlanResourceException InvalidOperation InvalidArgument 'OSDeploymentPlan' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
						
					}

					$_OSDeploymentSettings = NewObject -OSDeploymentSettings
					$_OSDeploymentSettings.osDeploymentPlanUri = $OSDeploymentPlan.uri

					ForEach ($_PlanAttribute in $OSDeploymentAttributes)
					{

						if ($_PlanAttribute -isnot [HPOneView.ServerProfile.OSDeployment.OSDeploymentParameter])
						{

							$ExceptionMessage = 'The provided OSDeploymentAttribute parameter value is not a valid resource.' -f $ApplianceConnection.Name
							$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.OSDeploymentAttributeResourceException InvalidOperation InvalidArgument 'OSDeploymentAttributes' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}						

						$_PlanAttributeSetting = NewObject -OSDeploymentPlanSetting
						$_PlanAttributeSetting.name  = $_PlanAttribute.name
						$_PlanAttributeSetting.value = $_PlanAttribute.value

						'[{0}] Setting {1} attribute to {2}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_PlanAttribute.name, $_PlanAttribute.value | Write-Verbose

						[void]$_OSDeploymentSettings.osCustomAttributes.Add($_PlanAttributeSetting)

					}

					$ServerProfile | Add-Member -NotePropertyName osDeploymentSettings -NotePropertyValue $null -Force

					$ServerProfile.osDeploymentSettings = $_OSDeploymentSettings

				}

			}

			if ('Unassigned', 'Bay' -Contains $AssignmentType) 
			{
			
				"[{0}] Profile assignmentType: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $AssignmentType | Write-Verbose 
			
				# Check to see if the serverHardwareType is null, and generate error(s) then break.
				if (-not $ServerHardwareType)
				{

					$ExceptionMessage = "Server Hardware Type is missing.  Please provide a Server Hardware Type using the -sht Parameter and try again."
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerHardwareTypeObject InvalidArgument 'ServerHardwareType' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}
			
				# If the URI is passed as the Server Hardware Type, then set the serverHardwareTypeUri variable
				If ($ServerHardwareType -is [string])
				{

					if ($ServerHardwareType.StartsWith($script:serverHardwareTypesUri))
					{ 
						
						"[{0}] SHT URI Provided: {1}"  -f $($MyInvocation.InvocationName.ToString().ToUpper()), $ServerHardwareType | Write-Verbose 

						Try
						{
						
							$ServerHardwareType = Send-HPOVRequest -Uri $ServerHardwareType -appliance $ApplianceConnection
						
						}
						
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}
				
					# Otherwise, perform a lookup ofthe SHT based on the name
					else 
					{

						"[{0}] SHT Name Provided: {1}"  -f $($MyInvocation.InvocationName.ToString().ToUpper()), $ServerHardwareType | Write-Verbose 

						Try
						{

							$ServerHardwareType = Get-HPOVServerHardwareType -name $ServerHardwareType -ErrorAction Stop -ApplianceConnection $ApplianceConnection

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

				}

				# Else the SHT object is passed
				elseif ($ServerHardwareType)
				{ 

					$ServerHardwareType = $ServerHardwareType | Where-Object { $_.ApplianceConnection.name -eq $ApplianceConnection.name }

					"[{0}] ServerHardwareType object provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
					"[{0}] ServerHardwareType Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerHardwareType.name | Write-Verbose 
					"[{0}] ServerHardwareType Uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerHardwareType.uri | Write-Verbose 
					
				}

				if (-not($PSBoundParameters['EnclosureGroup']) -and (-not($ServerHardwareType.model -match "DL")) -and $AssignmentType -eq 'unassigned' -and $null -eq $ServerProfileTemplate)
				{
						
					$ExceptionMessage = "Enclosure Group is missing.  Please provide an Enclosure Group using the -EnclosureGroup Parameter and try again."
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidEnclosureGroupObject InvalidArgument 'EnclosureGroup' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				elseif ($PSBoundParameters['EnclosureGroup'] -is [string] -and $AssignmentType -eq 'unassigned')
				{

					# If the URI is passed as the Enclosure Group, then set the enclosureGroupUri variable
					if ($EnclosureGroup.StartsWith('/rest'))
					{ 
						
						Try
						{

							$EnclosureGroup = Send-HPOVRequest -Uri $EnclosureGroup -appliance $ApplianceConnection

						}
						
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}
					
					}

					# Otherwise, perform a lookup ofthe Enclosure Group
					else
					{

						Try
						{

							$EnclosureGroup = Get-HPOVEnclosureGroup -name $EnclosureGroup -ErrorAction Stop -appliance $ApplianceConnection

						}
						
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}
						
					}

					"[{0}] EG URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnclosureGroup.uri | Write-Verbose

				}
						
				# Else the EG object is passed
				elseif (($EnclosureGroup -is [Object]) -and ($EnclosureGroup.category -eq "enclosure-groups") -and $AssignmentType -eq 'unassigned') 
				{ 

					$EnclosureGroup = $EnclosureGroup | Where-Object { $ApplianceConnection.name -eq $_.applianceConnection.name }

					"[{0}] Enclosure Group object provided" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnclosureGroup.name | Write-Verbose
					"[{0}] Enclosure Group Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnclosureGroup.name | Write-Verbose
					"[{0}] Enclosure Group Uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnclosureGroup.uri | Write-Verbose

				}

				elseif (-not $EnclosureGroup -and ($ServerHardwareType.model -match "DL")) 
				{

					"[{0}] Server is a ProLiant DL model. Enclosure Group not required." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

				# EG Param not required if assignment is to a bay
				elseif (-not $PSBoundParameters['EnclosureGroup'] -and $AssignmentType -eq 'bay')
				{

					# First check for $enclosure Param
					if (-not $PSBoundParameters['Enclosure'])
					{

						$ExceptionMessage = "Enclosure parameter is missing.  Please provide an Enclosure using the -enclosure Parameter and try again."
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidEnclosureObject InvalidArgument 'Enclosure' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}
					
					# Retrieve the enclosure group uri from passed in enclosure uri Param
					elseif($Enclosure -is [string]) 
					{
						
						if($Enclosure.StartsWith('/rest'))
						{ 
									
							try 
							{

								$Enclosure = Send-HPOVRequest -Uri $Enclosure -appliance $ApplianceConnection

							}

							catch 
							{

								$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidEnclosureGroupObject InvalidArgument 'Enclosure' -Message "Enclosure is missing.  Please provide an Enclosure using the -enclosure Parameter and try again."
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
							}

						}

						# Enclosure is a name
						else
						{

							try 
							{

								$Enclosure = Get-HPOVEnclosure -Name $Enclosure -ErrorAction Stop -appliance $ApplianceConnection
								
							}

							catch 
							{

								$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidEnclosureGroupObject InvalidArgument 'Enclosure' -Message "Enclosure is missing.  Please provide an Enclosure using the -enclosure Parameter and try again."
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

						}

					}

					elseif ($Enclosure -is [object] -and $Enclosure.category -match 'enclosures')
					{

						$Enclosure = $Enclosure | Where-Object { $_.ApplianceConnection.Name -eq $ApplianceConnection.name }

						"[{0}] Enclosure object provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					}

					"[{0}] Enclosure Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Enclosure.uri | Write-Verbose
					"[{0}] Enclosure's Enclosure Group Uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Enclosure.enclosureGroupUri | Write-Verbose

					$serverProfile.enclosureUri      = $Enclosure.uri
					$serverProfile.enclosureGroupUri = $Enclosure.enclosureGroupUri
					$serverProfile.enclosureBay      = $EnclosureBay
							
				} 
		
				else 
				{ 

					$ExceptionMessage = "Enclosure Group is invalid.  Please specify a correct Enclosure Group name, URI or object and try again."
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidEnclosureGroupObject InvalidArgument 'EnclsoureGroup' -TargetType $EnclosureGroup.GetType().Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
				}

			}

			# Creating an assigned profile
			else 
			{
			
				# Looking for the $server DTO to be string
				if ($Server -is [string]) 
				{
				
					# If the server URI is passed, look up the server object
					if ($Server.StartsWith($ServerHardwareUri)) 
					{

						"[{0}] Server URI passed: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Server | Write-Verbose 
						
						Try
						{
						
							$Server = Send-HPOVRequest -Uri $Server -appliance $ApplianceConnection
						
						}
						
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}
				
					# Else the name is passed and need to look it up.
					else
					{

						Try
						{

							$Server = Get-HPOVServer -name $Server -appliance $ApplianceConnection

						}
					
						Catch
						{
							
							$PSCmdlet.ThrowTerminatingError($_)	
							
						}		    
					
					}

				}
			
				"[{0}] Server object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($Server | Out-String) | Write-Verbose 

				# Check to make sure the server NoProfileApplied is true
				if ($Server.serverProfileUri)
				{

					Try
					{

						$ServerProfileConflict = Send-HPOVRequest -Uri $Server.serverProfileUri -Hostname $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$ExceptionMessage = "{0} already has a profile assigned, '{1}'.  Please specify a different Server Hardware object." -f $Server.name, $ServerProfileConflict.name
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerProfileAlreadyAssigned ResourceExists 'Server' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# Get the SHT of the SH that we are going to assign.
				Try
				{

					$ServerHardwareType = Send-HPOVRequest -Uri $Server.serverHardwareTypeUri -appliance $ApplianceConnection

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				# Set the server hardware URI value in the profile
				$ServerProfile.serverHardwareUri = $Server.uri

				if($AssignmentType -eq 'bay' -and $EnclosureBay)
				{

					$ServerProfile | Add-Member -NotePropertyName enclosureBay -NotePropertyValue $EnclosureBay

				}

				if ($Server.serverGroupUri)
				{

					"[{0}] Getting Enclosure Group object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{
	
						$EnclosureGroup = Send-HPOVRequest -Uri $Server.serverGroupUri
	
					}
					
					Catch
					{
	
						$PSCmdlet.ThrowTerminatingError($_)
	
					}

				}
			
			}

			# User provided UEFI or UEFIOptimized for a non-Gen9 platform.
			if ($BootMode -ne "BIOS" -and $ServerHardwareType.model -notmatch "Gen9|Gen10")
			{

				$ExceptionMessage = "The -BootMode Parameter was provided and the Server Hardware model '{0}' does not support this Parameter.  Please verify the Server Hardware Type is at least an HPE ProLiant Gen9." -f $ServerHardwareType.model
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException BootModeNotSupported InvalidArgument 'BootMode' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)    

			}

			# Handle Boot Order and BootManagement
			# Perform Device Model specific functions?
			switch ($ServerHardwareType.model)
			{

				# Handle DL Server Profiles by setting BL-specific properties to NULL
				{$_ -match "DL|XL|ML"}
				{

					"[{0}] Server Hardware Type is a DL, setting 'macType', 'wwnType', 'serialNumberType', 'affinity' and 'hideUnusedFlexNics' to supported values." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					if (-not $PSboundParameters['ServerProfileTemplate'])
					{

						$ServerProfile.macType            = 'Physical'
						$ServerProfile.wwnType            = 'Physical'
						$ServerProfile.serialNumberType   = 'Physical'
						$ServerProfile.hideUnusedFlexNics = $true
						$ServerProfile.affinity           = $Null

					}
					
				}
				
				{$_ -match 'Gen7|Gen8'}
				{

					if (-not($PSboundParameters['BootOrder']) -and $ManageBoot)
					{

						"[{0}] No boot order provided for Gen8 Server resource type.  Defaulting to 'CD','Floppy','USB','HardDisk','PXE'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

						[System.Collections.ArrayList]$serverProfile.boot.order = ('CD','Floppy','USB','HardDisk','PXE')

					}

				}

				{$_ -match 'Gen9|Gen10'}
				{

					if (-not $ServerProfileTemplate)
					{

						"[{0}] Gen 9/10 Server, setting BootMode to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $BootMode | Write-Verbose 

						$serverProfile.bootMode = NewObject -ServerProfileBootMode

						switch ($BootMode) 
						{

							'Unmanaged'
							{

								$serverProfile.bootMode.manageMode = $false						

							}

							"BIOS" 
							{

								$serverProfile.bootMode = NewObject -ServerProfileBootModeLegacyBios

								$serverProfile.bootMode.manageMode = $true;
								$serverProfile.bootMode.mode       = $BootMode;						
								
							}

							{ "UEFI","UEFIOptimized" -match $_ } 
							{
								
								$serverProfile.bootMode.manageMode    = $true;
								$serverProfile.bootMode.mode          = $BootMode;
								$serverProfile.bootMode.pxeBootPolicy = $PxeBootPolicy
								
								if ($ServerHardwareType.model -match 'DL|XL|ML')
								{

									$serverProfile.boot.manageBoot = $false

								}
								
							}

						}

					}

					if ($BootOrder -or (-not $BootOrder -and -not $ServerProfileTemplate))
					{

						"[{0}] Processing Gen9/10 Server BootOrder settings." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

						if ($ManageBoot -and ($BootOrder -contains "Floppy") -and ($BootMode -match "UEFI"))
						# If ($BootOrder -contains "Floppy" -and $BootMode -match "UEFI")
						{
							
							$ExceptionMessage = "The -BootOrder Parameter contains 'Floppy' which is an invalid boot option for a UEFI-based system."
							$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidUEFIBootOrderParameterValue InvalidArgument 'BootOrder' -TargetType 'Array' -Message	$ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						elseif ((-not ($PSBoundParameters["BootOrder"])) -and $ManageBoot -and ('Unmanaged','UEFI' -notcontains $BootMode)) 
						# Elseif ((-not ($PSBoundParameters["BootOrder"])) -and ('Unmanaged','UEFI' -notcontains $BootMode)) 
						{

							"[{0}] No boot order provided for Gen9 Server resource type.  Defaulting to 'CD','USB','HardDisk','PXE'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

							[System.Collections.ArrayList]$serverProfile.boot.order = @('CD','USB','HardDisk','PXE')
				
						}

						elseif ((-not ($PSBoundParameters["BootOrder"])) -and $ManageBoot -and $BootMode -match 'UEFI' -and $ServerHardwareType.model -notmatch 'DL|XL|ML')
						# Elseif ((-not ($PSBoundParameters["BootOrder"])) -and $BootMode -match 'UEFI' -and $ServerHardwareType.model -notmatch 'DL')
						{

							"[{0}] No boot order provided for BL Gen9 Server resource type.  Defaulting to 'HardDisk'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

							[System.Collections.ArrayList]$serverProfile.boot.order = @('HardDisk')
				
						}

						elseif (($BootOrder.count -gt 1) -and $ManageBoot -and $BootMode -match 'UEFI')
						# Elseif (($BootOrder.count -gt 1) -and $BootMode -match 'UEFI')
						{

							$ExceptionMessage = "The -BootOrder Parameter contains more than 1 entry, and the system BootMode is set to {0}, which is invalud for a UEFI-based system.  Please check the -BootOrder Parameter and make sure either 'HardDisk' or 'PXE' are the only option." -f $BootMode
							$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidUEFIBootOrderParameterValue InvalidArgument 'BootOrder' -TargetType 'Array' -Message	$ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
						}

						elseif ($BootOrder -and $serverProfile.boot.manageBoot -and $BootMode -match 'UEFI' -and $ServerHardwareType.model -notmatch 'DL|XL|ML')
						# Elseif ($BootOrder -and $serverProfile.boot.manageBoot -and $BootMode -match 'UEFI' -and $ServerHardwareType.model -notmatch 'DL')
						{

							"[{0}] Adding provided BootOrder {1} to Server Profile object." -f $MyInvocation.InvocationName.ToString().ToUpper(), ($BootOrder -join ', ') | Write-Verbose 

							[System.Collections.ArrayList]$serverProfile.boot.order = $BootOrder

						}

					}					

				}

			}

			$ServerProfile.name                  = $Name
			$ServerProfile.description           = $Description
			$ServerProfile.serverHardwareTypeUri = $ServerHardwareType.uri

			if ($EnclosureGroup -and $null -eq $ServerProfile.enclsosureGroupUri)
			{

				$ServerProfile.enclosureGroupUri = $EnclosureGroup.uri 

			}

			if ($EnclosureBay -and $null -eq $ServerProfile.enclosureBay)
			{

				$ServerProfile.enclosureBay = $EnclosureBay

			}
			
			# Check to make sure Server Hardware Type supports Firmware Management (OneView supported G7 blade would not support this feature)
			if ($PSBoundParameters['Firmware']) 
			{
				
				"[{0}] Firmware Baseline: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline | Write-Verbose

				if ($ServerHardwareType.capabilities -match "firmwareUpdate" ) 
				{

					$ServerProfile.firmware.manageFirmware         = [bool]$firmware
					$ServerProfile.firmware.forceInstallFirmware   = [bool]$forceInstallFirmware
					$ServerProfile.firmware.firmwareInstallType    = $ServerProfileFirmwareControlModeEnum[$FirmwareInstallMode]
					$ServerProfile.firmware.firmwareActivationType = $ServerProfileFirmareActivationModeEnum[$FirmwareActivationMode]

					if ('FirmwareOffline', 'FirmwareOnlyOfflineMode' -contains $FirmwareInstallMode -and $PSBoundParameters['FirmwareActivateDateTime'])
					{

						$ExceptionMessage = "The specifying a scheduled firmware installation and performing offline method is not supported.  Please choose an online method."
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidFirmwareInstallMode InvalidArgument 'FirmwareActivateDateTime' -TargetType 'Switch' -Message	$ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
					}

					elseif ($FirmwareActivationMode -eq 'Scheduled' -and -not $PSBoundParameters['FirmwareActivateDateTime'])
					{

						$ExceptionMessage = "The specifying a scheduled firmware installation requires the -FirmwareActivateDateTime parameter."
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidFirmwareInstallMode InvalidArgument 'FirmwareActivateDateTime' -TargetType 'Switch' -Message	$ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
					}

					elseif ($FirmwareActivationMode -eq 'Scheduled' -and $PSBoundParameters['FirmwareActivateDateTime'])
					{

						# Convert DateTime to UTC time for the appliance
						"[{0}] Setting firmware activation schedule: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $FirmwareActivateDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ") | Write-Verbose
						$ServerProfile.firmware.firmwareScheduleDateTime = $FirmwareActivateDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

					}					

					# Validating that the baseline value is a string type and that it is an SPP name.
					if (($baseline -is [string]) -and (-not ($baseline.StartsWith('/rest'))) -and ($baseline -match ".iso")) 
					{
						
						try 
						{

							$FirmwareBaslineName = $Baseline.Clone()

							$Baseline = Get-HPOVBaseline -isoFileName $Baseline -ApplianceConnection $ApplianceConnection -ErrorAction SilentlyContinue

							If (-not $_BaseLinePolicy)
							{

								$ExceptionMessage = "The provided Baseline '{0}' was not found." -f $FirmwareBaslineName
								$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'Baseline' -Message $ExceptionMessage
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}
							
							$serverProfile.firmware.firmwareBaselineUri = $baseline.uri
						
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

							$serverProfile.firmware.firmwareBaselineUri = $Baseline.uri

						}

						catch 
						{

							"[{0}] Error caught when looking for Firmware Baseline." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}
			
					# Validating that the baseline value is a string type and that it is the Baseline URI
					elseif (($baseline -is [string]) -and ($baseline.StartsWith('/rest'))) 
					{
				
						Try
						{

							$baselineObj = Send-HPOVRequest -Uri $baseline -appliance $ApplianceConnection

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}		    	            

						if ($baselineObj.category -eq "firmware-drivers") 
						{
						
							"[{0}] Valid Firmware Baseline provided: $($baselineObj.baselineShortName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$serverProfile.firmware.firmwareBaselineUri = $baselineObj.uri 
						
						}

						else 
						{

							$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidBaselineResource ObjectNotFound 'Baseline' -Message "The provided SPP Baseline URI '$($baseline)' is not valid or the correct resource category (expected 'firmware-drivers', received '$($baselineObj.category)'.  Please check the -baseline Parameter value and try again."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

					# Else we are expecting the SPP object that contains the URI.
					elseif (($baseline) -and ($baseline -is [object])) 
					{

						$serverProfile.firmware.firmwareBaselineUri = $baseline.uri
					
					}

					elseif (!$baseline) 
					{
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerHardwareMgmtFeatureNotSupported NotImplemented 'Firmware' -TargetType 'SwitchParameter' -Message "Baseline is required when manage firmware is set to true."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					}

				}

				else 
				{

					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerHardwareMgmtFeatureNotSupported NotImplemented 'Firmware' -TargetType 'SwitchParameter' -Message "`"$($serverHardwareType.name)`" Server Hardware Type does not support Firmware Management."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
				}

			}

			# Exmamine the profile connections Parameter and pull only those connections for this appliance connection
			If ($PSBoundParameters['Connections'] -and $ServerHardwareType.model -notmatch "DL")
			{

				$BootableConnections = New-Object System.Collections.ArrayList

				"[{0}] Getting available Network resources based on SHT and EG." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Get avaialble Networks based on the EG and SHT
				$_AvailableNetworksUri = '{0}?serverHardwareTypeUri={1}&enclosureGroupUri={2}' -f $ServerProfilesAvailableNetworksUri, $ServerHardwareType.uri, $EnclosureGroup.uri

				Try
				{

					$_AvailableNetworkResources = Send-HPOVRequest -Uri $_AvailableNetworksUri -Hostname $ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				ForEach($c in $connections)
				{

					$Message = $null

					# Remove connection Parameters no permitted in Template
					$c = $c | Select-Object -property * -ExcludeProperty ApplianceConnection

					switch (($c.networkUri.Split('\/'))[2])
					{

						'ethernet-networks'
						{
					
							if (-not($_AvailableNetworkResources.ethernetNetworks | Where-Object uri -eq $c.networkUri))
							{

								$Message = "The Ethernet network {0} specified in Connection {1} was not found to be provisioned to the provided Enclosure Group, {2}, and SHT, {3}.  Please verify that the network is a member of an Uplink Set in the associated Logical Interconnect Group." -f (Send-HPOVRequest $c.networkUri -Hostname $ApplianceConnection.Name).name, $c.id, $EnclosureGroup.name, $ServerHardwareType.name

							}

							else
							{

								"[{0}] {1} is available for Connection {2} in this Server Profile request." -f $MyInvocation.InvocationName.ToString().ToUpper(), $c.networkUri, $c.id | Write-Verbose 

								# Add check for iSCsi Initiator Name, to make sure the initiatorName property is set correctly.

							}
					
						}

						'network-sets'
						{
					
							if (-not($_AvailableNetworkResources.networkSets | Where-Object uri -eq $c.networkUri))
							{

								$Message = "The network set {0} specified in Connection {1} was not found to be provisioned to the provided Enclosure Group, {2}, and SHT, {3}.  Please verify that the network is a member of an Uplink Set in the associated Logical Interconnect Group." -f (Send-HPOVRequest $c.networkUri -Hostname $ApplianceConnection.Name).name, $c.id, $EnclosureGroup.name, $ServerHardwareType.name

							}
					
							else
							{

								"[$($MyInvocation.InvocationName.ToString().ToUpper())] {0} is available for Connection {1} in this Server Profile request." -f $c.networkUri, $c.id | Write-Verbose 

							}

						}

						'fc-networks'
						{
					
							if (-not($_AvailableNetworkResources.fcNetworks | Where-Object uri -eq $c.networkUri))
							{

								$Message = "The FC network {0} specified in Connection {1} was not found to be provisioned to the provided Enclosure Group, {2}, and SHT, {3}.  Please verify that the network is a member of an Uplink Set in the associated Logical Interconnect Group." -f (Send-HPOVRequest $c.networkUri -Hostname $ApplianceConnection.Name).name, $c.id, $EnclosureGroup.name, $ServerHardwareType.name

							}
					
							else
							{

								"[$($MyInvocation.InvocationName.ToString().ToUpper())] {0} is available for Connection {1} in this Server Profile request." -f $c.networkUri, $c.id | Write-Verbose 

							}

						}

						'fcoe-networks'
						{
					
							if (-not($_AvailableNetworkResources.fcNetworks | Where-Object uri -eq $c.networkUri))
							{

								$Message = "The FCoE network {0} specified in Connection {1} was not found to be provisioned to the provided Enclosure Group, {2}, and SHT, {3}.  Please verify that the network is a member of an Uplink Set in the associated Logical Interconnect Group." -f (Send-HPOVRequest $c.networkUri -Hostname $ApplianceConnection.Name).name, $c.id, $EnclosureGroup.name, $ServerHardwareType.name

							}
					
							else
							{

								"[$($MyInvocation.InvocationName.ToString().ToUpper())] {0} is available for Connection {1} in this Server Profile request." -f $c.networkUri, $c.id | Write-Verbose 

							}
					
						}

					}

					if ($Message)
					{

						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileConnectionException NetworkResourceNotProvisioned InvalidArgument 'Connections' -TargetType 'PSObject' -Message $Message
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

					}
				
					[void]$ServerProfile.connectionSettings.connections.Add($c)

					if ($null -ne $c.boot -and $c.boot.priority -ne "NotBootable") 
					{

						"[{0}] Found bootable connection ID: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $c.id | Write-Verbose

						[void]$BootableConnections.Add($c.id)

					}
			
				}

				if (-not $PSBoundParameters['ManageBoot'] -and $BootableConnections.count -gt 0) 
				{

					$ExceptionMessage = "Bootable Connections {0} were found, however the -ManageBoot switch Parameter was not provided.  Please correct your command syntax and try again." -f [String]::Join(', ', $BootableConnections.ToArray())
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException BootableConnectionsFound InvalidArgument 'manageBoot' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

				} 
		
			}

			# Check to make sure Server Hardware Type supports Bios Management (OneView supported G7 blade do not support this feature)
			if ($PSBoundParameters['BIOS']) 
			{

				# if (-not ($BiosSettings | Measure-Object).count) 
				# {
					
				# 	$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException BiosSettingsIsNull InvalidArgument 'biosSettings' -TargetType 'Array' -Message "BIOS Parameter was set to TRUE, but no biosSettings were provided.  Either change -bios to `$False or provide valid bioSettings to set within the Server Profile."
				# 	$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
				# }

				# else 
				# {
				
					if ($serverHardwareType.capabilities -match "ManageBIOS" ) 
					{

						if ($BiosSettings.GetEnumerator().Cout -gt 0)
						{
								
							# check for any duplicate keys
							$biosFlag = $false
							$hash = @{}
							$BiosSettings.id | ForEach-Object { $hash[$_] = $hash[$_] + 1 }

							foreach ($biosItem in ($hash.GetEnumerator() | Where-Object {$_.value -gt 1} | ForEach-Object {$_.key} )) 
							{
									
								$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException BiosSettingsNotUnique InvalidOperation 'BiosSettings' -TargetType 'Array' -Message "'$(($ServerHardwareType.biosSettings | where { $_.id -eq $biosItem }).name)' is being set more than once. Please check your BIOS Settings are unique.  This setting might be a depEndency of another BIOS setting/option.  Please check your BIOS Settings are unique.  This setting might be a depEndency of another BIOS setting/option."
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}
						
						}

						$serverProfile.bios.overriddenSettings = $BiosSettings

					}

					else 
					{ 

						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerHardwareMgmtFeatureNotSupported NotImplemented 'New-HPOVServerProfile' -Message "`"$($ServerHardwareType.name)`" Server Hardware Type does not support BIOS Management."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)                
					
					}
					
				# }

			}

			# Manage Secure Boot settings
			if ($PSBoundParameters['SecureBoot'])
			{

				# Check to make sure Server Hardware supports SecureBoot
				if ($ServerHardwareType.capabilities.Contains('SecureBoot') -and $BootMode -eq 'UEFIOptimized')
				{

					$serverProfile.bootMode.secureBoot = $SecureBoot

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
			if (($PSBoundParameters['StorageController']) -and ($ServerHardwareType.capabilities -Contains "ManageLocalStorage" )) 
			{

				# Loop through Controllers provided by user, which should have LogicalDisks attached.
				ForEach ($_Controller in $StorageController)
				{

					# Loop through Controllers provided by user, which should have LogicalDisks attached.
					$__controller = $_Controller.PSObject.Copy()

					$_NewLogicalDisksCollection = New-Object System.Collections.ArrayList

					"[{0}] Processing {1} Controller" -f $MyInvocation.InvocationName.ToString().ToUpper(), $__controller.deviceSlot | Write-Verbose
					
					# Validate the SHT.storageCapabilities controllerModes -> mode, raidLevels -> logicalDrives.raidLevel and maximumDrives -> numPhysicalDrives
					if ($__controller.mode -eq 'RAID' -and ($ServerHardwareType.storageCapabilities.controllerModes -notcontains 'Mixed' -and $ServerHardwareType.storageCapabilities.controllerModes -notcontains 'RAID'))
					{

						$_ExceptionMessage = "Unsupported LogicalDisk policy with Virtual Machine Appliance.  The requested Controller Mode '{0}' is not supported with the expected Server Hardware Type, which only supports '{1}'" -f $__controller.mode, ([System.String]::Join("', '", $ServerHardwareType.storageCapabilities.controllerModes)) 
						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedImportConfigurationSetting InvalidOperation "StorageController" -TargetType 'PSObject' -Message $_ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					# Need to set Gen10+ controller mode to Mixed, especially if ImportConfiguration is requested
					elseif ($__controller.mode -eq 'RAID' -and 'Mixed' -eq $ServerHardwareType.storageCapabilities.controllerModes)
					{

						$__controller.mode = "Mixed"

					}

					$_l = 1

					"[{0}] Storage Controller has {1} LogicalDrives to Process" -f $MyInvocation.InvocationName.ToString().ToUpper(), $__controller.logicalDrives.count | Write-Verbose

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

								$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message ('The ApplianceConnection {0} is not a Synergy Composer.  The LogicalDisk within the StorageController contains a SasLogicalJbod configuration with is only supported with HPE Synergy.' -f $ApplianceConnection)
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

							[void]$serverProfile.localStorage.sasLogicalJBODs.Add($_ld.SasLogicalJBOD)

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

							$_ExceptionMessage = "Unsupported LogicalDisk RAID Level {0} policy with {1} logical disk.  The Server Hardware Type only supports '{2}' RAID level(s). " -f $_ld.raidLevel, $_ld.name, [System.String]::Join("', '", $ServerHardwareType.storageCapabilities.raidLevels) 
							$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedLogicalDriveRaidLevel InvalidOperation "StorageController" -TargetType 'PSObject' -Message $_ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						if ($_ld.numPhysicalDrives -gt $ServerHardwareType.storageCapabilities.maximumDrives)
						{

							$_ExceptionMessage = "Invalid number of drives requested {0}.  The Server Hardware Type only supports a maximum of '{1}'." -f $_ld.numPhysicalDrives, $ServerHardwareType.storageCapabilities.maximumDrives 
							$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedNumberofDrives InvalidOperation "StorageController" -TargetType 'PSObject' -Message $_ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						$_ld = $_ld | Select-Object * -ExcludeProperty SasLogicalJBOD

						[Void]$_NewLogicalDisksCollection.Add($_ld)

						}

						$_l++

					}

					$__controller.logicalDrives = $_NewLogicalDisksCollection

					[void]$serverProfile.localStorage.controllers.Add($__controller)		

				}

			}
			
			# StRM Support
			if ($PSBoundParameters['SANStorage'] -and $ServerHardwareType.capabilities -Contains 'VCConnections')
			{ 

				"[{0}] SAN Storage being requested" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ServerProfile.sanStorage = [pscustomobject]@{
					
					hostOSType        = $ServerProfileSanManageOSType[$HostOsType];
					manageSanStorage  = [bool]$SANStorage;
					volumeAttachments = New-Object System.Collections.ArrayList
				
				}

				$_AllNetworkUrisCollection  = New-Object System.Collections.ArrayList

				# Build list of network URI's from connections
				ForEach ($_Connection in ($ServerProfile.connectionSettings.connections | Where-Object { -not $_.networkUri.StartsWith($NetworkSetsUri) })) 
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

						$_uri = "{0}?networks='{1}'&filter=uri='{2}'" -f $ReachableStoragePoolsUri, ([String]::Join(',', $_AllNetworkUrisCollection.ToArray())), $_Volume.volume.properties.storagePool
						$_VolumeName = $_Volume.volume.properties.name
						$_VolumeUri  = 'StoragePoolUri:{0}' -f $_Volume.volumeStoragePoolUri

					}

					# Provisioned Volume Support
					else
					{

						Try
						{

							$_VolumeObject = Send-HPOVRequest -uri $_Volume.volumeUri -Hostname $_Volume.ApplianceConnection

						}

						catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}	

						$_uri = "{0}?networks='{1}'&filter=name='{2}'" -f $AttachableStorageVolumesUri, ([String]::Join(',', $_AllNetworkUrisCollection.ToArray())), $_VolumeObject.name
						$_VolumeUri = $_Volume.uri
											

					}

					"[{0}] Processing Volume ID: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Volume.id | Write-Verbose 
					"[{0}] Looking to see if volume '{1} ({2})' is attachable" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_VolumeObject.name, $_VolumeUri |Write-Verbose 

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

									$_StorageTypeUri = $EthernetNetworksUri
									
								}

								else
								{

									"[{0}] Looking for FC/FCoE connections." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

									$_StorageTypeUri = $FcNetworksUri

								}

								# Figure out which connections "should" map based on identified storage connectivity type
								[Array]$_ProfileConnections = $ServerProfile.connectionSettings.connections | Where-Object { $_.networkUri.StartsWith($_StorageTypeUri) }

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

										[void]$_Volume.storagePaths.Add($_StoragePath)

									}

								}

								if ($_Volume.storagePaths.Count -eq 0)
								{

									Write-Warning ('No available connections were found that could attach to {0} Storage Volume.  Storage Volumes may not be attached.' -f $_VolumeName)

								}

								[void]$ServerProfile.sanStorage.volumeAttachments.Add($_Volume)

							}

						}

						else
						{
						
							[void]$ServerProfile.sanStorage.volumeAttachments.Add($_Volume)
						
						}

					}

					# No members found, generate exception
					else
					{

						$ExceptionMessage = "'{0}' Volume is not available to be attached to the profile. Please check the volume or available storage pools and try again."  -f $VolumeName
						$ErrorRecord = New-ErrorRecord InvalidOperationException StorageVolumeUnavailableForAttach ResourceUnavailable 'StorageVolume' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				# Check to see if user passed -EvenPathDisable and/or -OddPathDisable Parameter switches
				if ($EvenPathDisabled.IsPresent -or $OddPathDisabled.IsPresent) 
				{
										
					"[{0}] Disable Even Path: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EvenPathDisable.IsPresent | Write-Verbose
					"[{0}] Disable Odd Path: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), $OddPathDisable.IsPresent | Write-Verbose

					# Keep track of Volume Array index
					$v = 0

					foreach ($_vol in $ServerProfile.sanStorage.volumeAttachments) 
					{
						
						# Keep track of Volume Path Array index
						$p = 0

						foreach ($_Path in $_vol.storagePaths) 
						{

							$_IsEnabled = $true

							if ([bool]$OddPathDisabled.IsPresent -and [bool]($_Path.connectionID % 2)) 
							{ 
								
								$_IsEnabled = $false 
							
							}
							
							elseif ([bool]$EvenPathDisabled.IsPresent -and [bool]!($_Path.connectionID % 2)) 
							{ 
								
								$_IsEnabled = $false 

							}

							"[{0})] Setting Connection ID '{1}' path Enabled:  {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Path.connectionID, $_IsEnabled | Write-Verbose

							$serverProfile.sanStorage.volumeAttachments[$v].storagePaths[$p].isEnabled = $_IsEnabled
							$p++

						}

						$v++

					}
					
				}

			}

		}

		"[{0}] Profile: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($ServerProfile | out-string) | Write-Verbose

		if (-not $Passthru.IsPresent)
		{

			"[{0}] Sending request" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{
			
				$Resp = Send-HPOVRequest -Uri $ServerProfilesUri -Method POST -Body $ServerProfile -Hostname $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			Try
			{

				$Resp = $Resp | Wait-HPOVTaskStart

				if ($Resp.taskState -eq 'Error')
				{

					if ($Resp.taskErrors.message -match 'The selected server hardware has health status other than "OK"' -and 
						$PSCmdlet.ShouldProcess($Server.name, 'The selected server hardware has health status other than "OK". Do you wish to override and assign the Server Profile'))
					{

						Try
						{
						
							$_Uri = '{0}?force=all' -f $ServerProfilesUri

							$Resp = Send-HPOVRequest -Uri $_Uri -Method POST -Body $ServerProfile -Hostname $ApplianceConnection
				
						}
				
						Catch
						{
				
							$PSCmdlet.ThrowTerminatingError($_)
				
						}

					}

					else
					{

						$ExceptionMessage = $resp.taskErrors.message
						$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidOperation InvalidOperation 'AsyncronousTask' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

					}				

				}				

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if (-not $PSBoundParameters['Async'])
			{
			
				$Resp = Wait-HPOVTaskComplete -InputObject $Resp -ApplianceConnection $Resp.ApplianceConnection.Name
		
			}

			$Resp

		}

		else
		{

			# Return the server profile object back to the caller, who can directly modify it, and then use Save-HPOVServerProfile
			$ServerProfile

		}
		
	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
	}    
	
}
