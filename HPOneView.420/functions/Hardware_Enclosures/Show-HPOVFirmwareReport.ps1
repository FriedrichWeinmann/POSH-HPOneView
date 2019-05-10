function Show-HPOVFirmwareReport 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[Alias('Resource')]
		[validateNotNullorEmpty()]
		[Object]$InputObject,
	
		[Parameter (Mandatory = $false)]
		[validateNotNullorEmpty()]
		[Object]$Baseline,
			
		[Parameter (Mandatory = $false)]
		[Switch]$Export,
			
		[Parameter (Mandatory = $false)]
		[validateNotNullorEmpty()]
		[String]$Location = (get-location).Path,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false)]
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

		# Support ApplianceConnection property value via pipeline from Enclosure Object
		if(-not($PSboundParameters['InputObject']))
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

		$_ResourceCollection       = New-Object System.Collections.ArrayList
		$_FirmwareReportCollection = New-Object System.Collections.ArrayList

		# Test for location
		if ($Export) 
		{
		
			if ( -not (Test-Path $Location)) 
			{  

				$ErrorRecord = New-ErrorRecord InvalidOperationException LocationPathNotFound ObjectNotFound 'Location' -Message "The specified path $Location does not exist. Please verify it and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

		}
	
	}

	Process 
	{	

		$_r = 1

		# Add Resource to Collection, which can be accepted via the pipeline
		ForEach ($_resource in $InputObject)
		{

			if ($_resource -is [String])
			{

				# Error that the Resource isn't an object
				$ExceptionMessage = 'The Inputobject {0} is not a supported resource type, PSObject.' -f $_resource
				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidBaselineResouce InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			"[{0}] Adding '{1}' object to collection ({2}/{3})." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_resource.name, $_r, ($InputObject | Measure-Object).Count | Write-Verbose 

			[void]$_ResourceCollection.Add($_resource)

			$_r++

		}

	}

	End 
	{

		$_P = 0

		# Process the report generation here
		ForEach ($_resource in $_ResourceCollection)
		{

			if (-not($PSBoundParameters['Verbose']) -or -not($VerbosePreference -eq 'Continue'))
			{
				
				Write-Progress -id 1 -activity "Generate Firmware Report" -percentComplete (($_P / $_ResourceCollection.count) * 100)

			}

			switch ($_resource.category) 
			{

				$ResourceCategoryEnum.EnclosureGroup
				{

					$_P++

					$_ProgressParams = @{

						ID = 1;
						Activity = "Generate Firmware Report";
						CurrentOperation = ("Processing '{0}' Enclosure Group" -f $_resource.name);
						PercentComplete = (($_P / $_ResourceCollection.count) * 100)

					}

					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{
						
						"[{0}] Collecting Enclosure Firmware Information - {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ProgressParams | Out-String) | Write-Verbose

					}
					
					else 
					{ 

						Write-Progress @_ProgressParams
					
					}

					"[{0}] Getting Enclosure Group to Enclosure associations, then getting found Enclosure Resources." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						# Get associated Logical Enclosures with Enclosure Group
						$_uri = '{0}?parentUri={1}&name=ENCLOSURE_GROUP_TO_LOGICAL_ENCLOSURE' -f $AssociationsUri, $_resource.uri
						[Array]$_ResourcesFromIndexCol = Get-AllIndexResources -Uri $_uri -ApplianceConnection $_resource.ApplianceConnection.Name

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
						
					# Make sure the EG has associated Enclosures/LogicalEnclosures.
					if ($_ResourcesFromIndexCol) 
					{

						$_e = 0

						"[{0}] Total number of Logical Enclosures to Process: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ResourcesFromIndexCol.Count | Write-Verbose 

						foreach ($_le in $_ResourcesFromIndexCol) 
						{ 

							# Loop through LE EnclosureUris
							foreach ($_enclosureUri in $_le.enclosureUris)
							{

								# Get Enclosure Resource Object
								Try
								{

									$_enclosure = Send-HPOVRequest -uri $_enclosureUri -Hostname $_resource.ApplianceConnection.Name

								}
							
								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}

								$_e++

								$_EnclParams = @{

									ID               = 10;
									ParentID         = 1;
									Activity         = "Create Enclosure Firmware Report";
									CurrentOperation = ("[{0}\{1}] Processing '{2}' Enclosure" -f $_e, $_ResourcesFromIndexCol.Count, $_enclosure.name);
									PercentComplete  = (($_e / $_ResourcesFromIndexCol.Count) * 100)

								}

								# Handle the call from -Verbose so Write-Progress does not get borked on display.
								if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
								{ 

									"[{0}] Collecting Enclosure Firmware Information: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_EnclParams | Out-String) | Write-Verbose
							
								}
					
								else 
								{ 
								
									Write-Progress @_EnclParams
							
								}

								Try
								{

									$_EnclosureReportCol = Get-EnclosureFirmware -Enclosure $_enclosure -Baseline $Baseline -ProgressID 1

									"[{0}] Enclosure Firmware Report return: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_EnclosureReportCol | Out-String) | Write-Verbose

									ForEach ($_item in $_EnclosureReportCol)
									{

										"[{0}] Adding {1} in {2} to Enclosure Firmware collection" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_item.Component, $_item.Name | Write-Verbose
										
										# $_item | add-member -Type NoteProperty -Name eg -value $_resource.name

										[void]$_FirmwareReportCollection.Add($_item)

									}

								}
							
								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}

							}						

						}

					}
						
					# Clear Child Write-Progress progress bars
					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{ 
						
						"[{0}] Completed Collecting Enclosure Firmware Information - Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					}
			 
					else 
					{ 
						
						Write-Progress -ParentId 1 -id 2 -activity "Collecting Enclosure Firmware Information" -CurrentOperation "Completed" -Completed 
					
					}

					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{ 
						
						"[{0}] Completed Collecting Enclosure Group Firmware Information Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					}
			 
					else 
					{ 
						
						Write-Progress -Id 1 -activity "Collecting Enclosure Group Firmware Information" -CurrentOperation "Completed" -Completed 
					
					}

				}

				$ResourceCategoryEnum.LogicalEnclosure
				{

					$_P++

					$_ProgressParams = @{

						ID = 1;
						Activity = "Generate Firmware Report";
						CurrentOperation = ("Processing '{0}' Logical Enclosure" -f $_resource.name);
						PercentComplete = (($_P / $_ResourceCollection.count) * 100)

					}

					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{
						
						  "[{0}] Collecting Logical Enclosure Firmware Information - {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ProgressParams | Out-String) | Write-Verbose

					}
					
					else 
					{ 

						Write-Progress @_ProgressParams
					
					}

					"[{0}] Getting Enclosure resources from Logical Enclosure." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_e = 0

					# Loop through LE EnclosureUris
					foreach ($_enclosureUri in $_resource.enclosureUris)
					{

						# Get Enclosure Resource Object
						Try
						{

							$_enclosure = Send-HPOVRequest -uri $_enclosureUri -Hostname $_resource.ApplianceConnection.Name

						}
					
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						$_e++

						$_EnclParams = @{

							ID               = 10;
							ParentID         = 1;
							Activity         = "Create Enclosure Firmware Report";
							CurrentOperation = ("[{0}\{1}] Processing '{2}' Enclosure" -f $_e, $_resource.enclosureUris.Count, $_enclosure.name);
							PercentComplete  = (($_e / $_resource.enclosureUris.Count) * 100)

						}

						# Handle the call from -Verbose so Write-Progress does not get borked on display.
						if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
						{ 

							"[{0}] Collecting Enclosure Firmware Information: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_EnclParams | Out-String) | Write-Verbose
					
						}
			
						else 
						{ 
						
							Write-Progress @_EnclParams
					
						}

						Try
						{

							$_EnclosureReportCol = Get-EnclosureFirmware -Enclosure $_enclosure -Baseline $Baseline -ProgressID 1

							"[{0}] Enclosure Firmware Report return: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_EnclosureReportCol | Out-String) | Write-Verbose

							ForEach ($_item in $_EnclosureReportCol)
							{

								"[{0}] Adding {1} in {2} to Enclosure Firmware collection" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_item.Component, $_item.Name | Write-Verbose

								[void]$_FirmwareReportCollection.Add($_item)

							}

						}
					
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}						
						
					# Clear Child Write-Progress progress bars
					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{ 
						
						"[{0}] Completed Collecting Enclosure Firmware Information - Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					}
			 
					else 
					{ 
						
						Write-Progress -ParentId 1 -id 2 -activity "Collecting Enclosure Firmware Information" -CurrentOperation "Completed" -Completed 
					
					}

					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{ 
						
						"[{0}] Completed Collecting Enclosure Group Firmware Information Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					}
			 
					else 
					{ 
						
						Write-Progress -Id 1 -activity "Collecting Enclosure Group Firmware Information" -CurrentOperation "Completed" -Completed 
					
					}

				}

				# "enclosures" 
				$ResourceCategoryEnum.Enclosure
				{

					# Keep track of the number of resources
					$_P++

					$_ProgressParams = @{

						ID = 1;
						Activity = "Generate Firmware Report";
						CurrentOperation = ("Processing '{0}' Enclosure" -f $_resource.name);
						PercentComplete = (($_P / $_ResourceCollection.count) * 100)

					}

					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{
						
						  "[{0}] Collecting Enclosure Firmware Information - {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ProgressParams | Out-String) | Write-Verbose
					}
					
					else 
					{ 

						Write-Progress @_ProgressParams
					
					}

					Try
					{

						$_EnclosureReport = Get-EnclosureFirmware -Enclosure $_resource -Baseline $Baseline -ProgressID 1

						$_EnclosureReport | ForEach-Object {

							[void]$_FirmwareReportCollection.Add($_)

						}

					}

					Catch
					{

						Write-Progress -id 1 -activity "Collecting Enclosure Firmware Information" -CurrentOperation "Completed" -Completed 

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{ 
						
						"[{0}] Completed Collecting Enclosure Firmware Information - Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					}
				
					else 
					{ 
						
						Write-Progress -id 1 -activity "Collecting Enclosure Firmware Information" -CurrentOperation "Completed" -Completed 
					
					}

				}

				$ResourceCategoryEnum.ServerHardware
				{ 

					# Keep track of the number of resources
					$_P++

					$_ProgressParams = @{

						ID = 1;
						Activity = "Generate Firmware Report";
						CurrentOperation = ("Processing '{0}' Server(s)" -f $_resource.name);
						PercentComplete = (($_P / $_ResourceCollection.count) * 100)

					}

					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{
						
						  "[{0}] Collecting Server Firmware Information - {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ProgressParams | Out-String) | Write-Verbose
					}
					
					else 
					{ 

						Write-Progress @_ProgressParams
					
					}

					Try
					{

						$_ServerReport = Get-ServerFirmware -Server $_resource -Baseline $Baseline -ProgressID 1

						$_ServerReport | ForEach-Object {

							[void]$_FirmwareReportCollection.Add($_)

						}

					}

					Catch
					{

						Write-Progress -id 1 -activity "Collecting Server Firmware Information" -CurrentOperation "Completed" -Completed 

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{ 
						
						"[{0}] Completed Collecting Server Firmware Information - Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					}
				
					else 
					{ 
						
						Write-Progress -id 1 -activity "Collecting Server Firmware Information" -CurrentOperation "Completed" -Completed 
					
					}
			
				}

				{$ResourceCategoryEnum.Interconnect, $ResourceCategoryEnum.SasInterconnect -Contains $_}
				{ 

					# Keep track of the number of resources
					$_P++

					$_ProgressParams = @{

						ID = 1;
						Activity = "Generate Firmware Report";
						CurrentOperation = ("Processing '{0}' Interconnects(s)" -f $_resource.name);
						PercentComplete = (($_P / $_ResourceCollection.count) * 100)

					}

					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{

						"[{0}] Completed Collecting Server Firmware Information - {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ProgressParams | Out-String) | Write-Verbose
						
					}
					
					else 
					{ 

						Write-Progress @_ProgressParams
					
					}

					Try
					{

						$_InterconnectFirmwareReport = Get-InterconnectFirmware -Interconnect $_resource -Baseline $Baseline -ProgressID 1

						$_InterconnectFirmwareReport | ForEach-Object {

							[void]$_FirmwareReportCollection.Add($_)

						}

					}

					Catch
					{

						Write-Progress -id 1 -activity "Collecting Interconnect Firmware Information" -CurrentOperation "Completed" -Completed 

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{ 
						
						"[{0}] Completed Collecting Interconnect Firmware Information - Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					}
				
					else 
					{ 
						
						Write-Progress -id 1 -activity "Collecting Server Firmware Information" -CurrentOperation "Completed" -Completed 
					
					}
		   
				}

			}

		}

		Write-Progress -ID 10 -ParentID 1 -Activity "Create Enclosure Firmware Report" -Status "Finished." -Completed

		Write-Progress -Activity "Firmware collection report complete." -Status "Finished." -Completed

		if ($Export) 
		{ 

			$_Location = '{0}\FirmwareReport_{1}.csv' -f $Location,[DateTime]::Now.ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ss.ff.fffZzzz').Replace(':','')

			$_FirmwareReportCollection | ForEach-Object { Export-Csv -InputObject $_ -Path $_Location -AppEnd -NoTypeInformation -Encoding UTF8 }
				
		}

		# Display Report
		else 
		{

			Return $_FirmwareReportCollection

		}

	}

}
