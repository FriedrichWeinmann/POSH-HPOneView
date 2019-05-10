function Set-HPOVStorageVolume 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('SourceVolume')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('VolumeName')]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[String]$Description,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateScript ({$_ -ge 1})]
		[Alias ("size")]
		[int64]$Capacity,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Object]$SnapShotStoragePool,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateSet ('NetworkRaid0None','NetworkRaid5SingleParity','NetworkRaid10Mirror2Way','NetworkRaid10Mirror3Way','NetworkRaid10Mirror4Way','NetworkRaid6DualParity')]
		[String]$DataProtectionLevel,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[bool]$PermitAdaptiveOptimization,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[bool]$Shared,

		[Parameter (Mandatory = $false, ParameterSetName = "default", ValueFromPipelineByPropertyName)]
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

		$colStatus = New-Object System.Collections.ArrayList

	}

	Process 
	{

		# Get Source Volume resource
		Switch ($InputObject.GetType().Name) 
		{

			"String" 
			{ 
				 
				# Parameter is correct URI
				if ($InputObject.StartsWith($StorageVolumesUri))
				{

					"[{0}] Storage Volume URI provided by caller: $InputObject" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting volume resource object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_InputObject = Send-HPOVRequest $InputObject -hostname $ApplianceConnection

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
					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidArgumentValue InvalidArgument 'InputObject' -Message "Invalid Storage Volume Parameter value: $($InputObject | out-string). Please correct and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# Parameter is Storage Pool name
				else 
				{
								
					"[{0}] Storage Volume Name provided by caller." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
								
					Try
					{

						$_InputObject = Get-HPOVStorageVolume $InputObject -ApplianceConnection $ApplianceConnection -ErrorAction Stop

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}
				
			}

			"PSCustomObject" 
			{

				"[{0}] Storage Volume Object provided by caller." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($InputObject | ConvertTo-Json -Depth 99) | Write-Verbose

				# Validate the object
				if ('storage-volumes' -ne $InputObject.category)
				{

					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStoragePoolCategory InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "Invalid Storage Volume Parameter value.  Expected Resource Category 'storage-volumes', received '$($InputObject.category)'."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}    

				$_InputObject = $InputObject.PSObject.Copy()
				
			}

		}

		"[{0}] ORIGINAL Storage Volume object properties: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($InputObject | out-string) | Write-Verbose

		# Get the Storage Pool object to identify the family
		Try
		{

			$_AssociatedStoragePool = Send-HPOVRequest -Uri $InputObject.storagePoolUri -Hostname $InputObject.ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		# Get the SVT associated with the Volume
		if ($InputObject.volumeTemplateUri)
		{

			Try
			{

				$_SVT = Send-HPOVRequest -Uri $InputObject.volumeTemplateUri -Hostname $InputObject.ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}	

			"[{0}] Volume is associated with Volume Template: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_SVT.name | Write-Verbose

		}			

		# Volume Object updates
		switch ($PSboundParameters.keys) 
		{

			'Name'
			{ 
				
				$_InputObject.name = $Name 
			
			}

			'Description'
			{ 
				
				$_InputObject.description = $Description 
			
			}

			'Capacity' 
			{ 

				if (-not $_SVT.properties.size.meta.locked)
				{

					[int64]$_Capacity = $Capacity * 1GB

					if ([int64]$_Capacity -gt [int64]$InputObject.provisionedCapacity) 
					{ 
						
						$_InputObject.provisionedCapacity = $_Capacity 
					
					}

					# Generate Terminating Error
					else 
					{ 
					
						$ExceptionMessage = "Invalid 'capacity' Storage Volume Parameter value.  The value '{0}' is less than the original volume size '{1}'.  Volume capacity cannot be reduced, only increased." -f [int64]$capacity, [int64]$InputObject.provisionedCapacity
						$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStorageVolumeCapacityValue InvalidArgument 'Capacity' -TargetType 'Int' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
					}

				}
			
				else
				{

					$ExceptionMessage = "The associated Storage Volume Template does not allow modifying the Storage Volumes capacity."
					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException UnableToModifyCapacity PermissionDenied 'Capacity' -TargetType 'Int' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}				

			}

			'SnapShotStoragePool'
			{

				if (-not $_SVT.properties.snapshotPool.meta.locked -and $_AssociatedStoragePool.family -ne 'StoreVirtual')
				{

					Try
					{

						$_SnapShotStoragePool = GetStoragePool -StoragePool $SnapShotStoragePool -ApplianceConnection $SnapShotStoragePool.ApplianceConnection
						
					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
					$_InputObject.deviceSpecificAttributes.snapshotPoolUri = $_SnapShotStoragePool.uri

				}
			
				elseif ($_SVT.properties.snapshotPool.meta.locked)
				{

					$ExceptionMessage = "The associated Storage Volume Template does not allow modifying the Snapshot Storage Pool resource."
					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException UnableToModifySnapshotStoragePool PermissionDenied 'SnapShotStoragePool' -TargetType $SnapShotStoragePool.GetType().Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				elseif ($_AssociatedStoragePool.family -eq 'StoreVirtual')
				{

					$ExceptionMessage = "The associated Storage System family is a StoreVirtual system.  Snapshot Storage Pool assignment is not supported."
					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException UnsupportedStorageSystemFamily InvalidOperation 'SnapShotStoragePool' -TargetType $SnapShotStoragePool.GetType().Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			'Shared'
			{ 
				
				if (-not $_SVT.properties.isShareable.meta.locked)
				{

					$_InputObject.shareable = [Bool]$Shared 

				}
			
				else
				{

					$ExceptionMessage = "The associated Storage Volume Template does not allow modifying the shareability of the  Storage Volume resource."
					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException UnableToModifyCapacity PermissionDenied 'Shared' -TargetType $Shared.GetType().Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}				
			
			}

			'DataProtectionLevel'
			{

				$_InputObject.deviceSpecificProperties.dataProtectionLevel = $DataProtectionLevelEnum[$DataProtectionLevel]

			}

			'PermitAdaptiveOptimization'
			{

				$_InputObject.deviceSpecificProperties.isAdaptiveOptimizationEnabled = $PermitAdaptiveOptimization

			}
			
		}
		
		# "[{0}] Updated Storage Volume object properties: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_InputObject ) | Write-Verbose

		"[{0}] Sending updated storage volume to appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Try
		{

			Send-HPOVRequest -Uri $_InputObject.uri -Method PUT -Body $_InputObject -Hostname $ApplianceConnection

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
