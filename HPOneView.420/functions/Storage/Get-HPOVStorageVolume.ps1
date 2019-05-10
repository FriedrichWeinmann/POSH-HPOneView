function Get-HPOVStorageVolume 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "InputObject")]
		[ValidateNotNullOrEmpty()]
		[Alias ('ServerProfile', 'ServerProfileTemplate')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('VolumeName')]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('SVT')]
		[object]$StorageVolumeTemplate,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[switch]$Available,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[String]$Label,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "InputObject")]
		[ValidateNotNullorEmpty()]
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
		
		#$volumeCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{ 

		"[{0}] ParameterSetName: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PSCmdlet.ParameterSetName | Write-Verbose
		
		if ($InputObject)
		{

			"[{0}] InputObject category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.category | Write-Verbose

			switch ($InputObject.category)
			{

				${ResourceCategoryEnum.ServerProfile}
				{

					"[{0}] Processing Server Profile: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
					"[{0}] Storage Volume Attachments: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.sanStorage.volumeAttachments.Count | Write-Verbose
					
					ForEach ($_VolumeAttachment in $InputObject.sanStorage.volumeAttachments)
					{

						Try
						{

							$_StorageVolume = Send-HPOVRequest -Uri $_VolumeAttachment.volumeUri -HostName $InputObject.ApplianceConnection

							$_StorageVolume.PSobject.TypeNames.Insert(0,'HPOneView.Storage.Volume')

							$_StorageVolume

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

				}

				'storage-systems'
				{

					"[{0}] Processing Storage System: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

					"[{0}] Getting associated Storage Pools with system" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_Uri = "{0}?filter=storageSystemUri EQ '{1}'&filter=isManaged EQ true" -f $StoragePoolsUri, $InputObject.uri
						$_AssociatedPools = Send-HPOVRequest -Uri $_Uri -Hostname $InputObject.ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					"[{0}] Associated Storage Pools with system: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_AssociatedPools.count | Write-Verbose

					if ($_AssociatedPools.members)
					{

						ForEach ($_AssociatedPool in $_AssociatedPools.members)
						{

							"[{0}] Getting associated storage volumes with pool: " -f $MyInvocation.InvocationName.ToString().ToUpper(), $_AssociatedPool.name | Write-Verbose

							Try
							{

								$_Uri = "{0}?filter=storagePoolUri EQ '{1}'" -f $StorageVolumesUri, $_AssociatedPool.uri
								$_AssociatedVols = Send-HPOVRequest -Uri $_Uri -Hostname $InputObject.ApplianceConnection

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

							"[{0}] Associated storage vols with pool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_AssociatedVols.count | Write-Verbose

							if ($_AssociatedVols.members)
							{

								$_AssociatedVols.members | ForEach-Object {

									$_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.Volume')
									$_

								}

							}

						}

					}

				}

				'storage-pools'
				{

					"[{0}] Processing Storage Pool: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

					Try
					{

						$_Uri = "{0}?filter=storagePoolUri EQ '{1}'" -f $StorageVolumesUri, $InputObject.uri
						$_AssociatedVols = Send-HPOVRequest -Uri $_Uri -Hostname $InputObject.ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					if ($_AssociatedVols.members)
					{

						$_AssociatedVols.members | ForEach-Object {

							$_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.Volume')
							$_

						}

					}

				}

				default
				{

					$ExceptionMessage = "The InputObject parameter value is not supported.  Only Server Profile, Storage System and Storage Pool objects are supports."
					$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'InputObject' -TargetType $InputObject.gettype().Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

				}

			}

		}

		else
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

				$_Query = New-Object System.Collections.ArrayList

				# Handle default cause of AllResourcesInScope
				if ($Scope -eq 'AllResourcesInScope')
				{
	
					"[{0}] Processing AllResourcesInScope." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
					$_Scopes = $_appliance.ActivePermissions | Where-Object Active
	
					# If one scope contains 'AllResources' ScopeName "tag", then all resources should be returned regardless.
					if ($_Scopes | Where-Object ScopeName -eq 'AllResources')
					{
	
						$_ScopeNames = [String]::Join(', ', ($_Scopes | Where-Object ScopeName -eq 'AllResources').ScopeName)
	
						"[{0}] Scope(s) {1} is set to 'AllResources'.  Will not add scope to URI query parameter." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeNames | Write-Verbose
	
					}
	
					# Process ApplianceConnection ActivePermissions collection
					else
					{
	
						Try
						{
	
							$_ScopeQuery = Join-Scope $_Scopes
	
						}
	
						Catch
						{
	
							$PSCmdlet.ThrowTerminatingError($_)
	
						}
	
						[Void]$_Query.Add(("({0})" -f $_ScopeQuery))
	
					}
	
				}
	
				elseif ($Scope | Where-Object ScopeName -eq 'AllResources')
				{
	
					$_ScopeNames = [String]::Join(', ', ($_Scopes | Where-Object ScopeName -eq 'AllResources').ScopeName)
	
					"[{0}] Scope(s) {1} is set to 'AllResources'.  Will not add scope to URI query parameter." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeNames | Write-Verbose
	
				}
	
				elseif ($Scope -eq 'AllResources')
				{
	
					"[{0}] Requesting scope 'AllResources'.  Will not add scope to URI query parameter." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeNames | Write-Verbose
	
				}
	
				else
				{
	
					Try
					{
	
						$_ScopeQuery = Join-Scope $Scope
	
					}
	
					Catch
					{
	
						$PSCmdlet.ThrowTerminatingError($_)
	
					}
	
					[Void]$_Query.Add(("({0})" -f $_ScopeQuery))
	
				}

				if ($Name)
				{

					"[{0}] Filtering for Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

					if ($Name.Contains('*'))
					{

						[Void]$_Query.Add(("name%3A{0}" -f $Name.Replace("*", "%2A").Replace(',','%2C').Replace(" ", "?")))

					}

					else
					{

						[Void]$_Query.Add(("name:'{0}'" -f $Name))

					}                
					
				}

				if ($Label)
				{

					"[{0}] Filtering for Label: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Label | Write-Verbose

					[Void]$_Query.Add(("labels:'{0}'" -f $Label))

				}

				if ($PSBoundParameters['StorageVolumeTemplate'])
				{
				
					"[{0}] Filtering for StorageVolumeTemplate." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					switch ($StorageVolumeTemplate.GetType().Name)
					{

						'String'
						{

							Try
							{

								$_StorageVolumeTemplate = Get-HPOVStorageVolumeTemplate -Name $StorageVolumeTemplate -ApplianceConnection $_appliance -ErrorAction Stop

							}

							Catch
							{

								$PSCMdlet.ThrowTerminatingError($_)

							}

						}

						'PSCustomObject'
						{

							if ($StorageVolumeTemplate.category -ne 'storage-volume-templates')
							{

								$ExceptionMessage = "The provided StorageVolumeTemplate {0} object is not the correct resource category  Please check the value and try again." -f $StorageVolumeTemplate.Name
								$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidStorageVolumeTemplateResource InvalidArgument 'StorageVolumeTemplate' -TargetType $StorageVolumeTemplate.GetType().Name -Message $ExceptionMessage
								$PSCMdlet.ThrowTerminatingError($ErrorRecord)

							}

							$_StorageVolumeTemplate = $StorageVolumeTemplate.PSObject.Copy()

						}

					}

					[Void]$_Query.Add(("volumeTemplateUri:'{0}'" -f $_StorageVolumeTemplate.uri))

				}

				$_Category = 'category=storage-volumes'

				# Build the final URI
				$_uri = '{0}?{1}&sort=name:asc&query={2}' -f $IndexUri, [String]::Join('&', $_Category), [String]::Join(' AND ', $_Query.ToArray())

				Try
				{

					$_ResourcesFromIndexCol = Get-AllIndexResources -Uri $_uri -ApplianceConnection $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($Available)
				{

					"[{0}] Looking for available volumes to attach." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Label | Write-Verbose

					if ($_ResourcesFromIndexCol -is [System.Collections.IEnumerable])
					{

						$_TempCollection = $_ResourcesFromIndexCol.Clone()

					}

					else
					{

						$_TempCollection = $_ResourcesFromIndexCol.PSObject.Copy()

					}

					ForEach ($_member in $_TempCollection)
					{

						if (-not $_member.isShareable)
						{

							# Check to see if there is an existing volume attachment
							Try
							{

								$_uri = '{0}?childUri={1}&name=server_profiles_to_storage_volumes' -f $AssociationsUri, $_member.uri

								$_VolAttachments = Send-HPOVRequest -Uri $_uri -Hostname $_appliance

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

							if ($_VolAttachments.count -gt 0)
							{

								"[{0}] Volume attachment found for {1}.  Removing from final collection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_member.name | Write-Verbose

								$_ResourcesFromIndexCol = $_ResourcesFromIndexCol | Where-Object name -ne $_member.name

							}							

						}

					}

				}

				if ($_ResourcesFromIndexCol.Count -eq 0)
				{
					
					if ($Name) 
					{ 
						
						"[{0}] '{1}' Storage Volume found." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

						$ExceptionMessage = "No Storage Volume with '{0}' name found on '{1}' appliance connection.  Please check the name or use New-HPOVStorageVolume to create the volume." -f $Name, $_appliance.Name
						$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException StorageVolumeResourceNotFound ObjectNotFound 'Name' -Message $ExceptionMessage 
						$PSCmdlet.WriteError($ErrorRecord)

					}

					else 
					{

						"[{0}] No Storage Volumes found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					}
							
				}
					
				else 
				{

					ForEach ($_member in $_ResourcesFromIndexCol)
					{ 

						$_member.PSObject.TypeNames.Insert(0,"HPOneView.Storage.Volume") 
						
						$_member
						
					} 	
					
				}

			}

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
