function Get-HPOVServerProfile 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = "Detailed")]
		[Parameter (Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = "Export")]
		[Alias ('profile')]
		[string]$Name,

		[Parameter (Mandatory, ValueFromPipeline = $false, ParameterSetName = "Detailed")]
		[switch]$Detailed,

		[Parameter (Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = "Default")]
		[switch]$NonCompliant,

		[Parameter (Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = "Export")]
		[switch]$Unassigned,

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "Export")]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "Detailed")]
		[Parameter (Mandatory = $false, ParameterSetName = "Export")]
		[ValidateNotNullOrEmpty()]
		[String]$Label,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "Detailed")]
		[Parameter (Mandatory = $false, ParameterSetName = "Export")]
		[ValidateNotNullOrEmpty()]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (Mandatory = $false, ParameterSetName = "Default", ValueFromPipelinebyPropertyName)]
		[Parameter (Mandatory = $false, ParameterSetName = "Detailed", ValueFromPipelinebyPropertyName)]
		[Parameter (Mandatory = $false, ParameterSetName = "Export", ValueFromPipelinebyPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),
		
		[Parameter (Mandatory, ValueFromPipeline = $false, ParameterSetName = "Export")]
		[Alias ("x")]
		[switch]$export,

		[Parameter (Mandatory, ValueFromPipeline = $false, ParameterSetName = "Export")]
		[ValidateNotNullOrEmpty()]
		[Alias ("save")]
		[string]$location

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		# Validate the path exists.  If not, create it.
		if (($Export) -and (-not(Test-Path $Location)))
		{ 
		
			"[{0}] Directory does not exist.  Creating directory..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			New-Item -path $Location -ItemType Directory
		
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

		$ProfileCollection = New-Object System.Collections.ArrayList

	}

	Process 
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

			if ($PSBoundParameters['NonCompliant'])
			{

				"[{0}] Filtering for non-compliant profiles." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[Void]$_Query.Add("templateCompliance:'NonCompliant'")

			}

			$_Category = 'category={0}' -f $ResourceCategoryEnum.ServerProfile

			# Build the final URI
			$_uri = '{0}?{1}&sort=name:asc&query={2}' -f $IndexUri,  [String]::Join('&', $_Category), [String]::Join(' AND ', $_Query.ToArray())

			Try
			{

				[Array]$_ResourcesFromIndexCol = Get-AllIndexResources -Uri $_uri -ApplianceConnection $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($PSBoundParameters['Unassigned']) 
			{

				$_ResourcesFromIndexCol = $_ResourcesFromIndexCol | Where-Object $null -eq serverHardwareUri

			}

			if ($PSBoundParameters['InputObject'])
			{

				"[{0}] Processing InputObject property." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				switch ($InputObject.category)
				{

					$ResourceCategoryEnum.ServerHardware
					{

						"[{0}] Filtering for Server Hardware resource '{1}' assigned to a server profile." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

						if ($InputObject.serverProfileUri)
						{
						
							"[{0}] Resource is assigned to a server profile." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$_ResourcesFromIndexCol = $_ResourcesFromIndexCol | Where-Object serverHardwareUri -eq $InputObject.uri

						}

						else
						{

							"[{0}] Resource is not assigned to a server profile.  Filtering based on ServerHardwareType" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$_ResourcesFromIndexCol = $_ResourcesFromIndexCol | Where-Object serverHardwareTypeUri -eq $InputObject.serverHardwareTypeUri

						}

					}

					$ResourceCategoryEnum.ServerHardwareType
					{

						"[{0}] Filtering for Server Hardware Type: {1} [{2}]"  -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.model | Write-Verbose

						$_ResourcesFromIndexCol = $_ResourcesFromIndexCol | Where-Object serverHardwareTypeUri -eq $InputObject.uri

					}

					$ResourceCategoryEnum.ServerProfileTemplate
					{

						"[{0}] Filtering for Server Profile Template: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

						$_ResourcesFromIndexCol = $_ResourcesFromIndexCol | Where-Object serverProfileTemplateUri -eq $InputObject.uri

					}

				}

			}

			if ($_ResourcesFromIndexCol.count -eq 0 -and $Name)
			{

				"[{0}] Profile Resource Name '{1}' was not found on appliance {2}.  Generate Error." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name, $_appliance.Name | Write-Verbose

				$Exceptionmessage = "The specified Server Profile '{0}' was not found on '{1}' appliance connection. Please check the name again, and try again." -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerProfileResourceNotFound ObjectNotFound "Name" -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			foreach ($_member in $_ResourcesFromIndexCol)
			{
			
				$_member.PSObject.TypeNames.Insert(0,'HPOneView.ServerProfile')
					
				[void]$ProfileCollection.Add($_member)
				
			}

		}

	}

	End 
	{

		$ProfileCollection = $ProfileCollection | Sort-Object name

		"Done. {0} server profile resource(s) found." -f $ProfileCollection.count | Write-Verbose 

		if ($PSBoundParameters['Detailed']) 
		{

			# Display Pertinant Server Profile data in Table format
			$a1 = @{Expression={$_.name};Label="Name"},
				  @{Expression={$profileCache[$serverHardwareTypeUri].name};Label="Server Hardware Type"},
				  @{Expression={ if ($profileCache[$enclosureGroupUri]) {$profileCache[$enclosureGroupUri]}
								 else { 'N/A' }
								};Label="Enclosure Group"},
				  @{Expression={	if ($_.serverHardwareUri){ (Send-HPOVRequest $_.serverHardwareUri).name }
				 				else { "Unassigned" }
								 };Label="Assigned"},
				  @{Expression={
				  
						 switch ($_.affinity) {
				  
							 "Bay" { "Device bay" }
							 "BayAndServer" { "Device bay + Server Hardware" }
				  
				  
						 }
				  
				  };Label="Server Affinity"},
				  @{Expression={$_.state};Label="State"},
				  @{Expression={$_.status};Label="Status"}

			$a2 = @{Expression={$_.bios.manageBios};Label="Manage BIOS";align="Left"},
				  @{Expression={$_.boot.manageBoot};Label="Manage Boot Order";align="Left"},
				  @{Expression={$_.firmware.manageFirmware};Label="Manage Firmware";align="Left"},
				  @{Expression={if ($_.serialNumberType -eq "Virtual") { $_.serialNumber + " (v)" } else { $_.serialNumber + " (p)" }};Label="Serial Number"},
				  @{Expression={if ($_.serialNumberType -eq "Virtual") { $_.uuid + " (v)" } else { $_.uuid + " (p)" }};Label="UUID"}


			# Firmware Details
			$f = @{Expression={
				if ($_.firmware.manageFirmware) {

					$baseline = Send-HPOVRequest $_.firmware.firmwareBaselineUri
					"$($baseline.name) version $($baseline.version)"

				}
				else { "none" }
			
			};Label="Firmware Baseline"}

			$c = @{Expression={$_.id};Label="ID";width=2},
				 @{Expression={$_.functionType};Label="Type";width=12},
				 @{Expression={
				   
				   $address = @()
				 
				   # Mac Address
				   if ($_.macType -eq "Virtual" -and $_.mac) { $address += "MAC $($_.mac) (V)" }
				   elseif ($_.macType -eq "Physical" -and $_.mac) { $address += "MAC $($_.mac) (p)" }
				   
				   # WWNN
				   if ($_.wwpnType -eq "Virtual" -and $_.wwnn) { $address += "WWNN $($_.wwnn) (v)"} 
				   elseif ($_.wwpnType -eq "Physical" -and $_.wwnn) { $address += "WWNN $($_.wwnn) (p)" }
				   
				   # WWPN
				   if ($_.wwpnType -eq "Virtual" -and $_.wwpn) { $address += "WWPN $($_.wwpn) (v)"} 
				   elseif ($_.wwpnType -eq "Physical" -and $_.wwpn) { $address += "WWPN $($_.wwpn) (p)" }

				   $addressCol = $address | Out-String | ForEach-Object { $_ -replace '^\s+|\s+$' }
				   $addressCol
				   
				 };Label="Address";width=32},
				 @{Expression={$profileCache[$_.networkUri]};Label="Network"},
				 @{Expression={$_.portId};Label="Port Id";width=10},
				 @{Expression={[string]$_.requestedMbps};Label="Requested BW";width=12},
				 @{Expression={[string]$_.maximumMbps};Label="Maximum BW";width=10},
				 @{Expression={
				 
					  $bootSetting = @()
					  $bootSetting += $_.boot.priority
					  if ($_.boot.targets) {
				 
						   for ($i=0; $i -eq $boot.targets.count; $i++) { $bootSetting += "WWN $($_.boot.targets[$i].arrayWwpn)`nLUN $($_.boot.targets[$i].lun)" }
				 
					  }
					  $bootSettingString = $bootSetting | Out-String | ForEach-Object { $_ -replace '^\s+|\s+$' }
					  $bootSettingString
				 
				   
				  };Label="Boot";width=20},
				 @{Expression={
				 
					if ($_.functionType -eq "FibreChannel" -and -not ($_.boot.targets)) { "Yes" } 
					elseif ($_.functionType -eq "FibreChannel" -and $_.boot.targets) { "No" }
					else { $Null }
				 
				  };Label="Use Boot BIOS";width=13}
							   
			# Display extEnded BIOS settings
			$b = @{Expression={$_.category};Label="BIOS Category"},
				 @{Expression={$_.settingName};Label="Setting Name"},
				 @{Expression={$_.valueName};Label="Configured Value"}

			$ls = @{Expression={$_.localStorage.manageLocalStorage};Label="Manage Local Storage";align="Left"},
				  @{Expression={$_.localStorage.initialize};Label="Initialize Disk";align="Left"},
				  @{Expression={
				  
						$logicalDriveCol = @()
						$d=0

						while ($d -lt $sp.localStorage.logicalDrives.count) 
						{

							if ($_.localStorage.logicalDrives[$d].bootable) { $logicalDriveCol += "Drive {$d} $($sp.localStorage.logicalDrives[$d].raidLevel) (Bootable)" }
							else { $logicalDriveCol += "Drive {$d} $($sp.localStorage.logicalDrives[$d].raidLevel)" }
							$d++
						}

						$logicalDriveString = $logicalDriveCol | Out-String | ForEach-Object { $_ -replace '^\s+|\s+$' }
						$logicalDriveString
					
				   };Label="Logical Disk"}

			$ss = @{Expression={$_.manageSanStorage};Label="Manage SAN Storage";align="Left"},
				  @{Expression={$_.hostOSType};Label="Host OS Type";align="Left"}

			$p = @{Expression={[int]$_.connectionId};Label="Connection ID";align="Left"},
				 @{Expression={[string]$_.network};Label="Fabric";align="Left"},
				 @{Expression={[string]$_.initiator};Label="Initiator";align="Left"},
				 @{Expression={[string]$_.target};Label="Target";align="Left"},
				 @{Expression={[bool]$_.isEnabled};Label="Enabled";align="Left"}

			# Server Profile cache
			$profileCache = @{}
			
			# Loop through all Server Profile objects and display details
			ForEach ($profile in ($ProfileCollection | sort-object -property name)) 
			{

				$serverHardwareTypeUri = $profile.serverHardwareTypeUri
				$enclosureGroupUri = $profile.enclosureGroupUri

				# Cache resources during runtime to reduce API calls to appliance.
				if (-not ($profileCache[$serverHardwareTypeUri])) 
				{ 

					Try
					{

						$_Sht = Send-HPOVRequest -Uri $serverHardwareTypeUri -appliance $profile.ApplianceConnection.name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}					

					$profileCache.Add($serverHardwareTypeUri, $_Sht.name) 

				}

				if (-not ($profileCache[$enclosureGroupUri]) -and $profile.enclosureGroupUri) 
				{

					Try
					{

						$_EG = Send-HPOVRequest -Uri $enclosureGroupUri -appliance $profile.ApplianceConnection.name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$profileCache.Add($enclosureGroupUri, $_EG.name) 

				}

				foreach ($connection in $profile.connectionSettings.connections) 
				{
				
					$connection | ForEach-Object { $_.psobject.typenames.Insert(0,"HPOneView.Profile.Connection") }

					if (-not ($profileCache[$connection.networkUri])) 
					{ 

						Try
						{

							$_Net = Send-HPOVRequest -Uri $connection.networkUri -appliance $profile.ApplianceConnection.name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}
						
						$profileCache.Add($connection.networkUri, $_Net.name) 
					
					} 
				
				}

				foreach ($volume in $profile.sanStorage.volumeAttachments)
				 {

					# Insert HPOneView.Profile.SanVolume TypeName
					$volume | ForEach-Object { $_.psobject.typenames.Insert(0,"HPOneView.Profile.SanVolume") }
	
					# Cache Storage System, Storage Pool and Storage Volume Resources
					if (-not ($profileCache[$volume.volumeStorageSystemUri])) { $profileCache.Add($volume.volumeStorageSystemUri,(Send-HPOVRequest $volume.volumeStorageSystemUri $profile.ApplianceConnection.name)) }
					if (-not ($profileCache[$volume.volumeStoragePoolUri])) { $profileCache.Add($volume.volumeStoragePoolUri,(Send-HPOVRequest $volume.volumeStoragePoolUri $profile.ApplianceConnection.name)) }
					if (-not ($profileCache[$volume.volumeUri])) { $profileCache.Add($volume.volumeUri,(Send-HPOVRequest $volume.volumeUri $profile.ApplianceConnection.name)) }

				}

				#$profileCache

				# Initial Server Profile information
				$profile | format-table $a1 -AutoSize -wrap
				$profile | format-table $a2 -AutoSize -wrap

				# Firmware Baseline
				$profile | format-table $f

				# Server Profile Connection details
				$profile.connectionSettings.connections | format-table -wrap
				
				# Local Storage
				$profile | format-table $ls -wrap -auto

				# SAN Storage
				$profile.sanStorage | Format-Table $ss -auto
				#$profile.sanStorage.volumeAttachments | format-table -auto

				$profile.sanStorage.volumeAttachments | ForEach-Object {

					$_ | format-table -auto

					$pathConnectionCol = @()

					foreach ($path in $_.storagePaths) 
					{

						$pathObject = [PSCustomObject]@{
							connectionId = $Null; 
							network      = $Null; 
							initiator    = $Null; 
							target       = $Null; 
							isEnabled    = $Null
						}

						$pathConnection = $profile.connectionSettings.connections | Where-Object { $path.connectionId -eq $_.id }

						$pathObject.connectionId = $pathConnection.id
						$pathObject.network      = $profileCache[$pathConnection.networkUri]
						$pathObject.initiator    = $pathConnection.wwpn
						$pathObject.target       = if ($path.storageTargets) { $path.storageTargets }
												   else { "PEnding" }
						$pathObject.isEnabled    = [bool]$path.isEnabled
						$pathConnectionCol += $pathObject

					}

					#
					# Display path details with a left padded view. Format-Table doesn't have the ability to pad the display
					$capture = ($pathConnectionCol | Sort-Object connectionId | format-table $p -AutoSize -wrap | out-string) -split "`n"
					$capture | ForEach-Object { ($_).PadLeft($_.length + 5) }

				}

				#Boot Order
				$bootOrder = @()
				if ($profile.boot.manageBoot) 
				{

					$i = 0
					while ($i -lt $profile.boot.order.count) 
					{
						$bootOrder += "$($i+1) $($profile.boot.order[$i])"
						$i++
					}
					write-host "Boot Order"
					write-host "----------"
					$bootOrder

				}
				else 
				{ 

					"No Boot Management" 
				
				}

				# Display configured BIOS Settings from profile
				$configedBiosSettings = @()

				foreach ($setting in $profile.bios.overriddenSettings) 
				{

					$shtBiosSettingDetails = $profileCache[$serverHardwareTypeUri].biosSettings | Where-Object { $setting.id -eq $_.id }

					$biosSetting = [PSCustomObject]@{

						Category = $shtBiosSettingDetails.category;
						settingName = $shtBiosSettingDetails.name;
						valueName = ($shtBiosSettingDetails.options | Where-Object { $_.id -eq $setting.value } ).name;

					}

					$configedBiosSettings += $biosSetting
				
				}            
			
				$configedBiosSettings | Sort-Object category,settingName | format-list $b

				"----------------------------------------------------------------------"
			
			}

		}

		# If user wants to export the profile configuration
		elseif ($export) 
		{

			# Get the unique applianceConnection.name properties from the profile collection for grouping the output files
			$ProfileGroupings = $ProfileCollection.ApplianceConnection.name | Select-Object -Unique

			ForEach ($pg in $ProfileGroupings)
			{
				
				$outputProfiles = New-Object System.Collections.ArrayList

				$profiles = $ProfileCollection | Where-Object {$_.ApplianceConnection.Name -eq $pg}

				# Loop through all profiles
				foreach ($profile in $profiles) 
				{

					# Trim out appliance unique properties

					$_profile = $profile | select-object -Property * -excludeproperty uri,etag,created,modified,status,state,inprogress,enclosureUri,enclosureBay,serverHardwareUri,taskUri,ApplianceConnection
					$_profile.serialNumberType = "UserDefined"

					# Loop through the connections to save the assigned address
					$i = 0
					foreach ($connection in $profile.connectionSettings) 
					{

						if ($profile.connectionSettings.connections[$i].mac) 
						{ 
							
							$_profile.connectionSettings.connections[$i].macType = "UserDefined" 
						
						}

						if ($profile.connectionSettings.connections[$i].wwpn) 
						{ 
							
							$_profile.connectionSettings.connections[$i].wwpnType = "UserDefined" 
						
						}
						
						$i++

					}

					[void]$outputProfiles.Add($_profile)
					
				}

				# Save profile to JSON file
				"[{0}] Saving $($_profile.name) to $($location)\$($_profile.name).json" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				convertto-json -InputObject $outputProfiles -depth 99 | new-item "$location\$pg`_$($_profile.name).json" -itemtype file

			}

		}

		else 
		{

			Return $ProfileCollection

		}

	}

}
