function New-HPOVStorageVolumeTemplate 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[Parameter (Mandatory, ParameterSetName = "StoreVirtual")]
		[ValidateNotNullOrEmpty()]
		[Alias ('TemplateName')]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[ValidateNotNullOrEmpty()]
		[string]$Description,

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "StoreVirtual")]
		[ValidateNotNullOrEmpty()]
		[object]$StoragePool,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[switch]$LockStoragePool,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[object]$SnapshotStoragePool,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[switch]$LockSnapShotStoragePool,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[ValidateNotNullOrEmpty()]
		[object]$StorageSystem,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[Parameter (Mandatory, ParameterSetName = "StoreVirtual")]
		[ValidateScript({$_ -ge 1})]
		[Alias ("size")]
		[int64]$Capacity,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[switch]$LockCapacity,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[switch]$Full,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[Alias ('ProvisionType')]
		[ValidateSet ('Thin','Full','TPDD')]
		[String]$ProvisioningType,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[switch]$LockProvisionType,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Bool]$EnableDeduplication,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[switch]$LockEnableDeduplication,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Bool]$EnableCompression,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[switch]$LockEnableCompression,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[switch]$Shared,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[switch]$LockProvisionMode,

		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[ValidateSet ('NetworkRaid0None','NetworkRaid5SingleParity','NetworkRaid10Mirror2Way','NetworkRaid10Mirror3Way','NetworkRaid10Mirror4Way','NetworkRaid6DualParity')]
		[String]$DataProtectionLevel,

		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[switch]$LockProtectionLevel,

		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[switch]$EnableAdaptiveOptimization,

		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[switch]$LockAdaptiveOptimization,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.ScopeCollection]$Scope,

		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName, ParameterSetName = "StoreVirtual")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSboundParameters['StoragePool']))
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

		$colStatus = New-Object System.Collections.ArrayList

		if ($PSBoundParameters['Full'])
		{

			Write-Warning 'The -Full parameter isbeing deprecated.  Please update your scripts to use the -ProvisioningType parameter instead.'

		}

		if ($PSBoundParameters['ProvisionType'] -eq 'TPDD')
		{

			Write-Warning 'The -ProvisionType "TPDD" value is being deprecated.  Please update your script(s) to use the "Thin" value and -Compression $True parameter.'

		}

	}

	Process 
	{

		if ($StoragePool -isnot [PSCustomObject])
		{

			Try
			{

				"[{0}] Getting and validating StoragePool parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_StoragePool = GetStoragePool -InputObject $StoragePool -StorageSystem $StorageSystem -ApplianceConnection $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		else
		{

			"[{0}] StoragePool object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StoragePool.name | Write-Verbose
			"[{0}] StoragePool object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StoragePool.category | Write-Verbose
			"[{0}] StoragePool object URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StoragePool.uri | Write-Verbose
			$_StoragePool = $StoragePool.PSObject.Copy()

		}

		# Get Root Volume Template from Storage System
		Try
		{

			"[{0}] Getting storage system root volume template." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			$_Uri = '{0}/templates?filter=isRoot EQ true' -f $_StoragePool.storageSystemUri
			$_RootTemplate = (Send-HPOVRequest -Uri $_Uri -Hostname $ApplianceConnection).members[0]

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		"[{0}] Root template: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_RootTemplate.name | Write-Verbose
		"[{0}] Root template family: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_RootTemplate.family | Write-Verbose

		$_svt = NewObject -StorageVolumeTemplate
		$_svt.properties = $_RootTemplate.properties

		switch ($_RootTemplate.family)
		{

			'StoreServ'
			{

				if ($PSBoundParameters['DataProtectionLevel'] -or $PSBoundParameters['LockProtectionLevel'])
				{

					$ExceptionMessage = "The Storage System family of the Storage Pool, {0}, is not a StoreVirtual system.  DataProtectionLevel is only supported with StoreVirtual class of storage systems." -f $_StoragePool.name
					$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'DataProtectionLevel' -TargetType $DataProtectionLevel.gettype().Name -Message $ExceptionMessage
				
					# Generate Terminating Error
					$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

				}

				if ($PSBoundParameters['EnableAdaptiveOptimization'] -or $PSBoundParameters['LockAdaptiveOptimization'])
				{

					$ExceptionMessage = "The Storage System family of the Storage Pool, {0}, is not a StoreVirtual system.  EnableAdaptiveOptimization is only supported with StoreVirtual class of storage systems." -f $_StoragePool.name
					$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'EnableAdaptiveOptimization' -TargetType $EnableAdaptiveOptimization.gettype().Name -Message $ExceptionMessage
				
					# Generate Terminating Error
					$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

				}

				if ($PSboundParameters['SnapShotStoragePool'])
				{

					Try
					{

						$_SnapShotStoragePool = GetStoragePool -InputObject $SnapShotStoragePool -StorageSystem $StorageSystem -ApplianceConnection $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)
						
					}

					"[{0}] Setting snapshot storage pool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_SnapShotStoragePool.uri | Write-Verbose

					$_svt.properties.snapshotPool.default = $_SnapShotStoragePool.uri

				}

				else 
				{			

					"[{0}] No SnapShotStoragePool resource provided. Setting Snapshot Pool to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_StoragePool.name | Write-Verbose

					$_svt.properties.snapshotPool.default = $_StoragePool.uri

				}

				if ($PSBoundParameters['LockStoragePool'])
				{

					"[{0}] Locking Snapshot Storage Pool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockSnapshotStoragePool.IsPresent | Write-Verbose

					$_svt.properties.snapshotPool.meta.locked = $LockSnapshotStoragePool.IsPresent

				}

				if ($PSBoundParameters['EnableDeduplication'])
				{

					"[{0}] Enable Deduplication: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnableDeduplication | Write-Verbose

					$_svt.properties.isDeduplicated.default = $EnableDeduplication

					if ($PSBoundParameters['LockEnableDeduplication'])
					{

						"[{0}] Locking Snapshot Storage Pool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockEnableDeduplication.IsPresent | Write-Verbose

						$_svt.properties.isDeduplicated.meta.locked = $LockEnableDeduplication.IsPresent

					}					

				}
				
				if ($PSBoundParameters['EnableCompression'])
				{

					"[{0}] Enable Deduplication: {1}" -f $MyInvocation.InvoctionName.ToString().ToUpper(), $EnableCompression | Write-Verbose

					$_svt.properties.isCompressed.default = $EnableCompression

					if ($PSBoundParameters['LockEnableCompression'])
					{

						"[{0}] Locking Snapshot Storage Pool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockEnableCompression.IsPresent | Write-Verbose

						$_svt.properties.isCompressed.meta.locked = $LockEnableCompression.IsPresent

					}

				}				

			}

			'StoreVirtual'
			{

				if ($PSBoundParameters['SnapShotStoragePool'])
				{

					$ExceptionMessage = "The Storage System family of the Storage Pool, {0}, is not a StoreServ system.  Snapshots are only supported with StoreServ class of storage systems." -f $_StoragePool.name
					$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'StoragePool' -TargetType $StoragePool.gettype().Name -Message $ExceptionMessage
				
					# Generate Terminating Error
					$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

				}

				# Set AdaptiveOptimization and RedundancyMode
				if ($PSBoundParameters['DataProtectionLevel'])
				{

					$_DataProtectionLevel = $_RootTemplate.properties.dataProtectionLevel.enum | Where-Object { $_ -eq $DataProtectionLevel }

					if (-not $_DataProtectionLevel)
					{

						$ExceptionMessage = "The requested data protection level, {0}, is not supported with the storage system. Please correct the value with one of the following options: {1}" -f $DataProtectionLevel, ([String]::Join(', ', $_RootTemplate.properties.dataProtectionLevel.enum))
						$ErrorRecord = New-ErrorRecord ArgumentException UnsupportedProtectionLevelValue InvalidArgument 'DataProtectionLevel' -TargetType $DataProtectionLevel.gettype().Name -Message $ExceptionMessage
					
						# Generate Terminating Error
						$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

					}

					"[{0}] Setting StoreVirtual data protection level: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_DataProtectionLevel | Write-Verbose

					$_svt.properties.dataProtectionLevel.default = $_DataProtectionLevel

				}

				if ($PSBoundParameters['LockProtectionLevel'])
				{

					"[{0}] Locking Protection Level: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockProtectionLevel.IsPresent | Write-Verbose

					$_svt.properties.dataProtectionLevel.meta.locked = $LockProtectionLevel.IsPresent

				}

				if ($PSBoundParameters['EnableAdaptiveOptimization'])
				{

					"[{0}] Setting Adaptive optimization default value: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnableAdaptiveOptimization.IsPresent | Write-Verbose

					$_svt.properties.isAdaptiveOptimizationEnabled.default = $EnableAdaptiveOptimization.IsPresent

				}

				if ($PSBoundParameters['LockAdaptiveOptimization'])
				{

					"[{0}] Locking Adaptive optimization: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockAdaptiveOptimization.IsPresent | Write-Verbose

					$_svt.properties.isAdaptiveOptimizationEnabled.meta.locked = $LockAdaptiveOptimization.IsPresent

				}

			}

		}

		# Set common values here
		$_svt.name            = $Name
		$_svt.description     = $description
		$_svt.rootTemplateUri = $_RootTemplate.uri

		switch ($PSBoundParameters.Keys)
		{

			'Capacity'
			{

				"[{0}] Setting capacity default value: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [int64]($capacity * 1GB) | Write-Verbose

				$_svt.properties.size.default = [int64]($capacity * 1GB)

			}

			'LockCapacity'
			{

				"[{0}] Locking capacity: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockCapacity.IsPresent | Write-Verbose

				$_svt.properties.size.meta.locked = $LockCapacity.IsPresent

			}

			'StoragePool'
			{

				"[{0}] Setting Storage Pool default value: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_StoragePool.uri | Write-Verbose

				$_svt.properties.storagepool | Add-Member -NotePropertyName default -NotePropertyValue $_StoragePool.uri

			}

			'LockStoragePool'
			{

				"[{0}] Locking Storage Pool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockStoragePool.IsPresent | Write-Verbose

				$_svt.properties.storagepool.meta.locked = $LockStoragePool.IsPresent

			}

			'Full'
			{

				"[{0}] Setting Provisioning Type to Full: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Full.IsPresent | Write-Verbose

				$_svt.properties.provisioningType.default = if ($Full.IsPresent) { 'Full' } else { 'Thin' }
				
			}

			'ProvisioningType'
			{

				"[{0}] Setting Provisioning Type to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StorageVolumeProvisioningTypeEnum[$ProvisioningType] | Write-Verbose

				$_svt.properties.provisioningType.default = $StorageVolumeProvisioningTypeEnum[$ProvisioningType]

				if ($ProvisioningType -eq 'TPDD')
				{

					"[{0}] Setting isDeduplicated: true" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_svt.properties.isDeduplicated.default = $true

				}

			}

			'LockProvisionType'
			{

				"[{0}] Locking provisioning type: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockProvisionType.IsPresent | Write-Verbose

				$_svt.properties.provisioningType.meta.locked = $LockProvisionType.IsPresent

				if ($ProvisioningType -eq 'TPDD')
				{

					"[{0}] Locking Deduplication: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockProvisionType.IsPresent | Write-Verbose

					$_svt.properties.isDeduplicated.meta.locked = $LockProvisionType.IsPresent

				}

			}

			'Shared'
			{

				"[{0}] Setting Provisioning Type to Full: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Shared.IsPresent | Write-Verbose

				$_svt.properties.isShareable.default = $Shared.IsPresent
				
			}

			'LockProvisionMode'
			{

				"[{0}] Locking provisioning type: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockProvisionType.IsPresent | Write-Verbose

				$_svt.properties.isShareable.meta.locked = $LockProvisionType.IsPresent

			}

		}

		if ($PSBoundParameters['Scope'])
		{

			ForEach ($_Scope in $Scope)
			{

				"[{0}] Adding resource to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

				[void]$_svt.initialScopeUris.Add($_Scope.Uri)

			}

		}

		# Send the request
		Try
		{

			$_resp = Send-HPOVRequest -method POST -uri $StorageVolumeTemplateUri -body $_svt -Hostname $ApplianceConnection.Name
			$_resp.PSObject.TypeNames.Insert(0,'HPOneView.Storage.VolumeTemplate')

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}
		
		$_resp

	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
