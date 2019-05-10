function GetStoragePool
{

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param
	(

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("pool","poolName",'Name', 'StoragePool')]
		[Object]$InputObject,

		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[object]$StorageSystem,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[object]$ApplianceConnection

	)

	Process
	{

		switch ($InputObject.Gettype().Name) 
		{

			"String" 
			{ 
						
				# Parameter is correct URI
				if ($InputObject.StartsWith($StoragePoolsUri))
				{

					"[{0}] StoragePool URI provided by caller." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Sending request." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
													   
					Try
					{

						$_sp = Send-HPOVRequest -Uri $InputObject -Hostname $ApplianceConnection.Name

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
					$ExceptionMessage = "Invalid StoragePool Parameter value: {1}. Please correct and try again." -f $InputObject
					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidArgumentValue InvalidArgument 'InputObject' -Message 
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# Parameter is Storage Pool name
				else 
				{
								
					"[{0}] StoragePool Name provided by caller." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
								
					# Get specific storage pool from provided StorageSystem
					if ($InputObject) 
					{ 

						# First look for the StorageSystem Parameter value, and get the StoragePool by filtering on the StorageSystem value.
						Try
						{
										
							$_sp = Get-HPOVStoragePool -Name $InputObject -StorageSystem $StorageSystem -ApplianceConnection $ApplianceConnection -ErrorAction Stop
										
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
											
							$_sp = Get-HPOVStoragePool -Name $InputObject -ApplianceConnection $ApplianceConnection -ErrorAction Stop
									
						}
									
						Catch
						{
									
							$PSCmdlet.ThrowTerminatingError($_)
									
						}
									
					}
									
					# If multiple Storage Pool Resources are returned that are of the same name, generate error and indicate the -StorageSystem Parameter is needed.
					# Validate that the storage pool object is unique and not a collection
					if(($_sp | Measure-Object).Count -gt 1)
					{
									
						"[{0}] Multiple Storage Pool resources of the name '$InputObject'. $($_sp.count) resources found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
										
						$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidStoragePoolResource ObjectNotFound 'InputObject' -TargetType 'Array' -Message "Multiple Storage Pools it the '$tmpStoragePool' name were found.  Please use the -StorageSystem Parameter to specify the Storage System the	Pool is associated with, or use the Get-HPOVStoragePool cmdlet to get the	Storage Pool resource and pass as the -StoragePool Parameter value."
										
						# Generate Terminating Error
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}
									
				}

			}

			'StoragePool'
			{

				$_sp = $InputObject

			}

			"PSCustomObject" 
			{ 
						
				# Validate the object
				if ($InputObject.category -eq 'storage-pools') 
				{ 
								
					# Check the StoragePool object to make sure the ApplianceConnection property matches the ApplianceConnection Parameter from caller
					if ($InputObject.ApplianceConnection.Name -ne $ApplianceConnection.Name)
					{

						$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStoragePoolObject InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "The provided StoragePool object does not appear to originate from the same ApplianceConnection specified -  ApplianceConnection: $($ApplianceConnection.Name) StorageVolume ApplianceConnection $($StorageVolume.ApplianceConnection.Name)."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}
								
					$_sp = $InputObject.PSObject.Copy()
							
				}

				else 
				{

					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStoragePoolCategory InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "Invalid StoragePool Parameter value.  Expected Resource Category 'storage-pools', received '$($VolumeTemplate.category)'."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}                        
						
			}

		}

	}

	End
	{

		Return $_sp

	}

}
