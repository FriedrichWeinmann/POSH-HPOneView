function Get-EnclosureFirmware 
{

	<#
		Internal-only function.
	#>

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(
	
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateScript({
			if ($_.category -ne 'enclosures') 
			{ 
				
				Throw ("The resource object provided is not an Enclosure Resource.  Expected category 'enclosures', Received '{0}' [{1}]." -f $_.category, $_.name)
			}

			else
			{

				$True

			}
		
		})]
		[PsCustomObject]$Enclosure, 

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[object]$Baseline,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[int]$ProgressID = 0
		
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		# Reset private variables
		$_BaseLinePolicy  = $Null
		$_EnclosureReport = New-Object System.Collections.ArrayList

		# Keep track of the number of Servers
		$_s = 0

		# Keep track of the number of Interconnects
		$_i = 0
		
		# Keep track of the number of OAs
		$_o = 0

		# Keep track of the number of composable infrastructure appliances
		$_cia = 0
		# See if EnclosureObject was passed via Pipeline
		if (-not $PSBoundParameters['Enclosure']) 
		{ 
			
			$PipelineInput = $True 
		
		}

	}

	Process 
	{
		
		"[{0}] Enclosure Object passed via pipeline: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [bool]$PipelineInput | Write-Verbose
		"[{0}] Processing Enclosure firmware report for: '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Enclosure.name | Write-Verbose

		# Use the Enclosure FwBaseline if it is set
		if (($Enclosure.isFwManaged) -and ($null -eq $Baseline)) 
		{ 

			Try
			{

				$BaseLinePolicy = Send-HPOVRequest -Uri $Enclosure.fwBaselineUri -Hostname $Enclosure.ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		elseif (($Baseline) -and ($Baseline -is [PsCustomObject]) -and ($Baseline.category -eq $ResourceCategoryEnum['Baseline'])) 
		{ 
		
			"[{0}] Baseline resource passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			"[{0}] Baseline resource name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline.name | Write-Verbose
			"[{0}] Baseline resource uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline.uri | Write-Verbose

			$BaseLinePolicy = $Baseline
			
		}
		
		# Check to see if the wrong Object has been passed
		elseif (($Baseline) -and ($Baseline -is [PsCustomObject]) -and ($Baseline.category -ne "firmware-drivers")) 
		{ 
		
			"[{0}] Invalid Baseline resource passed. Generating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$ExceptionMessage = "An invalid Baseline Object was passed.  Expected Category type 'firmware-drivers', received '{0}' (Object Name: {1}" -f $Baseline.category, $Baseline.name
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidBaselineResouce InvalidArgument 'Baseline' -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
		}
		
		elseif (($Baseline) -and ($Baseline -is [string]) -and ($Baseline.StartsWith(($ApplianceFwDriversUri)))) 
		{ 
			
			"[{0}] Baseline URI passed: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline | Write-Verbose

			Try
			{

				$BaseLinePolicy = Send-HPOVRequest -Uri $Baseline -Hostname $Enclosure.ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
		
		}
		
		# Check to see if the wrong URI has been passed
		elseif (($Baseline) -and ($Baseline -is [string]) -and $Baseline.StartsWith("/rest/") -and ( -not $Baseline.StartsWith(($ApplianceBaselineRepoUri)))) 
		{ 
		
			"[{0}] Invalid Baseline URI passed. Generating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$ExceptionMessage = "An invalid Baseline URI was passed.  URI must start with '/rest/firmware-drivers/', received '{0}'" -f $Baseline
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidBaselineValue InvalidArgument 'Baseline' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)        
			
		}
		
		elseif (($Baseline) -and ($Baseline -is [string])) 
		{ 
		
			"[{0}] Baseline Name passed: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline | Write-Verbose

			Try
			{

				$FirmwareBaslineName = $Baseline.Clone()

				$BaseLinePolicy = Get-HPOVBaseline -name $Baseline -ErrorAction SilentlyContinue

				If (-not $BaseLinePolicy)
				{

					$ExceptionMessage = "The provided Baseline '{0}' was not found." -f $FirmwareBaslineName
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'Baseline' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
		}
		
		else 
		{ 
		
			"[{0}] No Baseline provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$BaseLinePolicy = [PsCustomObject]@{ baselineShortName = "NoPolicySet" } 
		
		}

		# Process shared infrastructure components based on enclosure type
		# If C-Class, attach to XML interface to get OA module information.  Will need to override SslValidator checks
		Switch ($Enclosure.enclosureType)
		{

			'C7000'
			{

				# Process OAs first
				ForEach ($_oa in $Enclosure.managerbays)
				{

					if ($_oa.devicePresence -ne 'Absent')
					{

						$_o ++

						$_ProgressParams = @{

							id               = (2 + $ProgressID);
							ParentId         = 1;
							activity         = "Collecting Enclosure Manager Firmware Information";
							CurrentOperation = ("[{0}/{1}] Processing '{2}'" -f $_o, $Enclosure.managerBays.count, $_oa.role);
							percentComplete  = (($_o / $Enclosure.managerBays.count) * 100) 

						}

						# Handle the call from -Verbose so Write-Progress does not get borked on display.
						if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
						{ 
							
							"[{0}] Collecting Enclosure Manager Firmware Information - Skipping Write-Progress display: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ProgressParams | Out-String) | Write-Verbose
						
						}
						
						else 
						{ 
							
							Write-Progress @_ProgressParams
						
						}

						if ($BaseLinePolicy.baselineShortName -eq "NoPolicySet") 
						{ 
							
							$BaselineVer = "N/A" 
							$BaselineName  = "N/A" 
							$BaselineUri = $null
						
						}

						else 
						{ 
							
							$_BaselineVersions = $BaseLinePolicy.fwComponents | Where-Object KeyNameList -contains "oa"

							$_BaselineVer = GetNewestVersion -Collection $_BaselineVersions
							$BaselineName = $Baseline.description
							$BaselineUri  = $Baseline.uri
						
						}

						"[{0}] Adding '{1}, OA {2}' to firmware report collection" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Enclosure.name, $_oa.bayNumber | Write-Verbose

						$_EnclosureDeviceReport = New-Object HPOneView.Servers.Enclosure+Firmware(("{0}, OA {1}" -f $Enclosure.name, $_oa.bayNumber),
																						'OnboardAdministrator',
																						'Firmware',
																						$_oa.fwVersion,
																						$_BaselineVer,
																						$BaselineName,
																						$BaselineUri,
																						$Enclosure.name,
																						$Enclosure.uri,
																						$Enclosure.ApplianceConnection)

						[void]$_EnclosureReport.Add($_EnclosureDeviceReport)

					}

					else
					{

						"[{0}] Onboard Administrator device bay {1} is absent." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_o | Write-Verbose

					}					
					
				}

			}

			'SY12000'
			{

				# Process FLMs first
				ForEach ($_em in $Enclosure.managerbays)
				{

					$_o ++

					$_ProgressParams = @{

						id               = (2 + $ProgressID);
						ParentId         = 1;
						activity         = "Collecting Enclosure Manager Firmware Information";
						CurrentOperation = ("[{0}/{1}] Processing '{2}'" -f $_o, $Enclosure.managerBays.count, $_em.role);
						percentComplete  = (($_o / $Enclosure.managerBays.count) * 100) 

					}

					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{ 
						
						"[{0}] Collecting Enclosure Manager Firmware Information - Skipping Write-Progress display: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ProgressParams | Out-String) | Write-Verbose
					
					}
					
					else 
					{ 
						
						Write-Progress @_ProgressParams
					
					}

					if ($BaseLinePolicy.baselineShortName -eq "NoPolicySet") 
					{ 
						
						$BaselineVer = "N/A" 
						$BaselineName  = "N/A" 
						$BaselineUri = $null
					
					}

					else 
					{ 
						
						$_BaselineVersions = $BaseLinePolicy.fwComponents | Where-Object KeyNameList -Contains "em"

						$_BaselineVer = GetNewestVersion -Collection $_BaselineVersions
						$BaselineName  = $Baseline.description
						$BaselineUri = $Baseline.uri
					
					}

					$_EnclosureDeviceReport = New-Object HPOneView.Servers.Enclosure+Firmware(("{0} (Bay {1})" -f $_em.model.Trim(), $_em.bayNumber),
																					  'EnclosureManager',
																					  'Firmware',
																					  $_em.fwVersion,
																					  $_em.serialNumber,
																					  $_em.partNumber,
																					  $_BaselineVer,
																					  $BaselineName,
																					  $BaselineUri,
																					  $Enclosure.name,
																					  $Enclosure.uri,
																					  $Enclosure.ApplianceConnection)

					[void]$_EnclosureReport.Add($_EnclosureDeviceReport)

				}

				ForEach ($_appliance in ($Enclosure.applianceBays | Where devicePresence -ne 'Absent'))
				{

					$_cia ++

					$_ProgressParams = @{

						id               = (3 + $ProgressID);
						ParentId         = 1;
						activity         = "Collecting Composable Infrastructure appliance firmware information";
						CurrentOperation = ("[{0}/{1}] Processing '{2}'" -f $_cia, $Enclosure.applianceBays.count, $_appliance.model);
						percentComplete  = (($_cia / $Enclosure.applianceBays.count) * 100) 

					}

					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{ 
						
						"[{0}] Collecting Enclosure Manager Firmware Information - Skipping Write-Progress display: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ProgressParams | Out-String) | Write-Verbose
					
					}
					
					else 
					{ 
						
						Write-Progress @_ProgressParams
					
					}

					$_applianceSerialNumber  = $_appliance.serialNumber
					$_appliancePartNumber    = $_appliance.partNumber

					# Get installed firmware
					switch ($_appliance.Model)
					{

						# need to figure out how to support both DCS and real hardware.  
						{$_ -match 'Composer'}
						{

							# if ($null -ne $_appliance.serialNumber)
							# {

							# 	$uri = '{0}/{1}' -f $ApplianceHANodesUri, $_appliance.serialNumber

							# 	Try
							# 	{

							# 		$_applianceDetails = Send-HPOVRequest -Uri $uri -Hostname $Enclosure.ApplianceConnection
							# 		$_applianeFirmareVersion = $_applianceDetails.version

							# 	}

							# 	Catch
							# 	{

							# 		$PSCmdlet.ThrowTerminatingError($_)

							# 	}

							# }
							
							# # This is for DCS
							# else
							# {

								$_applianeFirmareVersion = $PSLibraryVersion.($Enclosure.ApplianceConnection.Name).ApplianceVersion
								

							# }
							
						}

						{$_ -match 'Image Streamer'}
						{

							Try
							{

								$uri = "{0}?filter=applianceSerialNumber eq '{1}'" -f $AvailableDeploymentServersUri, $_appliance.serialNumber
								$_applianceDetails = Send-HPOVRequest -Uri $uri -Hostname $Enclosure.ApplianceConnection
								$_applianeFirmareVersion = $_applianceDetails.members.imageStreamerVersion

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

						}

					}

					$_EnclosureDeviceReport = New-Object HPOneView.Servers.Enclosure+Firmware(("{0} (Bay {1})" -f $_appliance.Model, $_appliance.bayNumber),
																					  'ApplianceDevice',
																					  'Firmware',
																					  $_applianeFirmareVersion,
																					  $_applianceSerialNumber,
																					  $_appliancePartNumber,
																					  'N/A',
																					  'N/A',
																					  $null,
																					  $Enclosure.name,
																					  $Enclosure.uri,
																					  $Enclosure.ApplianceConnection)

					[void]$_EnclosureReport.Add($_EnclosureDeviceReport)

				}

				# Locate drive enclosure relative to the frame
				Try
				{

					$uri = "{0}?filter=enclosureUri EQ '{1}'" -f $DriveEnclosureUri, $Enclosure.uri
					$_driveEnclosures = Send-HPOVRequest -Uri $uri -Hostname $Enclosure.ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				ForEach ($_driveEnclosure in $_driveEnclosures.members)
				{

					# Report drive enclosure IO Adapter(s)
					ForEach ($_IOAdatper in $_driveEnclosure.ioAdapters)
					{

						$_EnclosureDeviceReport = New-Object HPOneView.Servers.Enclosure+Firmware(("{0} {1}{2}" -f $_IOAdatper.Model, $_IOAdatper.ioAdapterLocation.locationEntries.type, $_IOAdatper.ioAdapterLocation.locationEntries.value),
																					  'DriveEnclosureIOAdapter',
																					  'Firmware',
																					  $_IOAdatper.firmwareVersion,
																					  $_IOAdatper.serialNumber,
																					  $_IOAdatper.partNumber,
																					  'N/A',
																					  'N/A',
																					  $null,
																					  $_driveEnclosure.name,
																					  $_driveEnclosure.uri,
																					  $Enclosure.ApplianceConnection)

						[void]$_EnclosureReport.Add($_EnclosureDeviceReport)
						
					}

					# Report drive device
					ForEach ($_driveBay in $_driveEnclosure.driveBays)
					{

						$_diskDrive = $_driveBay.drive

						$_EnclosureDeviceReport = New-Object HPOneView.Servers.Enclosure+Firmware(("{0} {1}" -f $_diskDrive.name, $_diskDrive.model),
																					  'DiskDrive',
																					  'Firmware',
																					  $_driveBay.drive.firmwareVersion,
																					  $_diskDrive.serialNumber,
																					  $_diskDrive.model,
																					  'N/A',
																					  'N/A',
																					  $null,
																					  $_driveEnclosure.name,
																					  $_driveEnclosure.uri,
																					  $Enclosure.ApplianceConnection)

						[void]$_EnclosureReport.Add($_EnclosureDeviceReport)

					}

				}

			}

			default
			{

				Throw ("'{0}' Not implemented." -f $Enclosure.enclosureType)

			}

		}

		# Process Interconnects within Enclosure
		"[{0}] Getting Interconnect resources from the enclosure." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		$_Interconnects = New-Object System.Collections.ArrayList

		Try
		{			
			
			ForEach ($_InterconnectBay in ($Enclosure.interconnectBays | Where-Object { $null -ne $_.interconnectUri }))
			{
				
				$_Object = Send-HPOVRequest -Uri $_InterconnectBay.interconnectUri -Hostname $Enclosure.ApplianceConnection

				[void]$_Interconnects.Add($_Object)
			
			}

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}		

		# Process each interconnect
		foreach ($_interconnect in $_Interconnects) 
		{

			$_i++

			$_ProgressParams = @{

				id               = (4 + $ProgressID);
				ParentId         = 1;
				activity         = "Collecting Interconnect Firmware Information";
				CurrentOperation = ("Processing {0}: {1} of {2} Interconnect(s)" -f $_Interconnect.name, $_i, $_Interconnects.Count);
				percentComplete  = (($_i / $_Interconnects.Count) * 100) 

			}

			# Handle the call from -Verbose so Write-Progress does not get borked on display.
			if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
			{
				
				"[{0}] Collecting Interconnect Firmware Information - Skipping Write-Progress display: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ProgressParams | Out-String) | Write-Verbose
			
			}
			 
			else 
			{ 
				
				Write-Progress @_ProgressParams
			
			}

			Try
			{

				$_InterconnectReport = Get-InterconnectFirmware -Interconnect $_interconnect -Baseline $BaseLinePolicy

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			"[{0}] Adding {1} in {2} to Enclosure Firmware collection" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_InterconnectReport.Component, $_InterconnectReport.Name | Write-Verbose

			[void]$_EnclosureReport.Add($_InterconnectReport)

		}

		# Process Server Resource Objects
		"[{0}] Getting Server resources from the enclosure." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Try
		{

			# This is faster to get all associated servers within the enclosure than to loop through deviceBays to make additional API calls
			$Uri = "{0}?filter=locationUri='{1}'" -f $ServerHardwareUri, $Enclosure.uri
			$_Servers = Send-HPOVRequest -Uri $uri -Hostname $Enclosure.ApplianceConnection

		}
		
		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$_s = 0

		foreach ($_server in $_Servers.members) 
		{

			$_s++

			$_ProgressParams = @{

				id               = (3 + $ProgressID);
				ParentId         = 1;
				activity         = "Collecting Server Firmware Information";
				CurrentOperation = ("[{1}/{2}] Processing '{0}' Server" -f $_server.name, $_s, $_Servers.Count);
				percentComplete  = (($_s / $_Servers.members.count) * 100)

			}

			# Handle the call from -Verbose so Write-Progress does not get borked on display.
			if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
			{
				
				"[{0}] Collecting Server Firmware Information - Skipping Write-Progress display: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ProgressParams | Out-String) | Write-Verbose
			
			}
			 
			else 
			{ 
				
				Write-Progress @_ProgressParams
			
			}

			Try
			{

				$_ServerFirmwareReport = Get-ServerFirmware -Server $_server -Baseline $BaseLinePolicy 

				ForEach ($_item in $_ServerFirmwareReport)
				{

					"[{0}] Adding {0} in {1} to Enclosure Firmware collection" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_item.Component, $_item.Name | Write-Verbose

					[void]$_EnclosureReport.Add($_item)

				}

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		# Handle the call from -Verbose so Write-Progress does not get borked on display.
		if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
		{ 
			
			"[{0}] Completed Collecting Enclosure Manager/Server/Interconnect Firmware Information - Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		}
		 
		else 
		{ 
		
			Write-Progress -ParentId 1 -id (2 + $ProgressID) -activity "Collecting Enclosure Manager Firmware Information" -CurrentOperation "Completed" -Completed                    
			Write-Progress -ParentId 1 -id (3 + $ProgressID) -activity "Collecting Server Firmware Information" -CurrentOperation "Completed" -Completed
			Write-Progress -ParentId 1 -id (4 + $ProgressID) -activity "Collecting Interconnect Firmware Information" -CurrentOperation "Completed" -Completed
			Write-Progress -Activity "Create Enclosure Firmware Report" -PercentComplete (100) -Status "Finished." -Completed

		}

	}

	End 
	{

		Return $_EnclosureReport | Sort-Object Name, Component

	}

}
