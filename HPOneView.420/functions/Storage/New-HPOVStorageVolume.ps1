function New-HPOVStorageVolume 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "default")]
		[Parameter (Mandatory, ParameterSetName = "template")]
		[ValidateNotNullOrEmpty()]
		[Alias ("VolumeName")]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[ValidateNotNullOrEmpty()]
		[string]$Description,

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("pool","poolName")]
		[object]$StoragePool,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[ValidateNotNullOrEmpty()]
		[object]$SnapshotStoragePool,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[object]$StorageSystem,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[ValidateSet ('NetworkRaid0None','NetworkRaid5SingleParity','NetworkRaid10Mirror2Way','NetworkRaid10Mirror3Way','NetworkRaid10Mirror4Way','NetworkRaid6DualParity')]
		[String]$DataProtectionLevel,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[switch]$EnableAdaptiveOptimization,

		[Parameter (Mandatory, ParameterSetName = "template")]
		[ValidateNotNullOrEmpty()]
		[Alias ('template','svt')]
		[object]$VolumeTemplate,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[ValidateScript({$_ -ge 1})]
		[Alias ("size")]
		[int64]$Capacity,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[ALias ("ProvisionType")]
		[ValidateSet ('Thin', 'Full', 'TPDD')]
		[String]$ProvisioningType,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[Bool]$EnableCompression,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[Bool]$EnableDeduplication,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[switch]$Full,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[switch]$Shared,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.ScopeCollection]$Scope,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "template")]
		[switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "template")]
		[ValidateNotNullorEmpty()]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['StoragePool']))
		{

			$PipelineInput = $True

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

		if ($PSBoundParameters['Full'])
		{

			Write-Warning "The -Full parameter is being deprecated for -ProvisioningType.  Please update your script(s) to use the new parameter."

		}

	}

	Process 
	{

		$_newVolume = NewObject -StorageVolume

		# Check to see if Storage Volume Template Global Setting is enabled
		Try
		{

			"[{0}] Checking for SVT Global Policy." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_storageVolumeTemplateRequiredGlobalPolicy = (Send-HPOVRequest $applStorageVolumeTemplateRequiredPolicy -Hostname $ApplianceConnection).value

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}
		
		if ($_storageVolumeTemplateRequiredGlobalPolicy -ieq "True" -and (-not $PSBoundParameters['VolumeTemplate'] -or -not $VolumeTemplate))
		{ 
		
			$ExceptionMessage = "Storage Volumes cannot be created without providing a Storage Volume Template due to global policy setting.  Please provide a Storage Volume Template and try again."
			$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException StorageVolumeTemplateRequired InvalidArgument 'VolumeTemplate' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
		
		}

		# Figure out what type of Volume we will create
		if ($PSBoundParameters['VolumeTemplate'] -or $VolumeTemplate)
		{

			if ($VolumeTemplate.category -ne 'storage-volume-templates')
			{

				$ExceptionMessage = "The value provided for VolumeTemplate is not the allowed resource type, storage-volume-templates."
				$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeTemplateResourceException InvalidStorageVolumeTemplateResource InvalidArgument 'VolumeTemplate' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			"[{0}] Storage Volume Template provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.name | Write-Verbose
			"[{0}] Storage Volume Template family: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.family | Write-Verbose

			$_Family = $VolumeTemplate.family

		}
		
		# Storage Pool was provided
		else
		{

			"[{0}] No Storage Volume Template provided.  Processing StoragePool." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($StoragePool -is [String])
			{

				"[{0}] Locating storage pool resource: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StoragePool | Write-Verbose

				Try
				{

					$StoragePool = GetStoragePool -Name $StoragePool -StorageSystem $StorageSystem -ApplianceConnection $ApplianceConnection

				}
			
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			# Get Storage System
			Try
			{

				$_StorageSystem = Send-HPOVRequest -Uri $StoragePool.storageSystemUri -Hostname $StoragePool.ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_StoragePool = $StoragePool.PSObject.Copy()

			$_StoragePool | Add-Member -NotePropertyName family -NotePropertyValue $_StorageSystem.family

			"[{0}] Storage Pool family: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_StoragePool.family | Write-Verbose

			$_Family = $_StoragePool.family

			# Need to get the root ST since none was provided
			Try
			{

				$Uri = "{0}/templates?query=isRoot EQ true" -f $_StoragePool.storageSystemUri
				$RootSVT = Send-HPOVRequest -Uri $Uri -ApplianceConnection $ApplianceConnection
				$VolumeTemplate = $RootSVT.members[0]

			}
		
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		$_newVolume = NewObject -StorageVolume

		"[{0}] Setting volume template uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.uri | Write-Verbose

		$_newVolume.templateUri = $VolumeTemplate.uri

		ForEach ($_PropName in ($VolumeTemplate.properties.PSObject.Members | Where-Object { $_.MemberType -eq 'NoteProperty' -and $_.Name -ne 'templateVersion' }))
		{
	
			$_newVolume.properties | Add-Member -NotePropertyName $_PropName.Name -NotePropertyValue $null

		}

		switch (($VolumeTemplate.properties.PSObject.Members | Where-Object MemberType -eq 'NoteProperty').Name)
		{

			'name'
			{

				"[{0}] Setting volume name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose
				$_newvolume.properties.name = $Name

			}

			'description'
			{

				if ($PSBoundParameters['Description'])
				{

					"[{0}] Setting volume description: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Description | Write-Verbose
					$_newvolume.properties.description = $Description

				}				

			}

			'storagePool'
			{

				# If SVT enforces, set it
				if ($VolumeTemplate.properties.storagePool.meta.locked -or -not $PSBoundParameters['StoragePool'])
				{

					"[{0}] Volume Template enforces StoragePool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.storagePool.default | Write-Verbose

					$_newvolume.properties.storagePool = $VolumeTemplate.properties.storagePool.default
					
				}

				else
				{

					"[{0}] Setting StoragePool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_StoragePool.uri | Write-Verbose

					$_newvolume.properties.storagePool = $_StoragePool.uri

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

						$_newvolume.properties.snapshotPool = $VolumeTemplate.properties.snapshotPool.default
						
					}

					else
					{

						if ($PSBoundParameters['SnapshotStoragePool'])
						{

							if ($SnapshotStoragePool -is [String])
							{

								try
								{

									$SnapshotStoragePool = GetStoragePool -Name $SnapshotStoragePool -StorageSystem $StorageSystem -ApplianceConnection $ApplianceConnection

								}

								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}

							}

							"[{0}] Setting SnapshotStoragePool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $SnapshotStoragePool.uri | Write-Verbose
							
							$_newvolume.properties.snapshotPool = $SnapshotStoragePool.uri

						}

						elseif (-not $PSBoundParameters['SnapshotStoragePool'] -and -not $PSBoundParameters['StoragePool'])
						{

							"[{0}] Setting SnapshotStoragePool to StoragePool from Volume Template: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.snapshotPool.default | Write-Verbose

							$_newvolume.properties.snapshotPool = $VolumeTemplate.properties.snapshotPool.default

						}
						
						else
						{

							"[{0}] Setting SnapshotStoragePool to StoragePool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StoragePool.uri | Write-Verbose

							$_newvolume.properties.snapshotPool = $StoragePool.uri

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

			'isDeduplicated'
			{

				if ($_Family -ne 'StoreVirtual')
				{

					"[{0}] Family is StoreServ, attempting to set Deduplicated" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# If SVT enforces, set it
					if ($VolumeTemplate.properties.isDeduplicated.meta.locked -or (-not $PSBoundParameters['EnableDeduplication'] -and $ProvisioningType -ne 'TPDD'))
					{

						"[{0}] Volume Template enforces Deduplicate: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.isDeduplicated.default | Write-Verbose

						$_newvolume.properties.isDeduplicated = $VolumeTemplate.properties.isDeduplicated.default
						
					}

					elseif ($ProvisionType -ne 'TPDD')
					{

						"[{0}] Setting (TPDD) Deduplicate: true" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_newvolume.properties.isDeduplicated = $true

					}

					else
					{

						"[{0}] Setting Deduplicate: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnableDeduplication | Write-Verbose

						$_newvolume.properties.isDeduplicated = $EnableDeduplication

					}

				}

				else
				{

					if ($PSBoundParameters['EnableDeduplication'])
					{

						$ExceptionMessage = "The Storage System family of the Storage Pool, {0}, is not a StoreServ system.  Deduplication is only supported with StoreServ class of storage systems." -f $_StoragePool.name
						$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'EnableDeduplication' -TargetType $SnapShotStoragePool.gettype().Name -Message $ExceptionMessage
					
						# Generate Terminating Error
						$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

					}

				}

			}

			'isCompressed'
			{

				if ($_Family -ne 'StoreVirtual')
				{

					"[{0}] Family is StoreServ, attempting to set Compression" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# If SVT enforces, set it
					if ($VolumeTemplate.properties.isCompressed.meta.locked -or -not $PSBoundParameters['EnableCompression'])
					{

						"[{0}] Volume Template enforces Compression: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.isCompressed.default | Write-Verbose

						$_newvolume.properties.isCompressed = $VolumeTemplate.properties.isCompressed.default
						
					}

					else
					{

						"[{0}] Setting Deduplication: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnableDeduplication | Write-Verbose

						$_newvolume.properties.isCompressed = $EnableDeduplication

					}

				}

				else
				{

					if ($PSBoundParameters['EnableDeduplication'])
					{

						$ExceptionMessage = "The Storage System family of the Storage Pool, {0}, is not a StoreServ system.  Deduplication is only supported with StoreServ class of storage systems." -f $_StoragePool.name
						$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'EnableDeduplication' -TargetType $SnapShotStoragePool.gettype().Name -Message $ExceptionMessage
					
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

						$_newvolume.properties.dataProtectionLevel = $VolumeTemplate.properties.dataProtectionLevel.default

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

						$_newvolume.properties.dataProtectionLevel = $_DataProtectionLevel

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

						$_newvolume.properties.isAdaptiveOptimizationEnabled = $VolumeTemplate.properties.isAdaptiveOptimizationEnabled.default

					}
					
					else
					{

						$_newvolume.properties.isAdaptiveOptimizationEnabled = $EnableAdaptiveOptimization.IsPresent

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

					$_newvolume.properties.size = $VolumeTemplate.properties.size.default

				}
				
				else
				{

					$_newvolume.properties.size = $Capacity * 1GB

				}

			}

			'provisioningType'
			{

				if ($VolumeTemplate.properties.provisioningType.meta.locked -or (-not $PSBoundParameters['Full'] -and -not $PSBoundParameters['ProvisioningType'] -and -not $VolumeTemplate.properties.provisioningType.meta.locked))
				{

					"[{0}] Volume Template enforces volume provisioningType: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.provisioningType.default | Write-Verbose
					$_newvolume.properties.provisioningType = $VolumeTemplate.properties.provisioningType.default

				}
				
				else
				{

					if ($PSBoundParameters['ProvisioningType'])
					{

						"[{0}] Setting volume provisioningType via ProvisioningType param: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StorageVolumeProvisioningTypeEnum[$ProvisioningType] | Write-Verbose

						$_newvolume.properties.provisioningType = $StorageVolumeProvisioningTypeEnum[$ProvisioningType]

					}

					elseif ($PSBoundParameters['Full'])
					{

						"[{0}] Setting volume provisioningType via full param: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StorageVolumeProvisioningTypeEnum['Full'] | Write-Verbose

						$_newvolume.properties.provisioningType = $StorageVolumeProvisioningTypeEnum['Full']

					}

					else
					{

						"[{0}] Setting volume provisioningType via not full param: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StorageVolumeProvisioningTypeEnum['Thin'] | Write-Verbose

						$_newvolume.properties.provisioningType = $StorageVolumeProvisioningTypeEnum['Thin']

					}

				}

			}

			'isShareable'
			{

				if ($VolumeTemplate.properties.isShareable.meta.locked -or (-not $PSBoundParameters['Shared'] -and -not $VolumeTemplate.properties.isShareable.meta.locked))
				{

                    "[{0}] Volume Template enforces volume shareable state: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $VolumeTemplate.properties.isShareable.default | Write-Verbose

					$_newvolume.properties.isShareable = $VolumeTemplate.properties.isShareable.default

				}
				
				else
				{

					$_newvolume.properties.isShareable = $Shared.IsPresent

				}

			}

		}

		if ($PSBoundParameters['Scope'])
		{

			ForEach ($_Scope in $Scope)
			{

				"[{0}] Adding resource to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

				[void]$_newVolume.initialScopeUris.Add($_Scope.Uri)

			}

		}

		# Send the request
		Try
		{

			$_Resp = Send-HPOVRequest -Uri $StorageVolumesUri -Method POST -Body $_newVolume -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-Not $PSBoundParameters['Async'])
		{

			$_Resp | Wait-HPOVTaskComplete

		}

		else
		{

			$_Resp

		}

	}

	End 
	{
		
		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
