function Copy-HPOVServerProfile 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(
	
		[Parameter (Mandatory, ValueFromPipeline)]
		[Alias ('sname','src','SourceName')]
		[ValidateNotNullOrEmpty()]
		[object]$InputObject,
		
		[Parameter (Mandatory = $false)]
		[Alias ('dname','dst')]
		[string]$DestinationName,
		
		[Parameter (Mandatory = $false)]
		[object]$Assign = "unassigned",

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
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
		
		if($ApplianceConnection.count -gt 1)
		{
		
			# Check for appliance specific URI Parameters and error if more than one appliance connection supplied
			if (($InputObject -is [string]) -and ($InputObject.StartsWith($ServerProfilesUri))) 
			{
					
				"[{0}] InputObject is a Server Profile URI: $($InputObject)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				$ErrorRecord = New-ErrorRecord ArgumentNullException ParametersNotSpecified InvalidArgument 'InputObject' -Message "The input Parameter 'InputObject' is a URI. For multiple appliance connections this is not supported."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
			}

			if (($assign -is [string]) -and ($assign.StartsWith($ServerHardwareUri))) 
			{
				
				"[{0}] Assign is a Server Profile URI: $($SourceName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				$ErrorRecord = New-ErrorRecord ArgumentNullException ParametersNotSpecified InvalidArgument 'Assign' -Message "The input Parameter 'Assign' is a URI. For multiple appliance connections this is not supported."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

		}

		$taskCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		if (!$InputObject) 
		{ 
		
			$ErrorRecord = New-ErrorRecord ArgumentNullException ParametersNotSpecified InvalidArgument 'InputObject' -Message "The input Parameter 'InputObject' was Null. Please provide a value and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
		}

		if (($InputObject -is [string]) -and (!$InputObject.StartsWith($ServerProfilesUri))) 
		{
			
			"[{0}] InputObject is a Server Profile Name: $($InputObject)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			"[{0}] Getting Server Profile URI" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_Profile = Get-HPOVServerProfile -Name $InputObject -appliance $ApplianceConnection -ErrorAction Stop
				
				$profileSourceSHT = $_Profile.serverHardwareTypeUri

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		# Checking if the input is System.String and IS a URI - Should not Process on multi-appliance connections
		elseif (($InputObject -is [string]) -and ($InputObject.StartsWith($ServerProfilesUri))) 
		{
			
			"[{0}] InputObject is a Server Profile URI: $($InputObject)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_Profile = Send-HPOVRequest -uri $InputObject -appliance $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
			$profileSourceSHT = $_Profile.serverHardwareTypeUri
		
		}

		# Checking if source is object or object collection
		elseif (($InputObject -is [PSCustomObject]) -and ($InputObject.category -ieq $ResourceCategoryEnum.ServerProfile)) 
		{
			
			"[{0}] InputObject is a Server Profile object: $($InputObject.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			# For multi-appliance connections retrieve the source object only for this connection
			$_Profile = $InputObject.PSObject.Copy()

			$profileSourceSHT = $InputObject.serverHardwareTypeUri
		
		}

		else 
		{

			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message "The Parameter -InputObject value is invalid.  Please validate the InputObject Parameter value you passed and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($assign -ine 'unassigned') 
		{
			
			# Target Server is the server device name. Could be any empty bay assignment
			if (($assign -is [string]) -and (-not ($assign.StartsWith($ServerHardwareUri)))) 
			{
				
				# Get-HPOVServer needs to be in a try/catch since it may be an empty bay
				Try
				{
				
					$serverDevice = Get-HPOVServer -Name $assign -appliance $ApplianceConnection
					
				}
				
				Catch 
				{
				
					"[{0}] $($assign) server resource does not exist." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Check for empty bay assignment." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						if(!$serverDevice -and ($assign -match "bay"))
						{
							

							$assign = $assign.split(',').trim()

							try
							{

								$thisEnc = Get-HPOVEnclosure -Name $assign[0] -appliance $ApplianceConnection -ErrorAction Stop

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}
							
							[int]$thisBay = (($assign[1]) -replace "bay", "").trim()

							$presence = $thisEnc.deviceBays[($thisBay - 1)].devicePresence
							
							# If presence is null, invalid device bay
							if(!$presence) 
							{
							
								$ErrorRecord = New-ErrorRecord ArgumentNullException ParametersNotSpecified InvalidArgument 'Copy-HPOVProfile' -Message "The bay number $thisBay is not valid or not present."

								$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
							}
							
							else 
							{
							
								$_Profile.enclosureGroupUri = $thisEnc.uri
								$_Profile.enclosureBay = $thisBay
								$profileDestSHT = $profileSourceSHT
							
							} 
						
						}

						else 
						{
						
							$profileDestSHT = $serverDevice.serverHardwareTypeUri
							
						}
						
					}

					Catch 
					{
					
						$PSCmdlet.ThrowTerminatingError($_)
						
					}
						
				}					
				
			}

			# Checking if the input is System.String and IS a URI
			elseif (($assign -is [string]) -and ($assign.StartsWith($ServerHardwareUri))) 
			{
			
				"[{0}] Assign to the Server hardware URI: $($assign)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$serverDevice = Send-HPOVRequest $assign -appliance $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
									
				$profileDestSHT = $serverDevice.serverHardwareTypeUri
		
			}

			# Checking if the input is PSCustomObject, and the category type is server-profiles, which would be passed via pipeline input
			elseif (($assign -is [PSCustomObject]) -and ($assign.category -ieq "server-hardware")) 
			{
				
				"[{0}] Assign to the Server object: $($assign.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$serverDevice = $assign | Where-Object { $_.applianceConnection.name -eq $ApplianceConnection.name }
				$profileDestSHT = $serverDevice.serverHardwareTypeUri
		
			}

			else 
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Copy-HPOVProfile' -Message "The Parameter -Assign value is invalid.  Please validate the Assign Parameter value you passed and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			# Checking if the input is PSCustomObject, and the category type is server-hardware, which would be passed via pipeline input
			if ($serverDevice.serverProfileUri) 
			{

				$ExceptionMessage = "A server profile is already assigned to {0} ({1}). Please try specify another server." -f $serverDevice.name, (Send-HPOVRequest $serverDevice.serverProfileUri -appliance $ApplianceConnection).name
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerPropfileResourceAlreadyExists ResourceExists 'ServerProfile' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)                
		
			}

		}

		elseif ($assign -ieq "unassigned") 
		{
			
			"[{0}] Server will be unassigned" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		# Check to see if the SHT is different from the Profile and Target Assign Server
		if (($profileDestSHT -ine $profileSourceSHT) -and ($assign -ine "unassigned") -and (!$_Profile.enclosureBay))
		{
		
			$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerHardwareTypeMismatch InvalidOperation 'Copy-HPOVProfile' -Message "The Target Server Hardware Type does not match the source Profile Server Hardware Type. Please specify a different Server Hardware Device to assign."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)          
				
		}

		# Remove Profile Specifics:
		$_Profile = $_Profile | select-object -Property * -excludeproperty uri,etag,created,modified,uuid,status,state,inprogress,serialNumber,enclosureUri,enclosureBay,serverHardwareUri,taskUri #,sanStorage

		$newConnections = New-Object System.Collections.ArrayList
		# Create new connections with excluded properties and add to the newConnections array

		'[{0}] Rebuilding fabric connections' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		$_Profile.connectionSettings.connections | select-object -property * -excludeproperty mac,wwnn,wwpn,deploymentstatus,interconnectUri, applianceConnection | ForEach-Object {
		
			# Assign the newConnections array to $_Profile.connections
			[void]$newConnections.Add($_)
		
		}

		$_Profile.connectionSettings.connections = $newConnections

		# Null compliant property
		$_Profile.templateCompliance = $null

		# Process SAN Volume Attachments
		if ($_Profile.sanStorage -and $_Profile.sanStorage.volumeAttachments) 
		{ 

			$newVolumeAttachments = @()
		
			"[{0}] Processing SAN Volume Attachments" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			ForEach ($attachVolume in $_Profile.sanStorage.volumeAttachments ) 
			{

				$tempVolume = [PSCustomObject]@{}
		
				"[{0}] Found attached volume ID $($attachVolume.id). Getting Volume properties." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$volume = Send-HPOVRequest $attachVolume.volumeUri -appliance $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				# Process shared volume
				if ($volume.shareable) 
				{
		
					"[{0}] Adding Shareable Volume." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$tempVolume = $attachVolume | Select-Object id,volumeUri,lunType,lun,storagePaths
					$tempVolume.lun = $Null
					$tempVolume.storagePaths = ($attachVolume.storagePaths | ForEach-Object { $_ | select-object * -exclude status } )

				}

				# Process private volume
				else 
				{

					"[{0}] Adding Private Volume." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Checking for unique volume name." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# Get list of existing volumes from Index
					
					Try
					{
						
						$indexVolumes = Send-HPOVRequest ($indexUri + "?category=storage-volumes&count=-1&start=0&sort=name:asc") -appliance $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$regex = " \((([0-9]|[1-9][0-9]|[1-9][0-9][0-9])+)\)"

					$tempVolumeName = $volume.name -replace $regex,""

					for ($i = 1; $i -le $volume.name.length; $i++) 
					{
					
						if (-not ($indexVolumes.members -contains ($tempVolumeName + " ($i)"))) 
						{
		
							$attachVolumeName = $tempVolumeName + " ($i)"
							
							# Verify the name is unique by searching the index.
							Try
							{
							
								$results = Send-HPOVRequest ($indexUri + "?category=storage-volumes&filter=name='$attachVolumeName'&count=-1&start=0&sort=name:asc") -appliance $ApplianceConnection
							
							}
							
							Catch
							{
							
								$PSCmdlet.ThrowTerminatingError($_)
							
							}

							if ($results.count -eq 0) 
							{	

								"[{0}] Setting Volume Name to '$attachVolumeName'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
								break

							}

						}

					}

					$tempVolume | Add-Member -NotePropertyName id -NotePropertyValue $attachVolume.id
					$tempVolume | Add-Member -NotePropertyName volumeName -NotePropertyValue $attachVolumeName
					$tempVolume | Add-Member -NotePropertyName volumeUri -NotePropertyValue $Null
					$tempVolume | Add-Member -NotePropertyName volumeStoragePoolUri -NotePropertyValue $attachVolume.volumeStoragePoolUri 
					$tempVolume | Add-Member -NotePropertyName volumeStorageSystemUri  -NotePropertyValue $attachVolume.volumeStorageSystemUri 
					$tempVolume | Add-Member -NotePropertyName volumeProvisionType  -NotePropertyValue $volume.provisionType
					$tempVolume | Add-Member -NotePropertyName volumeProvisionedCapacityBytes  -NotePropertyValue $volume.provisionedCapacity
					$tempVolume | Add-Member -NotePropertyName volumeShareable   -NotePropertyValue $False
					$tempVolume | Add-Member -NotePropertyName lunType   -NotePropertyValue $attachVolume.lunType
					
					if ($attachVolume.lunType -eq "Auto") { $tempVolume | Add-Member -NotePropertyName lun  -NotePropertyValue $Null }
					else { $tempVolume | Add-Member -NotePropertyName lun  -NotePropertyValue $attachVolume.lun }
					
					$tempVolume | Add-Member -NotePropertyName storagePaths  -NotePropertyValue ($attachVolume.storagePaths | ForEach-Object { $_ | select-object * -exclude status } )
					$tempVolume | Add-Member -NotePropertyName permanent -NotePropertyValue $volume.isPermanent

				}

				# "[{0}] Copied volume details: $($tempVolume | Format-List * )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$newVolumeAttachments += $tempVolume

			}

			$_Profile.sanStorage.volumeAttachments = $newVolumeAttachments

		}

		# Need to parse through local storage policies to null out Logical Drive ID
		if ($_Profile.localStorage.controllers.Count -gt 0)
		{

			ForEach ($_controller in $_Profile.localStorage.controllers)
			{

				For ($_ld = 0; $_ld -lt $_controller.logicalDrives.Count; $_ld++)
				{

					'[{0}] Setting "{1}" Controller Logical Drive "{2}" drive number to null' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_controller.deviceSlot, $_controller.logicalDrives[$_ld].name | Write-Verbose

					$_controller.logicalDrives[$_ld].driveNumber = $null

				}

			}

		}

		# Set iscsiInitiatorName to null
		$_Profile.iscsiInitiatorName = $null

		# If DestinationName is provided, change to the profile name to value
		if ($DestinationName) 
		{

			"[{0}] New Server Profile name provided $($DestinationName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			$_Profile.name = $destinationName
		
		}
		
		# If no DestinationName is provided, add "Copy Of " prefix.
		else 
		{

			"[{0}] No new Server Profile name provided. Setting to `"Copy of $($_Profile.name)`"" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			$_Profile.name = "Copy of {0}" -f $_Profile.name

		}

		# If the server hardware device is present, add the property to the object
		if ($serverDevice) 
		{

			$_Profile | Add-Member @{ serverHardwareUri = $serverDevice.Uri }
		
		}

		# "[{0}] New Server Profile object: $($_Profile | Format-List * )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		# Send request to create new copied profile
		"[{0}] Sending request"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		Try
		{
		
			$Resp = Send-HPOVRequest -Uri $ServerProfilesUri -Method POST -Body $_Profile -appliance $ApplianceConnection

			Try
			{

				$Resp = $Resp | Wait-HPOVTaskStart

				if ($Resp.taskState -eq 'Error')
				{

					if ($Resp.taskErrors.message -match 'The selected server hardware has health status other than "OK"' -and 
						$PSCmdlet.ShouldProcess($serverDevice.name, 'The selected server hardware has health status other than "OK". Do you wish to override and assign the Server Profile'))
					{

						Try
						{
						
							$_Uri = '{0}?force=all' -f $ServerProfilesUri

							$Resp = Send-HPOVRequest -Uri $_Uri -Method POST -Body $_Profile -Hostname $ApplianceConnection
				
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
		
		}
		
		Catch
		{
		
			$PSCmdlet.ThrowTerminatingError($_)
		
		}
		
		$resp

	}

	End 
	{
		
		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
