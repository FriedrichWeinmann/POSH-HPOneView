function Get-HPOVPowerDevice 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false)]
		[ValidateSet ('HPIpduCore', 'HPIpduAcModule', 'LoadSegment', 'HPIpduOutletBar', 'HPIpduOutlet')]
		[Array]$Type,
		
		[Parameter (Mandatory = $false)]
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

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			$_Query = New-Object System.Collections.ArrayList

			# Commented out until corect Index API call can be found
			# if ($Type)
			# {

			# 	ForEach ($_type in $Type)
			# 	{

			# 		$_queryvalue = "pdd_type:'{0}'" -f $_type
			# 		# $_queryvalue = "deviceType:'{0}'" -f $_type
			# 		[void]$_Query.Add($_queryvalue)

			# 	}

			# }

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

			$_Category = 'category=power-devices'

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

			if ($_ResourcesFromIndexCol.Count -eq 0)
			{
				
				if ($Name) 
				{ 
					
					"[{0}] '{1}' Power Device not found." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

					$ExceptionMessage = "No power device with '{0}' name found on '{1}' appliance connection.  Please check the name or use New-HPOVStorageVolume to create the volume." -f $Name, $_appliance.Name
					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException StorageVolumeResourceNotFound ObjectNotFound 'Name' -Message $ExceptionMessage 
					$PSCmdlet.WriteError($ErrorRecord)

				}

				else 
				{

					"[{0}] No Power Device found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}
						
			}
				
			else 
			{

				if ($Type)
				{

					"[{0}] Filtering for {1} device type." -f $MyInvocation.InvocationName.ToString().ToUpper(), [String]::Join(', ', $Type) | Write-Verbose

					$_ResourcesFromIndexCol = $_ResourcesFromIndexCol | Where-Object { $Type -contains $_.deviceType }

				}

				ForEach ($_member in ($_ResourcesFromIndexCol | Sort-Object name, deviceType))
				{ 

					switch ($_member.deviceType)
					{
	
						'HPIpduCore'
						{

							$_member.psobject.typenames.Insert(0,"HPOneView.PowerDeliveryDevice")
	
						}

						'HPIpduAcModule'
						{

							$_member.psobject.typenames.Insert(0,"HPOneView.PowerDeliveryDevice.PduAcModule")

						}

						'LoadSegment'
						{

							$_member.psobject.typenames.Insert(0,"HPOneView.PowerDeliveryDevice.LoadSegment")

						}

						'HPIpduOutletBar'
						{

							$_member.psobject.typenames.Insert(0,"HPOneView.PowerDeliveryDevice.OutletBar")

						}
	
						'HPIpduOutlet'
						{

							# Get power state
							Try
							{

								$_PowerState = Send-HPOVRequest -Uri ($_member.uri + '/powerState') -ApplianceConnection $_member.ApplianceConnection

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

							$_member | Add-Member -NotePropertyName power -NotePropertyValue $_PowerState -Force

							$_member.psobject.typenames.Insert(0,"HPOneView.PowerDeliveryDevice.Outlet")

						}
		
					}

					$_member
					
				} 	
				
			}         

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
	}

}
