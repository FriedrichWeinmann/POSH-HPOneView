function Set-HPOVStorageVolumeTemplate 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "StoreVirtual")]
		[Alias('SVT','Template')]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[ValidateNotNullOrEmpty()]
		[Alias ('TemplateName')]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[ValidateNotNullOrEmpty()]
		[string]$Description,

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
		[switch]$Thin,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[switch]$Full,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[switch]$LockProvisionType,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "StoreVirtual")]
		[bool]$Shared,

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

		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName, ParameterSetName = "StoreVirtual")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject']))
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

	}

	Process 
	{

		# Get Source Volume resource
		Switch ($InputObject.GetType().Name) 
		{

			"String" 
			{ 
				 
				# Parameter is correct URI
				if ($InputObject.StartsWith($StorageVolumeTemplatesUri))
				{

					"[{0}] Storage Volume Template URI provided by caller: $InputObject" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting volume resource object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_InputObject = Send-HPOVRequest -Uri $InputObject -hostname $ApplianceConnection

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
							
				}

				# Parameter is incorrect URI value
				elseif ($InputObject.StartsWith("/rest")) 
				{

					# Invalid Parameter value, generate terminating error.
					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeTemplateResourceException InvalidArgumentValue InvalidArgument 'InputObject' -Message "Invalid InputObject parameter value: $($InputObject | out-string). Please correct and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# Parameter is Storage Pool name
				else 
				{
								
					"[{0}] Storage Volume Name provided by caller." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_InputObject = Get-HPOVStorageVolumeTemplate -Name $InputObject -ApplianceConnection $ApplianceConnection -ErrorAction Stop

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}
				
			}

			"PSCustomObject" 
			{

				"[{0}] Storage Volume Template Object provided by caller." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
				"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.uri | Write-Verbose
				"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.ApplianceConnection.Name | Write-Verbose
				"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.category | Write-Verbose

				# Validate the object
				if ('storage-volume-templates' -ne $InputObject.category)
				{

					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeTemplateResourceException InvalidStorageVolumeTemplateCategory InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "Invalid InputObject parameter value.  Expected Resource Category 'storage-volume-templates', received '$($InputObject.category)'."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_InputObject = $InputObject.PSObject.Copy()
				
			}

		}

		"[{0}] ORIGINAL Storage Volume object properties: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

		switch ($_InputObject.family)
		{

			'StoreServ'
			{

				if ($PSBoundParameters['DataProtectionLevel'] -or $PSBoundParameters['LockProtectionLevel'])
				{

					$ExceptionMessage = "The Storage System family of the volume template, {0}, is not a StoreVirtual system.  DataProtectionLevel is only supported with StoreVirtual class of storage systems." -f $_InputObject.name
					$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'DataProtectionLevel' -TargetType $DataProtectionLevel.gettype().Name -Message $ExceptionMessage
				
					# Generate Terminating Error
					$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

				}

				if ($PSBoundParameters['EnableAdaptiveOptimization'] -or $PSBoundParameters['LockAdaptiveOptimization'])
				{

					$ExceptionMessage = "The Storage System family of the volume template, {0}, is not a StoreVirtual system.  EnableAdaptiveOptimization is only supported with StoreVirtual class of storage systems." -f $_InputObject.name
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

					Try
					{

						$_StoragePool = Send-HPOVRequest -Uri $_InputObject.storagePoolUri -Hostname $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					if ($_StoragePool.storageSystemUri -ne $_SnapShotStoragePool.storageSystemUri)
					{

						$ExceptionMessage = "The Storage Pool and SnapShot Storage Pool are not from the same Storage System. please correct the SnapshotStoragePool parameter value."
						$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidSnapshotStoragePoolLocation InvalidOperation 'SnapShotStoragePool' -TargetType 'PSObject' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					"[{0}] Setting snapshot storage pool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_SnapShotStoragePool.uri | Write-Verbose

					$_InputObject.properties.snapshotPool.default = $_SnapShotStoragePool.uri

				}

				if ($PSBoundParameters['LockStoragePool'])
				{

					"[{0}] Locking Snapshot Storage Pool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockSnapshotStoragePool.IsPresent | Write-Verbose

					$_InputObject.properties.snapshotPool.meta.locked = $LockSnapshotStoragePool.IsPresent

				}

			}

			'StoreVirtual'
			{

				if ($PSBoundParameters['SnapShotStoragePool'])
				{

					$ExceptionMessage = "The Storage System family of the Storage Pool, {0}, is not a StoreServ system.  Snapshots are only supported with StoreServ class of storage systems." -f $_StoragePool.name
					$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'SnapShotStoragePool' -TargetType $SnapShotStoragePool.gettype().Name -Message $ExceptionMessage
				
					# Generate Terminating Error
					$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

				}

				# Set AdaptiveOptimization and RedundancyMode
				if ($PSBoundParameters['DataProtectionLevel'])
				{

					$_DataProtectionLevel = $_InputObject.properties.dataProtectionLevel.enum | Where-Object { $_ -eq $DataProtectionLevel }

					if (-not $_DataProtectionLevel)
					{

						$ExceptionMessage = "The requested data protection level, {0}, is not supported with the storage system. Please correct the value with one of the following options: {1}" -f $DataProtectionLevel, ([String]::Join(', ', $_InputObject.properties.dataProtectionLevel.enum))
						$ErrorRecord = New-ErrorRecord ArgumentException UnsupportedProtectionLevelValue InvalidArgument 'DataProtectionLevel' -TargetType $DataProtectionLevel.gettype().Name -Message $ExceptionMessage
					
						# Generate Terminating Error
						$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

					}

					"[{0}] Setting StoreVirtual data protection level: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_DataProtectionLevel | Write-Verbose

					$_InputObject.properties.dataProtectionLevel.default = $_DataProtectionLevel

				}

				if ($PSBoundParameters['LockProtectionLevel'])
				{

					"[{0}] Locking Protection Level: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockProtectionLevel.IsPresent | Write-Verbose

					$_InputObject.properties.dataProtectionLevel.meta.locked = $LockProtectionLevel.IsPresent

				}

				if ($PSBoundParameters['EnableAdaptiveOptimization'])
				{

					"[{0}] Setting Adaptive optimization default value: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnableAdaptiveOptimization.IsPresent | Write-Verbose

					$_InputObject.properties.isAdaptiveOptimizationEnabled.default = $EnableAdaptiveOptimization.IsPresent

				}

				if ($PSBoundParameters['LockAdaptiveOptimization'])
				{

					"[{0}] Locking Adaptive optimization: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockAdaptiveOptimization.IsPresent | Write-Verbose

					$_InputObject.properties.isAdaptiveOptimizationEnabled.meta.locked = $LockAdaptiveOptimization.IsPresent

				}

			}

		}

		switch ($PSBoundParameters.Keys)
		{

			'Name'
			{

				$_InputObject.name = $Name

			}

			'Description'
			{

				$_InputObject.description = $description

			}

			'Capacity'
			{

				"[{0}] Setting capacity default value: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [int64]($Capacity * 1GB) | Write-Verbose

				$_InputObject.properties.size.default = [int64]($Capacity * 1GB)

			}

			'LockCapacity'
			{

				"[{0}] Locking capacity: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockCapacity.IsPresent | Write-Verbose

				$_InputObject.properties.size.meta.locked = $LockCapacity.IsPresent

			}

			'LockStoragePool'
			{

				"[{0}] Locking Storage Pool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockStoragePool.IsPresent | Write-Verbose

				$_InputObject.properties.storagepool.meta.locked = $LockStoragePool.IsPresent

			}

			'Full'
			{

				"[{0}] Setting Provisioning Type to Full: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Full.IsPresent | Write-Verbose

				$_InputObject.properties.provisioningType.default = if ($Full.IsPresent) { 'Full' } else { 'Thin' }
				
			}

			'Thin'
			{

				"[{0}] Setting Provisioning Type to Thin: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Thin.IsPresent | Write-Verbose

				$_InputObject.properties.provisioningType.default = if ($Thin.IsPresent) { 'Full' } else { 'Thin' }
				
			}

			'LockProvisionType'
			{

				"[{0}] Locking provisioning type: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockProvisionType.IsPresent | Write-Verbose

				$_InputObject.properties.provisioningType.meta.locked = $LockProvisionType.IsPresent

			}

			'Shared'
			{

				"[{0}] Setting Provisioning Type to Full: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Shared.IsPresent | Write-Verbose

				$_InputObject.properties.isShareable.default = $Shared.IsPresent
				
			}

			'LockProvisionMode'
			{

				"[{0}] Locking provisioning type: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LockProvisionType.IsPresent | Write-Verbose

				$_InputObject.properties.isShareable.meta.locked = $LockProvisionType.IsPresent

			}

		}
		
		"[{0}] Updated Storage Volume Template object properties: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_InputObject | out-string) | Write-Verbose

		"[{0}] Sending updated storage volume template to appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Try
		{

			$Resp = Send-HPOVRequest -Uri $_InputObject.uri -Method PUT -Body $_InputObject -Hostname $ApplianceConnection

			$Resp.PSObject.TypeNames.Insert(0,'HPOneView.Storage.VolumeTemplate')

			$Resp

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
