function Get-InterconnectFirmware 
{

	<#
		Internal-only function.
	#>

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(
	
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[PsCustomObject]$Interconnect, 

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[object]$Baseline = $Null,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[int]$ProgressID
		
	)


	Begin 
	{

		$_InterconnectReport = New-Object System.Collections.ArrayList

	}

	Process 
	{
		
		"[{0}] Processing Interconnect firmware report for: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Interconnect.name | Write-Verbose

		$_InterconnectFirmwareVersion = $Interconnect.firmwareVersion
		
		if (-not $Baseline)
		{

			"[{0}] Baseline was not provided, checking Logical Interconnect Firmware Baseline set." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				switch ($Interconnect.category)
				{

					'sas-interconnects'
					{

						$_baseUri = $Interconnect.sasLogicalInterconnectUri

					}

					'interconnects'
					{

						$_baseUri = $Interconnect.logicalInterconnectUri

					}

				}

				$_Uri = '{0}/firmware' -f $_baseUri

				$_LogicalInterconnectFirmware = Send-HPOVRequest -Uri $_Uri -Hostname $Interconnect.ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($_LogicalInterconnectFirmware.sppUri.ToLower() -ne 'unknown' -and -not [System.String]::IsNullOrWhiteSpace($_LogicalInterconnectFirmware.sppUri))
			{
				
				Try
				{

					$_BaseLinePolicy = Send-HPOVRequest -Uri $_LogicalInterconnectFirmware.sppUri -Hostname $Interconnect.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				"[{0}] Logical Interconenct Firmware Baseline name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_BaseLinePolicy.name | Write-Verbose

			}

			Elseif (-not [System.String]::IsNullOrWhiteSpace($Interconnect.enclosureUri))
			{

				"[{0}] Baseline was not provided, checking Enclosure Firmware Baseline set." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_Enclosure = Send-HPOVRequest -Uri $Interconnect.enclosureUri -Hostname $Interconnect.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
			
				"[{0}] Enclosure Firmware Baseline set: {0}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Enclosure.isFwManaged | Write-Verbose 

				# Check if the Enclosure has a Firmware Baseline attached
				if ($_Enclosure.isFwManaged -and $_Enclosure.fwBaselineUri)
				{ 

					Try
					{

						$_BaseLinePolicy = Send-HPOVRequest -Uri $_Enclosure.fwBaselineUri -Hostname $Interconnect.ApplianceConnection.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					"[{0}] Enclosure Firmware Baseline name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_BaseLinePolicy.name | Write-Verbose

				}

				else 
				{ 
			
					"[{0}] No Baseline provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_BaselinePolicy = [PsCustomObject]@{ 
								
						name              = "NoPolicySet"; 
						baselineShortName = "NoPolicySet" 
						
					} 
			
				}

			}

			else 
			{ 
		
				"[{0}] No Baseline provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

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
			elseif ($null -ne $Baseline -and $Baseline.category -ne "firmware-drivers")
			{ 
			
				"[{0}] Invalid Baseline resource passed. Generating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				$ExceptionMessage = "An invalid Baseline Object was passed.  Expected Category type 'firmware-drivers', received '{0}' (Object Name: {1})" -f $Baseline.category, $Baseline.name
				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentType InvalidArgument 'Baseline' -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
			}

		}            

		elseif ($null -ne $Baseline -and $Baseline -is [string] -and $Baseline.StartsWith($ApplianceFwDriversUri))
		{ 
				
			"[{0}] Baseline URI passed: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline | Write-Verbose 

			Try
			{

				$_BaseLinePolicy = Send-HPOVRequest -Uri $Baseline -Hostname $Server.ApplianceConnection

			}
				
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
		}

		# Check to see if the wrong URI has been passed
		elseif ($null -ne $Baseline -and $Baseline -is [string] -and -not $Baseline.StartsWith($ApplianceBaselineRepoUri))
		{ 

			"[{0}] Invalid Baseline URI passed. Generating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			$ExceptionMessage = "An invalid Baseline URI was passed.  URI must start with '/rest/firmware-drivers/', received '{0}'" -f $Baseline
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentType InvalidArgument 'Baseline' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)        
				
		}

		else 
		{ 
				
			"[{0}] Unknown baseline." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline | Write-Verbose 
			
		}

		if ($_BaseLinePolicy.baselineShortName -eq "NoPolicySet") 
		{ 
		
			$_BaselineVer = "N/A"
			$_Compliance = "N/A"

		}

		else 
		{ 

			switch ($Interconnect.enclosureType)
			{

				'C7000'
				{

					# C-CLASS
					# {vceth, vc8gb}                              HPE BladeSystem c-Class Virtual Connect Firmware, Ethernet plus 8Gb 20-port and 8/16Gb 24-port FC Edition Component for Linux
					$_ComponentType = 'vceth'					

				}

				default
				{

					switch ($Interconnect.model)
					{

						'Virtual Connect SE 40Gb F8 Module for Synergy'
						{

							# {icmvc40gbf8}                               HPE Virtual Connect SE 40Gb F8 Module for Synergy Firmware install package
							$_ComponentType = 'icmvc40gbf8'

						}


						'Virtual Connect SE 16Gb FC Module for Synergy'
						{

							# {icmvc16gbfc}                               Virtual Connect SE 16Gb FC Module for Synergy
							$_ComponentType = 'icmvc16gbfc'

						}

						{'Synergy 10Gb Interconnect Link Module', 'Synergy 20Gb Interconnect Link Module' -contains $_}
						{
							
							# {icmlm}                                     Synergy 10/20 Gb Interconnect Link Module
							$_ComponentType = 'icmlm'
							
						}

						'Synergy 10Gb Pass-Thru Module'
						{

							# {icmpt}                                     Synergy 10Gb Pass-Thru Module
							$_ComponentType = 'icmpt'

						}

						'Synergy 12Gb SAS Connection Module'
						{

							# {12G SAS Conn Mod}                          Smart Component for HPE Synergy 12Gb SAS Connection Module Firmware
							$_ComponentType = '12G SAS Conn Mod'

						}

						default
						{

							Throw ("{0} module not implemented." -f $Interconnect.model)

						}

					}

				}

			}

			$_BaselineVersions = $_BaseLinePolicy.fwComponents | Where-Object KeyNameList -contains $_ComponentType

			$_BaselineVer = GetNewestVersion -Collection $_BaselineVersions
								
		}

		$_EnclosureDeviceReport = New-Object HPOneView.Servers.Enclosure+Firmware($Interconnect.name,
																		  $Interconnect.model,
																		  'Firmware',
																		  $_InterconnectFirmwareVersion,
																		  $Interconnect.serialNumber,
																		  $Interconnect.partNumber,
																		  $_BaselineVer,
																		  $_BaselinePolicy.name,
																		  $_BaselinePolicy.uri,
																		  $Interconnect.enclosureName,
																		  $Interconnect.enclosureUri,
																		  $Interconnect.ApplianceConnection)

		[void]$_InterconnectReport.Add($_EnclosureDeviceReport)

	}

	End 
	{

		Return $_InterconnectReport

	}

}
