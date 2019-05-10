function Enclosure-Report 
{

	<#
		.DESCRIPTION
		Internal helper function to display the report of an enclosure

		.Parameter Enclosure
		The enclosure object.
	
		.Parameter file
		File to save the report to.
	
		.INPUTS
		Enclosure object.

		.OUTPUTS
		Enclosure report.

		.LINK
		Get-HPOVEnclosure

		.LINK
		Send-HPOVRequest

		.EXAMPLE
		PS C:\> $enclosures = Get-HPOVEnclosure
		Return all the enclosure hardware  managed by this appliance.

	#>
	
	[CmdletBinding ()]    
	Param 
	(

		[Parameter (Mandatory,ValueFromPipeline)]
		[object]$Enclosure,
	
		[Parameter (Mandatory = $false,ValueFromPipeline = $false)]
		[object]$file,
	
		[Parameter (Mandatory = $false)]
		[switch]$fwreport
	)

	Process 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose
		
		Write-Verbose "ENCLOSURE OBJECT:  $($enclosure)"
		Write-Verbose "ENCLOSURE UUID:  $($Enclosure.uuid)"
	
	# ENCLOSURE REPORT DATA
		$a = @{Expression={$_.name};Label="Enclosure Name";width=15},
			 @{Expression={$_.serialNumber};Label="Serial Number";width=15},
			 @{Expression={$_.enclosureType};Label="Enclosure Model";width=30},
			 @{Expression={$_.rackName};Label="Rack Name";width=12},
			 @{Expression={$_.isFwManaged};Label="FW Managed";width=10},
			 @{Expression={$_.fwBaseLineName};Label="Baseline Name";width=30}

		# Generate Report
		$Enclosure | format-table $a -AutoSize
		
		# License Intent Report
		$a = @{Expression={$_.licensingIntent};Label="Licensing";width=15}

		$Enclosure | format-table $a -AutoSize
		
	# ONBOARD ADMINISTRATOR REPORT DATA
		$a = @{Expression={$_.bayNumber};Label="OA Bay";width=10},
			 @{Expression={$_.role};Label="Role";width=15},
			 @{Expression={$_.ipAddress};Label="IP Address";width=15},
			 @{Expression={($_.fwVersion + " " + $_.fwBuildDate)};Label="Firmware Version";width=20}
		
		$Enclosure.oa | Format-Table $a -AutoSize
		
	# DEVICE BAY REPORT DATA
		# Looking for servers related to the requested enclosure
		$serversCol = New-Object System.Collections.ArrayList
		
		# Loop through populated device bays
		ForEach ($_DeviceBay in ($Enclosure.deviceBays | Where-Object { $_.devicePresence -eq 'Present' -and $_.deviceUri } ))
		{
			
			# Loop through index association results
			Try
			{
				
				$_server = Send-HPOVRequest $_DeviceBay.deviceUri -Hostname $Enclosure.ApplianceConnection.Name

				[void]$serversCol.Add($_server)

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
	
		}
		
		$serversCol | out-string | Write-Verbose
		
		$a = @{Expression={$_.name};Label="Server Name";width=20},
			 @{Expression={$_.serialNumber};Label="Serial Number";width=15},
			 @{Expression={$_.shortModel};Label="Model";width=12},
			 @{Expression={$_.romVersion};Label="System ROM";width=15},
			 @{Expression={($_.mpModel + " " + $_.mpFirmwareVersion)};Label="iLO Firmware Version";width=22},
			 @{Expression={

			 	if (-not($_.serverProfileUri))
				{ 
					
					'No Profile' 
				
				}

			 	else 
				{ 
				 
					Try
					{

						(Send-HPOVRequest $_.serverProfileUri -Hostname $Enclosure.ApplianceConnection.Name).name 

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
				
				}

			 };Label="Server Profile";width=30},
			 @{Expression={$_.licensingIntent};Label="Licensing";width=15}
		
		$serversCol | Sort-Object name | format-table $a -AutoSize
		
	# INTERCONNECT BAY REPORT DATA
		# Loop through interconnect bays
		$interconnectsCol = New-Object System.Collections.ArrayList

		foreach ($interconnect in $enclosure.interconnectBays)
		{

			Write-Verbose "INTERCONNECT:  $($interconnect)"

			if ($interconnect.interconnectUri)
			{

				Try
				{

					# Get the Interconnect object to read properties
					$tempInterconnect = Send-HPOVRequest $interconnect.interconnectUri -Hostname $Enclosure.ApplianceConnection.Name

					# Get Logical Interconnect associated with the Interconnect to report its Name
					$li = Send-HPOVRequest $interconnect.logicalInterconnectUri -Hostname $Enclosure.ApplianceConnection.Name

					$tempInterconnect | Add-Member -type NoteProperty -name liName -value $li.name
					$tempInterconnect | out-string | Write-Verbose
				
					[void]$interconnectsCol.Add($tempInterconnect)

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

		}

		# Display Interconnect information (Name, Model, Serial Number, FW Ver)
		$a = @{Expression={$_.name};Label="Interconnect Name";width=22},
			 @{Expression={$_.model};Label="Module";width=38},
			 @{Expression={$_.serialNumber};Label="Serial Number";width=20},
			 @{Expression={$_.firmwareVersion};Label="Firmware Version";width=20}

		$interconnectsCol | format-Table $a -AutoSize

		# Display Interconnect information (PAD, Name, Logical Interconnect Name, State, Status)
		$b = @{Expression={'     '};Label="     ";width=5},
			 @{Expression={$_.name};Label="Interconnect Name";width=22},
			 @{Expression={$_.liName};Label="Logical Interconnect";width=30},
			 @{Expression={$_.state};Label="State";width=14},
			 @{Expression={$_.status};Label="Status";width=20},
			 @{Expression={ 
				 
				 Try
				 {

					 $tempLI = Send-HPOVRequest $_.logicalInterconnectUri -Hostname $Enclosure.ApplianceConnection.Name

				 }

				 Catch
				 {

					 $PSCmdlet.ThrowTerminatingError($_)

				 }
				 
				 switch ($tempLI.consistencyStatus) 
				 {
 
					'CONSISTENT'     { "Consistent" }
					'NOT_CONSISTENT' { "Inconsistent with group" }
					default          { $tempLI.consistencyStatus }
				 
				 }
			 
			 };Label="Consistency state";width=26}

		$interconnectsCol | format-Table $b -AutoSize

		# Write-Host "=================================================================================================================="

	}

}
