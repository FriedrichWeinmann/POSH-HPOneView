function New-HPOVServerProfileAttachVolume 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdLetBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "ServerProfileObject")]
		[Parameter (Mandatory = $false, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateScript ({ $ResourceCategoryEnum.ServerProfile,$ResourceCategoryEnum.ServerProfileTemplate -contains $_.category })]
		[Object]$ServerProfile,

		[Parameter (Mandatory = $false, ParameterSetName = "ServerProfileObject")]
		[Parameter (Mandatory = $false, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[Switch]$PassThru,
		
		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObject")]
		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateNotNullOrEmpty()]
		[Alias ('id')]
		[int]$VolumeID = 1,

        [Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "ServerProfileObject")]
		[ValidateScript({$_ | Where-Object { 'storage-volumes' -contains $_.category}})]
		[Array]$Volume,

		[Parameter (Mandatory, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateNotNullOrEmpty()]
		[object]$Name,

        [Parameter (Mandatory = $false, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateNotNullOrEmpty()]
		[object]$VolumeTemplate,

        [Parameter (Mandatory = $false, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateNotNullOrEmpty()]
		[object]$StoragePool,

		[Parameter (Mandatory = $false, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateNotNullOrEmpty()]
		[object]$SnapshotStoragePool,

		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateNotNullOrEmpty()]
		[object]$StorageSystem,

		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateNotNullOrEmpty()]
		[int64]$Capacity,

		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateSet ('Thin', 'Full', 'ThinDeduplication')]
		[string]$ProvisioningType = 'Thin',

		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[Switch]$Full,

		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[switch]$Permanent,

		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateSet ('NetworkRaid0None','NetworkRaid5SingleParity','NetworkRaid10Mirror2Way','NetworkRaid10Mirror3Way','NetworkRaid10Mirror4Way','NetworkRaid6DualParity')]
		[String]$DataProtectionLevel,

		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[Switch]$EnableAdaptiveOptimization,

        [Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObject")]
		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateSet ("Auto","Manual", IgnoreCase = $true)]
		[Alias ('type')]
		[string]$LunIdType = "Auto",

		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObject")]
		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateRange(0,254)]
		[int]$LunID,

		[Parameter (Mandatory = $false, ParameterSetName = "ServerProfileObject")]
		[Parameter (Mandatory = $false, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateSet ('CitrixXen','CitrixXen7','AIX','IBMVIO','RHEL4','RHEL3','RHEL','RHEV','RHEV7','VMware','Win2k3','Win2k8','Win2k12','Win2k16','OpenVMS','Egenera','Exanet','Solaris9','Solaris10','Solaris11','ONTAP','OEL','HPUX11iv1','HPUX11iv2','HPUX11iv3','SUSE','SUSE9','Inform', IgnoreCase = $true)]
		[Alias ('OS')]
		[string]$HostOStype,

        [Parameter (Mandatory = $false, ParameterSetName = "Default")]
        [Parameter (Mandatory = $false, ParameterSetName = "ServerProfileObject")]
		[Parameter (Mandatory = $false, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[Alias ('Bootable')]
		[switch]$BootVolume,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObject")]
		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateSet ('Auto', 'TargetPorts')]
		[String]$TargetPortAssignment = 'Auto',

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObject")]
		[Parameter (Mandatory = $False, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateNotNullOrEmpty()]
		[Alias ('wwpns')]
		[Array]$TargetAddresses,

        [Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
        [Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "ServerProfileObject")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "ServerProfileObjectEphmeralVol")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)
	
	Begin 
	{

		if ($PSBoundParameters['Full'])
		{

			Write-Warning 'The -Full switch is deprecated, and no longer be used.  Please use the -ProvisioningType parameter to define Full, Thin or ThinDeduplication.'
			$PSBoundParameters.Add('ProvisioningType', $StorageVolumeProvisioningTypeEnum['Full'])
			
		}

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		If (-not($PSBoundParameters['Volume']))
		{

			$PipelineInput = $True

		}

		else
		{

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

		}        
		
		if ($LunIdType -eq "Manual" -and (-not($PSBoundParameters.ContainsKey("LunId"))))
		{ 
		
			$ErrorRecord = New-ErrorRecord ArgumentNullException ParametersNotSpecified InvalidArgument 'New-HPOVServerProfileAttachVolume' -Message "'Manual' LunIdType was specified, but no LUN ID value was provided.  Please include the -LunId Parameter or a value in the Parameters position and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($LunIdType -eq "Auto" -and $PSBoundParameters.ContainsKey("LunId")) 
		{ 
		
			$ErrorRecord = New-ErrorRecord ArgumentException ParametersSpecifiedCollision InvalidArgument 'New-HPOVServerProfileAttachVolume' -Message "'Auto' LunIdType was specified and a specific LUN ID were provided.  Please either specify -LunIdType 'Manual' or omit the -LunId Parameter and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# If volume Parameter is passed as URI validate that only one appliance connection is present
		if ($PSBoundParameters['Volume']) 
		{

			if (($Volume -is [String] -and $Volume.StartsWith($StorageVolumesUri)) -or ($Volume -is [String] -and $Volume.StartsWith("/rest/"))) 
			{

				"[{0}] Volume URI was provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				if(-not($ApplianceConnection))
				{

					"[{0}] No Appliance connections identified with volume URI Parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Volume' -Message "The Volume Parameter contains a URI and requires the ApplianceConnection Parameter."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

		}

		# If StoragePool Parameter is present and passed as URI validate only one appliance connection is present
		if ($PSBoundParameters['StoragePool']) 
		{
			
			if (($StoragePool -is [string] -and $StoragePool.StartsWith($StoragePoolsUri)) -or ($StoragePool -is [string] -and $StoragePool.StartsWith("/rest"))) 
			{

				"[{0}] Storage Pool URI provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StoragePool | Write-Verbose

				if ($ApplianceConnection.Count -ne 1)
				{

					"[{0}] Multiple appliance connections identified with storage pool URI Parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'New-HPOVServerProfileAttachVolume' -Message "The StoragePool URI Parameter is invalid with multiple appliance connections."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
				}

			}

		}

		if ($PSBoundParameters['SnapshotStoragePool']) 
		{
			
			if (($SnapshotStoragePool -is [string] -and $SnapshotStoragePool.StartsWith($StoragePoolsUri)) -or ($SnapshotStoragePool -is [string] -and $SnapshotStoragePool.StartsWith("/rest"))) 
			{

				"[{0}] Storage Pool URI provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $SnapshotStoragePool | Write-Verbose

				if ($ApplianceConnection.Count -ne 1)
				{

					"[{0}] Multiple appliance connections identified with storage pool URI Parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'New-HPOVServerProfileAttachVolume' -Message "The StoragePool URI Parameter is invalid with multiple appliance connections."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

		}

		if ($PSBoundParameters['ServerProfile'])
		{

			if ($ServerProfile -isnot [PSCustomObject])
			{

				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException UnsupportedServerHardwareResource InvalidArgument 'ServerProfile' -TargetType $ServerProfile.GetType().Name -Message ("The provided Server Profile {0} is not an Object.  Please provide a Server Profile object." -f $ServerProfile)
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

			}

		}

		# Initialize collection to hold multiple volume attachments objects
		$_volumeAttachments = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PSBoundParameters['Volume']) 
		{

			ForEach ($_vol in $Volume)
			{

				$volumeAttachment = NewObject -ServerProfileStorageVolume

				"[{0}] Processing Volume: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), (ConvertTo-Json $_vol -Depth 99) | Write-Verbose

				$volumeAttachment.volumeUri              = $_vol.uri
				$volumeAttachment.volumeStoragePoolUri   = $_vol.storagePoolUri

				if ($PSBoundParameters['SnapshotStoragePool'])
				{

					$volumeAttachment | Add-Member -NotePropertyName snapshotPool -NotePropertyValue $SnapshotStoragePool.uri
					
				}

				$volumeAttachment.volumeStorageSystemUri = $_vol.storageSystemUri

				if ($PSBoundParameters['VolumeID'])
				{

					$volumeAttachment.id = $VolumeID

				}
				
				if ($LunIdType -ne 'Auto')
				{

					$volumeAttachment.lunType = $LunIdType
					$volumeAttachment.lun     = $LunID

				}

				if ($PSBoundParameters['BootVolume'])
				{

					if ($ServerProfile -and ($ServerProfile.sanStorage.volumeAttachments | Where-Object bootVolumePriority -eq 'Primary'))
					{

						$_Message = 'The Server Profile already had a Bootable Device, {0}.  Please omit the -BootVolume Parameter switch or set the "bootVolumePriority" poperty of the Volume Attachment to "NotBootable".' -f ($ServerProfile.sanStorage.volumeAttachments | Where-Object bootVolumePriority -eq 'Bootable').id
						$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException MultipleBootVolumesNotSupported InvalidOperation 'BootVolume' -TargetType 'SwitchParameter' -Message $_Message
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if (-not ($_volumeAttachments | Where-Object bootVolumePriority -eq 'Primary'))
					{

						"[{0}] Setting Volume as Boot Volume: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_vol.volumeName | Write-Verbose

						$volumeAttachment.bootVolumePriority = 'Primary'

					}

					else
					{

						$_ConflictVolume = $Volume | Where-Object uri -contains ($_volumeAttachments | Where-Object bootVolumePriority -eq 'Primary').volumeUri

						$_Message = 'An existing volume is already marked as a Bootable Device, {0}.  Multiple Storage Volumes via Pipeline or Parameter input along with -BootVolume Parameter is not supported.' -f $_ConflictVolume.volumeName
						$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException MultipleBootVolumesNotSupported InvalidOperation 'BootVolume' -TargetType 'SwitchParameter' -Message $_Message
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
						
					}

				}

				$volumeAttachment.ApplianceConnection = $_vol.ApplianceConnection

				[void]$_volumeAttachments.Add($volumeAttachment)

			}

		}

		# Ephmeral Volume Support
		else
		{

			"[{0}] Creating dynamic volume attach object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
			$volumeAttachment = NewObject -EphemeralStorageVolume

			if ($PSBoundParameters['StoragePool']) 
			{

				switch ($StoragePool.GetType().Name) 
				{

					"String" 
					{ 
						
						if ($StoragePool.StartsWith($StoragePoolsUri)) 
						{
							
							"[{0}] Storage Pool URI provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),  $StoragePool | Write-Verbose

							Try
							{
									
								$sp = Send-HPOVRequest $StoragePool -appliance $ApplianceConnection

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}
							
						}

						elseif ($StoragePool.StartsWith("/rest/")) 
						{
							
							"[{0}] Invalid storage pool URI provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StoragePool | Write-Verbose

							$ErrorRecord = New-ErrorRecord ArgumentException InvalidStoragePoolURI InvalidArgument 'StoragePool' -Message "The provided URI value for the -StoragePool Parameter '$StroagePool' is invalid.  The StoragePool URI must Begin with /rest/storage-pools.  Please check the value and try again."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						else 
						{
							
							if ($StorageSystem) 
							{
									
								# If both storagepool and storagesystem were provided, look that up first
								Try
								{
									
									$sp = Get-HPOVStoragePool -poolName $StoragePool -storageSystem $StorageSystem -appliance $ApplianceConnection -ErrorAction Stop

								}

								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}
								
							}

							else 
							{

								Try
								{

									# If both storagepool and storagesystem were provided, look that up first
									$sp = Get-HPOVStoragePool -poolName $StoragePool -appliance $ApplianceConnection -ErrorAction Stop

								}

								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}

								if ($sp -and $sp.count -gt 1) 
								{

									# Generate Error that StoragePool name is not unique and must supply the StorageSystem as well.
									"[{0}] {1} StoragePool resource found" -f $MyInvocation.InvocationName.ToString().ToUpper(), $sp.count | Write-Verbose

									$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException MultipleStoragePoolsFound InvalidResult 'New-HPOVServerProfileAttachVolume' -Message "Multiple StoragePool resources found with the name '$StoragePool'.  Please use the -StorageSystem Parameter to specify the Storage System the Storage Pool is to be used."
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

							}
							
						}
						
					}

					'StoragePool'
					{

						$sp = $StoragePool

					}

					default
					{ 
						
						# Validate the object
						if ($StoragePool.category -eq 'storage-pools') 
						{ 
								
							$sp = $StoragePool 
							
						}

						else 
						{

							$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStoragePoolCategory InvalidArgument 'StoragePool' -Message "Invalid -StoragePool Parameter value.  Expected Resource Category 'storage-pools', received '$($VolumeTemplate.category)'."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}              
						
					}

				}

				# Get the associated storage system family
				try
				{

					"[{0}] Get storage system family associated with the provided Storage Pool." -f $MyInvocation.InvocationName.ToString().ToUpper(), $sp.count | Write-Verbose
					$StorageSystem = Send-HPOVRequest -Uri $sp.storageSystemUri -Hostname $sp.ApplianceConnection

				}

				catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				"[{0}] Get storage system family associated with the provided Storage Pool." -f $MyInvocation.InvocationName.ToString().ToUpper(), $sp.count | Write-Verbose

				# Get Storage System Root Volume Template
				Try
				{
					
					"[{0}] Get storage system root volume template." -f $MyInvocation.InvocationName.ToString().ToUpper(), $sp.count | Write-Verbose

					$_Uri = '{0}/templates?filter=isRoot%20EQ%20True' -f $StorageSystem.uri
					$_StorageSystemRootVolumeTemplate = Send-HPOVrequest -Uri $_Uri -Hostname $sp.ApplianceConnection

					"[{0}] Storage System root volume template URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_StorageSystemRootVolumeTemplate.members.uri | Write-Verbose
					$_VolumeTemplateUri = $_StorageSystemRootVolumeTemplate.members.uri

					$VolumeTemplate = Send-HPOVrequest -Uri $_VolumeTemplateUri -Hostname $sp.ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($PSBoundParameters['VolumeTemplate'])
			{

				if ($VolumeTemplate.category -ne 'storage-volume-templates')
				{

					$ExceptionMessage = "The value provided for VolumeTemplate is not the allowed resource type, storage-volume-templates."
					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeTemplateResourceException InvalidStorageVolumeTemplateResource InvalidArgument 'VolumeTemplate' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				"[{0}] Storage Volume Template provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.name | Write-Verbose
				"[{0}] Storage Volume Template family: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.family | Write-Verbose

				$_VolumeTemplateUri = $VolumeTemplate.uri

				Try
				{

					"[{0}] Getting Storage Pool from SVT" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					$StoragePool = Send-HPOVRequest -Uri $VolumeTemplate.storagePoolUri -Hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				Try
				{

					"[{0}] Getting Storage System from Storage Pool" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$StorageSystem = Send-HPOVRequest -Uri $StoragePool.storageSystemUri -Hostname $ApplianceConnection
					
				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
			}

			$_Family = $StorageSystem.family

			if ($StorageSystem.family -eq 'StoreVirtual' -and -not $PSBoundParameters['DataProtectionLevel'])
			{

				$ExceptionMessage = "The DataProtectionLevel parameter is required, as the Storage System associated with the Storage Pool {0} is a StoreVirtual system." -f $StoragePool.name
				$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStoragePoolCategory InvalidArgument 'StoragePool' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			elseif ($StorageSystem.family -eq 'StoreVirtual')
			{

				"[{0}] Will create StoreVirtual Ephemeral volume." -f $MyInvocation.InvocationName.ToString().ToUpper(), $sp.count | Write-Verbose

				$volumeAttachment.volume.properties = NewObject -StoreVirtualEphemeralVolumeProperties
				$volumeAttachment.volume.properties.dataProtectionLevel = $DataProtectionLevelEnum[$DataProtectionLevel]
				$volumeAttachment.volume.properties.isAdaptiveOptimizationEnabled = [bool]$PSboundParameters['EnableAdaptiveOptimization']

			}

			else
			{

				"[{0}] Will create StoreServe Ephemeral volume." -f $MyInvocation.InvocationName.ToString().ToUpper(), $sp.count | Write-Verbose

				$volumeAttachment.volume.properties = NewObject -StoreServeEphemeralVolumeProperties

			}

			switch ($volumeAttachment.volume.properties.PSObject.Properties.name)
			{

				'name'
				{

					"[{0}] Setting volume name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose
					$volumeAttachment.volume.properties.name = $Name

				}

				'description'
				{

					"[{0}] Setting volume description: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Description | Write-Verbose
					$volumeAttachment.volume.properties.description = $Description

				}

				'storagePool'
				{

					# If SVT enforces, set it
					if ($VolumeTemplate.properties.storagePool.meta.locked -or -not $PSBoundParameters['StoragePool'])
					{

						"[{0}] Volume Template enforces StoragePool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.storagePool.default | Write-Verbose

						$volumeAttachment.volume.properties.storagePool = $VolumeTemplate.properties.storagePool.default
						
					}

					else
					{

						"[{0}] Setting StoragePool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StoragePool.uri | Write-Verbose

						$volumeAttachment.volume.properties.storagePool = $StoragePool.uri

					}

				}

				'snapshotPool'
				{

					if ($_Family -ne 'StoreVirtual')
					{

						"[{0}] Family is StoreServ, attempting to set snapshot pool" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						# If SVT enforces, set it
						if ($VolumeTemplate.properties.snapshotPool.meta.locked)
						{

							"[{0}] Volume Template enforces Snapshot StoragePool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.snapshotPool.default | Write-Verbose

							$volumeAttachment.volume.properties.snapshotPool = $VolumeTemplate.properties.snapshotPool.default
							
						}

						else
						{

							if ($PSBoundParameters['SnapshotStoragePool'])
							{

								if ($SnapshotStoragePool -is [String])
								{

									try
									{

										$SnapshotStoragePool = GetStoragePool -Name $StoragePool -StorageSystem $StorageSystem -ApplianceConnection $ApplianceConnection

									}

									Catch
									{

										$PSCmdlet.ThrowTerminatingError($_)

									}

								}

								"[{0}] Setting StoragePool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_StoragePool.uri | Write-Verbose
								
								$volumeAttachment.volume.properties.snapshotPool = $SnapshotStoragePool.uri

							}

							else
							{

								"[{0}] Setting StoragePool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_StoragePool.uri | Write-Verbose

								$volumeAttachment.volume.properties.snapshotPool = $StoragePool.uri

							}						

						}

					}

					else
					{

						if ($PSBoundParameters['SnapshotStoragePool'])
						{

							$ExceptionMessage = "The Storage System family of the Storage Pool, {0}, is not a StoreServ system.  Snapshots are only supported with StoreServ class of storage systems." -f $_StoragePool.name
							$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'SnapShotStoragePool' -TargetType $SnapShotStoragePool.gettype().Name -Message $ExceptionMessage
						
							# Generate Terminating Error
							$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

						}

					}

				}

				'dataProtectionLevel'
				{

					if ($_Family -eq 'StoreVirtual')
					{

						if ($VolumeTemplate.properties.dataProtectionLevel.meta.locked -or (-not $PSBoundParameters['DataProtectionLevel'] -and -not $VolumeTemplate.properties.dataProtectionLevel.meta.locked))
						{

							"[{0}] Volume Template enforces DataProtectionLevel: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.dataProtectionLevel.default | Write-Verbose

							$volumeAttachment.volume.properties.dataProtectionLevel = $VolumeTemplate.properties.dataProtectionLevel.default

						}
						
						else
						{

							$_DataProtectionLevel = $VolumeTemplate.properties.dataProtectionLevel.enum | Where-Object { $_ -eq $DataProtectionLevel }

							if (-not $_DataProtectionLevel)
							{

								$ExceptionMessage = "The requested data protection level, {0}, is not supported with the storage system. Please correctthe value with one of the following options: {1}" -f $DataProtectionLevel, ([String]::Join(', ', $VolumeTemplate.properties.dataProtectionLevel.enum))
								$ErrorRecord = New-ErrorRecord ArgumentException UnsupportedProtectionLevelValue InvalidArgument 'DataProtectionLevel' -TargetType $DataProtectionLevel.gettype().Name -Message $ExceptionMessage
							
								# Generate Terminating Error
								$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

							}

							$volumeAttachment.volume.properties.dataProtectionLevel = $_DataProtectionLevel

						}

					}

					else
					{

						if ($PSBoundParameters['DataProtectionLevel'])
						{

							$ExceptionMessage = "The Storage System family of the Storage Pool, {0}, is not a StoreVirtual system.  Data Protection for volumes is defined within the StoreServ Common Provisioning Group (CPG)." -f $_StoragePool.name
							$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'DataProtectionLevel' -TargetType $DataProtectionLevel.gettype().Name -Message $ExceptionMessage
						
							# Generate Terminating Error
							$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

						}

					}

				}

				'isAdaptiveOptimizationEnabled'
				{

					if ($_Family -eq 'StoreVirtual')
					{

						if ($VolumeTemplate.properties.isAdaptiveOptimizationEnabled.meta.locked -or (-not $PSBoundParameters['EnableAdaptiveOptimization'] -and -not $VolumeTemplate.properties.isAdaptiveOptimizationEnabled.meta.locked))
						{

							"[{0}] Volume Template enforces AdaptiveOptimizationEnabled: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.isAdaptiveOptimizationEnabled.default | Write-Verbose

							$volumeAttachment.volume.properties.isAdaptiveOptimizationEnabled = $VolumeTemplate.properties.isAdaptiveOptimizationEnabled.default

						}
						
						else
						{

							$volumeAttachment.volume.properties.isAdaptiveOptimizationEnabled = $EnableAdaptiveOptimization.IsPresent

						}

					}

					else
					{

						if ($PSBoundParameters['EnableAdaptiveOptimization'])
						{

							$ExceptionMessage = "The Storage System family of the Storage Pool, {0}, is not a StoreVirtual system.  Adaptive Optimization is only available with StoreVirtual." -f $_StoragePool.name
							$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'EnableAdaptiveOptimization' -TargetType $EnableAdaptiveOptimization.gettype().Name -Message $ExceptionMessage
						
							# Generate Terminating Error
							$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

						}

					}

				}

				'size'
				{

					if ($VolumeTemplate.properties.size.meta.locked -or (-not $PSBoundParameters['Capacity'] -and -not $VolumeTemplate.properties.size.meta.locked))
					{

						"[{0}] Volume Template enforces volume capacity: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.size.default | Write-Verbose

						$volumeAttachment.volume.properties.size = $VolumeTemplate.properties.size.default

					}
					
					else
					{

						$volumeAttachment.volume.properties.size = [int64]$Capacity * 1GB

					}

				}

				'provisioningType'
				{

					if ($VolumeTemplate.properties.provisioningType.meta.locked -or (-not $PSBoundParameters['Full'] -and -not $PSBoundParameters['ProvisioningType'] -and -not $VolumeTemplate.properties.provisioningType.meta.locked))
					{

						"[{0}] Volume Template enforces volume provisioningType: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.provisioningType.default | Write-Verbose
						$volumeAttachment.volume.properties.provisioningType = $VolumeTemplate.properties.provisioningType.default

					}
					
					else
					{

						if ($PSBoundParameters['ProvisioningType'])
						{

							"[{0}] Setting volume provisioningType via ProvisioningType param: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StorageVolumeProvisioningTypeEnum[$ProvisioningType] | Write-Verbose

							$volumeAttachment.volume.properties.provisioningType = $StorageVolumeProvisioningTypeEnum[$ProvisioningType]

						}

						elseif ($PSBoundParameters['Full'])
						{

							"[{0}] Setting volume provisioningType via full param: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StorageVolumeProvisioningTypeEnum['Full'] | Write-Verbose

							$volumeAttachment.volume.properties.provisioningType = $StorageVolumeProvisioningTypeEnum['Full']

						}

						else
						{

							"[{0}] Setting volume provisioningType via not full param: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StorageVolumeProvisioningTypeEnum['Thin'] | Write-Verbose

							$volumeAttachment.volume.properties.provisioningType = $StorageVolumeProvisioningTypeEnum['Thin']

						}

					}

				}

			}

			"[{0}] Setting templateUri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_VolumeTemplateUri | Write-Verbose
			$volumeAttachment.volume.templateUri = $_VolumeTemplateUri

			$volumeAttachment.volume.isPermanent = [bool]$PSBoundParameters['Permanent']

			if (-not($PSBoundParameters['VolumeID']) -and $ServerProfile)
			{

				"[{0}] No VolumeID value provided.  Getting next volume id value." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$id = 1

				$Found = $false

				While (-not($Found))
				{

					if (-not($ServerProfile.sanStorage.volumeAttachments | Where-Object id -eq $id))
					{

						$VolumeID = $id

						$Found = $true

					}

					$id++

				}

			}

			$volumeAttachment.id = $VolumeID

			if ($LunIdType -ne 'Auto')
			{

				$volumeAttachment.lunType = $LunIdType
				$volumeAttachment.lun     = $LunID

			}

			if ($PSBoundParameters['BootVolume'])
			{

				if (-not($_volumeAttachments | Where-Object bootVolumePriority))
				{

					"[{0}] Setting Volume as Boot Volume: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $volumeAttachment.volumeName | Write-Verbose

					$volumeAttachment.bootVolumePriority = 'Primary'

				}

				else
				{

					$_Message = 'An existing volume is already marked as a Bootable Device, {0}.  Multiple Storage Volumes via Pipeline or Parameter input along with -BootVolume Parameter is not supported.' -f [String]::Join(' ', ($_volumeAttachments | Where-Object bootVolumePriority -eq 'Primary').volumeName)
					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException MultipleBootVolumesNotSupported InvalidOperation 'BootVolume' -TargetType 'SwitchParameter' -Message $_Message
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			$volumeAttachment.ApplianceConnection = $_Connection

			[void]$_volumeAttachments.Add($volumeAttachment)

		}

		"[{0}] VolumeAttachments Added to collection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_volumeAttachments.Count | Write-Verbose

	}

	End 
	{

		if ($PSBoundParameters['ServerProfile'])
		{

			$_ServerProfile = $ServerProfile.PSObject.Copy()

			# Validate Server Profile and Server Hardware resource supports StRM operations
			Try
			{

				"[{0}] Checking SHT for SanStorage operation support" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_SHTResource = Send-HPOVRequest -uri $ServerProfile.serverHardwareTypeUri -Hostname $ServerProfile.ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if (-not [RegEx]::Match($_SHTResource.model,'BL|WS|SY', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Success)
			{
					
				$ExceptionMessage = "The provided Server Profile {0} is not assigned to a supported Server Hardware Type Resource, {1}.  Only WS/BL/SY Gen 8/Gen 9 or newer are supported." -f $ServerProfile.name, $_SHTResource.model
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException UnsupportedServerHardwareResource InvalidArgument 'ServerProfile' -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

			}

			# Validate Server Profile has SanStorage already set.  If not, set it and add the necessary properties.
			if (-not($ServerProfile.sanStorage.manageSanStorage))
			{

				"[{0}] Server Profile does not have manageSanStorage property set to True." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Generate Error that HostOSType is required
				if (-not($PSBoundParameters['HostOsType']))
				{

					$ExceptionMessage = "The -HostOSType parmater is required when the Server Profile is not already configured for managing SAN Storage.  Please specify the HostOSType Parameter in your call."
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException MissingHostOSTypeParameterValue InvalidArgument 'ServerProfile' -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

				}

				$_ServerProfile.sanStorage = [PSCustomObject]@{
						
					hostOSType        = $ServerProfileSanManageOSType[$HostOsType];
					manageSanStorage  = $true;
					volumeAttachments = New-Object System.Collections.ArrayList
					
				}

			}

			# Rebuild VolumeAttachments property to be an ArrayList
			else
			{

				if ($ServerProfile.sanStorage.volumeAttachments.Count -gt 0)
				{

					"[{0}] Rebuilding Server Profile Volume Attachment object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_ExistingVols = $ServerProfile.sanStorage.volumeAttachments.Clone()					

					$_ServerProfile.sanStorage.volumeAttachments = New-Object System.Collections.ArrayList

					$_ExistingVols | ForEach-Object {

						if ($_.volumeUri -contains $_volumeAttachments.volumeUri)
						{

							Try
							{

								$_ExistingVolume = Send-HPOVRequest -Uri $_.volumeUri -Hostname $ServerProfile.ApplianceConnection

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

							[void]$_volumeAttachments.Remove($_)
							$ExceptionMessage = 'Storage Volume {0} is already attached at ID {1}.' -f $_ExistingVolume.name, $_.id
							$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException StorageVolumeAlreadyAttached ResourceExists 'Volume' -Targettype 'PSObject' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						[void]$_ServerProfile.sanStorage.volumeAttachments.Add($_)

					}

				}

				else
				{

					$_ServerProfile.sanStorage.volumeAttachments = New-Object System.Collections.ArrayList

				}

			}

			$_AllNetworkUrisCollection  = New-Object System.Collections.ArrayList

			# Build list of network URI's from connections
			ForEach ($_Connection in ($ServerProfile.connectionSettings.connections | Where-Object { -not $_.networkUri.StartsWith($NetworkSetsUri)})) 
			{

				[void]$_AllNetworkUrisCollection.Add($_Connection.networkUri)

			}
					
			"[{0}] Volumes to Process {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_volumeAttachments | out-string) | Write-Verbose 
					
			$i = 0
			
			# // TODO: This causes an exception when using SVT to create volume attachment
			# Process volumes being passed
			foreach ($_volume in $_volumeAttachments) 
			{  

				if (-not [System.String]::IsNullOrWhiteSpace($_volume.volumeUri))
				{

					Try
					{

						
						$_VolumeObject = Send-HPOVRequest -Uri $_volume.volumeUri -Hostname $ServerProfile.ApplianceConnection.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				"[{0}] Processing '{1}' Storage Volume (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_volume.name, $_volumeAttachments.count | Write-Verbose

				"[{0}] Getting list of attachable storage volumes" -f $MyInvocation.InvocationName.ToString().ToUpper()| Write-Verbose
			
				# Get list of available storage system targets and the associated Volumes based on the EG and SHT provided
				Try
				{

					$_uri = "{0}?networks='{1}'" -f $AttachableStorageVolumesUri, ([String]::Join(',', $_AllNetworkUrisCollection.ToArray()))

					if (-not [System.String]::IsNullOrWhiteSpace($_volume.volumeUri))
					{

						$_uri += "&filter=name='{0}'" -f $_VolumeObject.name

					}

					$_AttachableStorageVolumes = (Send-HPOVRequest -Uri $_uri -Hostname $ServerProfile.ApplianceConnection.Name).members
				
				}
				
				Catch
				{
				
					$PSCmdlet.ThrowTerminatingError($_)
				
				}
				
				"[{0}] Attachable Storage Volumes: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_AttachableStorageVolumes | out-string) | Write-Verbose
				
				# Error on no available storage systems
				if (-not $_AttachableStorageVolumes)
				{
				
					$ExceptionMessage = "Unable to find attachable storage volumes for '{0}' Server Profile with available connection networks and '{1}'.   Verify the Server Profile contains at least 1 Connection that is mapped to the storage system the volume is provisioned from." -f $ServerProfile.name, [String]::Join(',', $_AllNetworkUrisCollection.ToArray())
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException NoAvailableStorageSystems ObjectNotFound 'SANStorage' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)  
				
				}

				if (-not $_volume.id)
				{

					"[{0}] No VolumeID value provided.  Getting next volume id value." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$id = 1

					$Found = $false

					While (-not $Found)
					{

						if (-not($_ServerProfile.sanStorage.volumeAttachments | Where-Object id -eq $id))
						{

							$_volume.id = $id

							$Found = $true

						}

						$id++

					}

				}

				# If the storage paths array is null, Process connections to add mapping
				if (-not $_volume.storagePaths)
				{

					"[{0}] Storage Paths value is Null. Building connection mapping." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# Static Volume, must have volumeUri attribute present to be valid
					if ($_volume.volumeUri) 
					{
											   
						# validate volume is attachable
						$_AttachableVolFound = $_AttachableStorageVolumes | Where-Object uri -eq $_volume.volumeUri

						# If it is available, continue Processing
						if ($_AttachableVolFound) 
						{
					
							"[{0}] '{1} ({2})' volume is attachable" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_AttachableVolFound.uri, $_AttachableVolFound.name | Write-Verbose

							# Check to make sure profile connections exist.
							if ($null -ne $_ServerProfile.connectionSettings.connections)
							{

								"[{0}] Profile has connections" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
									
								# Loop through profile connections
								$found = 0

								foreach ($_volNetwork in $_AttachableVolFound.reachableNetworks) 
								{

									$_StoragePath = NewObject -StoragePath

									# Looking for $volConnection
									$_ProfileConnection = $_ServerProfile.connectionSettings.connections | Where-Object networkUri -eq $_volNetwork

									if ($_ProfileConnection) 
									{

										# Keep track of the connections found for error reporting later
										$found++

										"[{0}] Mapping connection ID '{1}' -> volume ID '{2}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ProfileConnection.id, $_volumeAttachments[$i].id | Write-Verbose

										$_StoragePath.connectionId = $_ProfileConnection.id
										$_StoragePath.isEnabled = $True

										if ($PSBoundParameters['TargetAddresses'])
										{

											"[{0}] Getting FC network to get associated SAN." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

											# $_uri = "{0}/reachable-ports?query=expectedNetworkUri EQ '{1}'" -f $_VolumeToStorageSystem.uri, $profileConnection.networkUri
											$_StoragePath.targetSelector = 'TargetPorts'

											Try
											{

												$_ServerProfileConnectionNetwork = Send-HPOVRequest -Uri $_ProfileConnection.networkUri -Hostname $ServerProfile.ApplianceConnection

											}

											Catch
											{

												$PSCmdlet.ThrowTerminatingError($_)

											}

											$_StorageSystemExpectedMappedPorts = $_AvailStorageSystems.ports | Where-Object expectedSanUri -eq $_ServerProfileConnectionNetwork.managedSanUri

											ForEach ($_PortID in $TargetAddresses)
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

										[void]$_volume.storagePaths.Add($_StoragePath)

									}

								}

								if (-not ($found)) 
								{

									# Generate non-terminating error and continue
									$ExceptionMessage = "Unable to find a Profile Connection that will map to '{0}'. Creating server profile resource without Volume Connection Mapping."  -f $_VolumeName
									$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException NoProfileConnectionsMapToVolume ObjectNotFound 'Volumes' -Message $ExceptionMessage
									$PSCmdlet.WriteError($ErrorRecord)

								}
									
							}

							# Else, generate an error that at least one FC connection must exist in the profile in order to attach volumes.
							else 
							{

								$ExceptionMessage = "The profile does not contain any Network Connections.  The Profile must contain at least 1 Connection to attach Storage Volumes.  Use the New-HPOVServerProfileConnection helper cmdlet to create 1 or more connections and try again." 
								$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException NoProfileConnections ObjectNotFound 'Connections' -Message $ExceptionMessage
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

						}
					
						elseif (-not $_AttachableVolFound)
						{ 
							
							$ExceptionMessage = "'{0}' Volume is not available to be attached to the profile. Please check the volume and try again." -f $_VolumeObject.Name
							$ErrorRecord = New-ErrorRecord InvalidOperationException StorageVolumeUnavailableForAttach ResourceUnavailable 'ServerProfile' -TargetType 'PSObject'  -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

					# Ephemeral volume support
					elseif ($null -eq $_Volume.volumeUri -and $_Volume.volume.properties.storagePool)
					{

						"[{0}] No volumeUri, ephemeral volume request." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						# Check to make sure profile connections exist.
						if ($ServerProfile.connectionSettings -and $ServerProfile.connectionSettings.connections.functionType -contains "FibreChannel") 
						{

							"[{0}] Profile has connections" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							# Process available storage system and available FC networks
							$_StorageSystemVolCreate = $_AvailStorageSystems | Where-Object storageSystemUri -eq $_volume.volumeStorageSystemUri

							if ($_StorageSystemVolCreate) 
							{
										
								"[{0}] Available Storage System targets: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_StorageSystemVolCreate.storageSystemUri -join ", ") | Write-Verbose 

								# Loop through profile connections
								$found = 0

								foreach ($_storageSystemNetworks in $_StorageSystemVolCreate.availableNetworks) 
								{

									$_ProfileConnection = $_ServerProfile.connectionSettings.connections | Where-Object networkUri -eq $_storageSystemNetworks.uri

									if ($_ProfileConnection) 
									{

										# Keep track of the connections found for error reporting later
										$found++

										"[{0}] Mapping connection ID '{1}' -> volume ID '{2}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ProfileConnection.id, $_volumeAttachments[$i].id | Write-Verbose

										$_StoragePath.connectionId = $_ProfileConnection.id
										$_StoragePath.isEnabled = $True

										if ($PSBoundParameters['TargetAddresses'])
										{

											"[{0}] Getting FC network to get associated SAN." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

											$_StoragePath.targetSelector = 'TargetPorts'

											Try
											{

												$_ServerProfileConnectionNetwork = Send-HPOVRequest -Uri $_ProfileConnection.networkUri -Hostname $_ServerProfile.ApplianceConnection

											}

											Catch
											{

												$PSCmdlet.ThrowTerminatingError($_)

											}

											$_StorageSystemExpectedMappedPorts = $_AvailStorageSystems.ports | Where-Object expectedSanUri -eq $_ServerProfileConnectionNetwork.managedSanUri

											ForEach ($_PortID in $TargetAddresses)
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

										[void]$_volume.storagePaths.Add($_StoragePath)

									}

								}

								if (-not($found))
								{

									# Generate non-terminating error and continue
									$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException NoProfileConnectionsMapToVolume ObjectNotFound 'New-HPOVServerProfile' -Message "Unable to find a Profile Connection that will map to '$($_volume.id)'. Creating server profile resource without Volume Connection Mapping." 

									$PSCmdlet.WriteError($ErrorRecord)

									
								}

							}

							else 
							{

								$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException StorageSystemNotFound ObjectNotFound 'Volume' -TargetType 'PSObject' -Message "The provided Storage System URI '$($_volume.volumeStorageSystemUri)' for the ephemeral volume '$($_volume.name)' was not found as an available storage system." 
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}
										
						}

						# Else, generate an error that at least one FC connection must exist in the profile in order to attach volumes.
						else 
						{

							$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException NoProfileConnections ObjectNotFound 'ServerProfile' -TargetType 'PSObject' -Message "The profile does not contain any Network Connections.  The Profile must contain at least 1 FC Connection to attach Storage Volumes.  Use the New-HPOVServerProfileConnection helper cmdlet to create 1 or more connections and try again." 
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}
 
				}

				"[{0}] Storage Volume Object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), (ConvertTo-Json $_volume -depth 99) | Write-Verbose

				"[{0}] Attaching '{1}' Storage Volume to volumeAttachments collection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_AttachableVolFound.name | Write-Verbose

				[void]$_ServerProfile.sanStorage.volumeAttachments.Add($_volume)

				$i++

			}

			# Workaround to remove a possible NULL entry in the volumeAttachments collection
			[void]$_ServerProfile.sanStorage.volumeAttachments.Remove($null)

			if (-not $PSBoundParameters['PassThru'])
			{

				"[{0}] Updating Server Profile with new Storage Volume Attachments: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerProfile.name | Write-Verbose 

				Try
				{

					$_Task = Send-HPOVRequest -Uri $_ServerProfile.uri -Method PUT -Body $_ServerProfile -Hostname $_ServerProfile.ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
				Return $_Task

			}

			else
			{

				"[{0}] Returning Server Profile to caller with new Storage Volume Attachments: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerProfile.name | Write-Verbose 

				return $_ServerProfile

			}			

		}
		
		else
		{

			if ($PSBoundParameters['TargetAddresses'])
			{

				"[{0}] Adding TargetPortAssignmentType and TargetAddresses to volume attachment members." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				ForEach ($_VolAttachment in $_volumeAttachments)
				{

					$_volumeAttachments | Add-Member -NotePropertyName TargetPortAssignmentType -NotePropertyValue $TargetPortAssignment
					$_volumeAttachments | Add-Member -NotePropertyName TargetAddresses -NotePropertyValue $TargetAddresses

				}				

			}

			return $_volumeAttachments

		}

	}

}
