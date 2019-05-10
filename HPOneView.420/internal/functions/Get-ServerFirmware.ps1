function Get-ServerFirmware 
{

	<#
		Internal-only function.
	#>

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(
	
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[Object]$Server, 

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Object]$Baseline,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[int]$ProgressID
		
	)


	Begin 
	{

		$_ServerReport = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ([System.String]::IsNullOrWhiteSpace($Server.serverName))
		{

			$_servername = $Server.name
			
		}

		else
		{

			$_servername = $Server.serverName			

		}

		"[{0}] Processing Server firmware report for: '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_servername | Write-Verbose

		if ('Unknown', 'Adding', 'Monitored', 'Unmanaged', 'Removed', 'Unsupported' -notcontains $Server.state)
		{

			"[{0}] Getting Server Hardware Type" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose		

			# Check if the server hardware type allows firmware management
			Try
			{

				$_sht = Send-HPOVRequest -Uri $Server.serverHardwareTypeUri -Hostname $Server.ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
			if ($_sht.capabilities -match "FirmwareUpdate") 
			{

				"[{0}] Server Hardware Type supports firmware management." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Baseline value provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($Baseline | Out-String) | Write-Verbose

				# If a bladeserver and that the caller hasn't specified a Baseline, Use the Enclosure FwBaseline if it is set
				if (-not($Baseline))
				{ 

					# Check to see if there is a profile
					if ($Server.serverProfileUri) 
					{

						"[{0}] No Baseline provided.  Checking Server Profile." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Try
						{

							$_ServerProfile = Send-HPOVRequest -Uri $Server.serverProfileUri -Hostname $Server.ApplianceConnection.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						# Then check if a Baseline is attached there
						if ($_ServerProfile.firmware.manageFirmware) 
						{ 
						
							"[{0}] Server Profile has baseline attached. Getting baseline details." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							Try
							{

								$_BaselinePolicy = Send-HPOVRequest -Uri $_ServerProfile.firmware.firmwareBaselineUri -Hostname $Server.ApplianceConnection.Name

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

							"[{0}] Server Profile Baseline name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_BaselinePolicy.name | Write-Verbose

							"[{0}] Server Profile Baseline name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_BaselinePolicy.uri | Write-Verbose

						}
						
						# If not, set $BaselinePolicy to NoPolicySet
						else 
						{
							
							"[{0}] Server Profile does not have a baseline attached." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_BaselinePolicy.uri | Write-Verbose

							$_BaselinePolicy = [PsCustomObject]@{ 
								
								name              = "NoPolicySet"; 
								baselineShortName = "NoPolicySet" 
							
							} 

						}

					}

					else 
					{

						"[{0}] No Server Profile assigned, which does not have a baseline policy set." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_BaselinePolicy = [PsCustomObject]@{ 
								
							name              = "NoPolicySet"; 
							baselineShortName = "NoPolicySet" 
							
						} 

					}
					
				}

				elseif ($Baseline -is [PSCustomObject])
				{

					if ($Baseline.baselineShortName -eq 'NoPolicySet')
					{

						"[{0}] No Baseline provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_BaselinePolicy = [PsCustomObject]@{ 
								
							name              = "NoPolicySet"; 
							baselineShortName = "NoPolicySet" 
							
						} 

					}

					elseif (($Baseline) -and ($Baseline.category -eq $ResourceCategoryEnum['Baseline'])) 
					{ 
				
						"[{0}] Baseline resource passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						"[{0}] Baseline resource name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline.baselineShortName | Write-Verbose
						"[{0}] Baseline resource uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline.uri | Write-Verbose

						$_BaselinePolicy = $Baseline.PSObject.Copy()
					
					}

					# Check to see if the wrong Object has been passed
					elseif (($Baseline) -and ($Baseline.category -ne "firmware-drivers")) 
					{ 
				
						"[{0}] Invalid Baseline resource passed. Generating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$ExceptionMessage = "The wrong Baseline Object was passed.  Expected Category type 'firmware-drivers', received '{0}' (Object Name: {1}" -f $Baseline.category, $Baseline.name
						$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentType InvalidArgument 'getserverfirmware' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
					}

				}            

				elseif (($Baseline) -and ($Baseline -is [string]) -and ($Baseline.StartsWith(($ApplianceFwDriversUri)))) 
				{ 
					
					"[{0}] Baseline URI passed: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline | Write-Verbose

					Try
					{

						$_BaseLinePolicy = Send-HPOVRequest -Uri $Baseline -Hostname $Server.ApplianceConnection.Name

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
				
				}

				# Check to see if the wrong URI has been passed
				elseif (($Baseline) -and ($Baseline -is [string]) -and $Baseline.StartsWith("/rest/") -and (-not($Baseline.StartsWith(($ApplianceBaselineRepoUri))))) 
				{ 

					"[{0}] Invalid Baseline URI passed. Generating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					$ExceptionMessage = "The wrong Baseline URI was passed.  URI must start with '/rest/firmware-drivers/', received '{0}'" -f $Baseline
					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentType InvalidArgument 'getserverfirmware' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)        
					
				}

				# Baseline must be a Name
				else
				{ 
				
					"[{0}] Baseline Name passed: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline | Write-Verbose

					Try
					{

						$FirmwareBaslineName = $Baseline.Clone()

						$_BaseLinePolicy = Get-HPOVBaseline -name $Baseline -ApplianceConnection $Server.ApplianceConnection.Name -ErrorAction Stop

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)
					
					}
					
				}

				# Check Baseline Policy and set Compliance statement
				if ($_BaseLinePolicy.baselineShortName -eq "NoPolicySet") 
				{ 
								
					# Get firmware report from server resource since no baseline is associated
					$_Uri = '{0}/firmware' -f $Server.uri

					Try
					{

						$_ServerHardwareFirmwareCompliance = Send-HPOVRequest -Uri $_Uri -Hostname $Server.ApplianceConnection.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}				
										
				}

				else
				{

					# This is where we generate compliance report of server hardware with baseline
					Try
					{

						$_FirmwareComplianceReportRequest = @{
							serverUUID         = $Server.uuid;
							firmwareBaselineId = $_BaseLinePolicy.resourceId
						}

						$_ServerHardwareFirmwareCompliance = Send-HPOVRequest -Uri $ServerHardwareFirmwareComplianceUri -Method POST -Body $_FirmwareComplianceReportRequest -Hostname $Server.ApplianceConnection.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				Switch ($_ServerHardwareFirmwareCompliance.type)
				{

					'server-hardware-firmware-1'
					{

						ForEach ($_Component in $_ServerHardwareFirmwareCompliance.components)
						{

							$_ComponentName = $_Component.componentName

							if ($_Component.componentName.Contains('.sys') -or $_Component.componentName.Contains('.ko') -or $_Component.componentName.Contains('driver') -or $_Component.componentName.Contains('null'))
							{

								$_ComponentType = 'Software'

								if ($_ComponentName -eq 'null')
								{

									$_ComponentName = $_Component.componentLocation

								}

							}

							else
							{

								$_ComponentType = "Firmware"

							}

							if (($_ComponentName.Contains('System ROM') -or $_ComponentName.Contains('System BIOS')) -and -not $_ComponentName.Contains('Backup')-and -not $_ComponentName.Contains('Redundant'))
							{

								$_SerialNumber = $Server.serialNumber
								$_PartNumber   = $Server.partNumber

							}

							else
							{

								$_SerialNumber = 'N/A'
								$_PartNumber = 'N/A'

							}

							$_ComponentVersion = New-Object HPOneView.Servers.ServerHardware+Firmware ($_ComponentName,
																							$_ComponentType,
																							$_Component.componentVersion,
																							$_SerialNumber,
																							$_PartNumber,
																							$_Component.baselineVersion,
																							$_BaseLinePolicy.name,
																							$_BaseLinePolicy.uri,
																							$_servername,
																							$Server.shortModel,
																							$Server.uri,
																							$Server.ApplianceConnection)

							[void]$_ServerReport.Add($_ComponentVersion)

						}			

					}

					default
					{

						if ($_ServerHardwareFirmwareCompliance.componentMappingList.Count -eq 0 -and $Baseline -ne "NoPolicySet")
						{

							Try
							{

								$_ServerFirmwareComponents = Send-HPOVRequest -Uri ($Server.uri + "/firmware") -Hostname $Server.ApplianceConnection

							}
							
							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

							ForEach ($_Component in $_ServerFirmwareComponents.components)
							{

								$_componentName = $_Component.componentName
								$_componentType = 'Firmware'

								Switch ($_componentName)
								{

									{'System ROM', 'System BIOS' -match $_}
									{

										$_swKeyNameListName = $Server.romVersion.SubString(0,3)
										$_BaselineVersion = GetNewestVersion -Collection ($Baseline.fwComponents | Where-Object KeyNameList -contains $_swKeyNameListName)

										if ($_Component.componentName.Contains('System ROM') -or $_Component.componentName.Contains('System BIOS') -and -not $_Component.componentName.Contains('Backup')-and -not $_Component.componentName.Contains('Redundant'))
										{

											$_SerialNumber = $Server.serialNumber
											$_PartNumber   = $Server.partNumber

										}

										else
										{

											$_SerialNumber = 'N/A'
											$_PartNumber = 'N/A'

										}

									}

									'iLO'
									{

										$_swKeyNameListName = $MpModelTable.($Server.mpModel)
										$_BaselineVersion = GetNewestVersion -Collection ($Baseline.fwComponents | Where-Object KeyNameList -contains $_swKeyNameListName)

									}

									'Intelligent Provisioning'
									{

										$_BaselineVersion = 'N/A'

									}

									'Power Management Controller Firmware'
									{

										switch ($Server.model)
										{

											{'Gen9' -match $_}
											{

												$_swKeyNameListName = 'PowerPIC-Gen9'

											}

											{'Gen8' -match $_}
											{

												$_swKeyNameListName = 'PowerPIC-Gen8'

											}

										}

										$_BaselineVersion = GetNewestVersion -Collection ($Baseline.fwComponents | Where-Object KeyNameList -contains $_swKeyNameListName)

									}

									'null'
									{

										$_componentName = $_Component.componentLocation
										$_componentType = 'Driver'

									}

								}

								$_ComponentVersion = New-Object HPOneView.Servers.ServerHardware+Firmware ($_componentName,
																											$_componentType,
																											$_Component.componentVersion,
																											$_SerialNumber,
																											$_PartNumber,
																											$_BaselineVersion,
																											$_BaseLinePolicy.name,
																											$_BaseLinePolicy.uri,
																											$_servername,
																											$Server.shortModel,
																											$Server.uri,
																											$Server.ApplianceConnection)

								[void]$_ServerReport.Add($_ComponentVersion)

							}

						}

						else
						{

							ForEach ($_Component in $_ServerHardwareFirmwareCompliance.componentMappingList)
							{

								$_componentName = $_Component.componentName
								$_componentType = 'Firmware'

								Switch ($_componentName)
								{

									{'System ROM', 'System BIOS' -match $_}
									{

										if ($_Component.componentName.Contains('System ROM') -or $_Component.componentName.Contains('System BIOS') -and -not $_Component.componentName.Contains('Backup')-and -not $_Component.componentName.Contains('Redundant'))
										{

											$_SerialNumber = $Server.serialNumber
											$_PartNumber   = $Server.partNumber

										}

										else
										{

											$_SerialNumber = 'N/A'
											$_PartNumber = 'N/A'

										}

									}

									'Intelligent Provisioning'
									{

										$_BaselineVersion = 'N/A'

									}

									'null'
									{

										$_componentName = $_Component.componentLocation
										$_componentType = 'Driver'

									}

								}
	
								$_ComponentVersion = New-Object HPOneView.Servers.ServerHardware+Firmware ($_componentName,
																											$_componentType,
																											$_Component.installedVersion,
																											$_SerialNumber,
																											$_PartNumber,
																											$_Component.baselineVersion,
																											$_BaseLinePolicy.name,
																											$_BaseLinePolicy.uri,
																											$_servername,
																											$Server.shortModel,
																											$Server.uri,
																											$Server.ApplianceConnection)
	
								[void]$_ServerReport.Add($_ComponentVersion)
	
							}	
							
						}					

					}

				}

			}

			# Server firmware is unmanageable based on its Server Hardware Type
			else 
			{ 

				$_SerialNumber = $Server.serialNumber
				$_PartNumber   = $Server.partNumber
				
				"[{0}] Server Hardware Type does not support firmware management." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_UnmanageableServer = New-Object HPOneView.Servers.ServerHardware+Firmware ("N/A",
																							"N/A",
																							"N/A",
																							$_SerialNumber,
																							$_PartNumber,
																							"N/A",
																							"Unmanaged",
																							$null,
																							$_servername,
																							$Server.shortModel,
																							$Server.uri,
																							$Server.ApplianceConnection)
				[void]$_ServerReport.Add($_UnmanageableServer)
				
			}

		}

		else
		{

			"[{0}] Server Hardware is not in a Managed state." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_SerialNumber = $Server.serialNumber
			$_PartNumber   = $Server.partNumber

			$_UnmanageableServer = New-Object HPOneView.Servers.ServerHardware+Firmware ("N/A",
																						"N/A",
																						"N/A",
																						$_SerialNumber,
																						$_PartNumber,
																						"N/A",
																						"Unmanaged",
																						$null,
																						$_servername,
																						$Server.shortModel,
																						$Server.uri,
																						$Server.ApplianceConnection)
			[void]$_ServerReport.Add($_UnmanageableServer)

		}		

	}

	End 
	{

		Return $_ServerReport | Sort-Object Name, Component

	}

}
