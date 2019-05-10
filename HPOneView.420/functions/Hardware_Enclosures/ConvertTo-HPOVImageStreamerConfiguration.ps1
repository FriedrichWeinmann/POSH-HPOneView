function ConvertTo-HPOVImageStreamerConfiguration
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('EnclosureGroup','EG')]
		[Object]$InputObject,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[String]$UplinkSetName,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Array]$UplinkPorts = @("Enclosure1:Bay3:Q1.1", "Enclosure1:Bay3:Q2.1", "Enclosure2:Bay6:Q1.1", "Enclosure2:Bay6:Q2.1"),
		
		[Parameter (Mandatory, ParameterSetName = 'default')]
		[ValidateNotNullOrEmpty()]
		[Object]$DeploymentNetwork,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		
		if (-not($PSBoundParameters['InputObject'])) 
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

				For ([int]$c = 0; $c -gt $ApplianceConnection.Count; $c++) 
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

		$_TaskCollection = New-Object System.Collections.ArrayList
		$_Collection     = New-Object System.Collections.ArrayList
		
	}

	Process
	{

		If ($ApplianceConnection.ApplianceType -ne 'Composer')
		{

			$ExceptionMessage = 'The ApplianceConnection {0} ({1}) is not a Synergy Composer.  This Cmdlet only support Synergy Composer management appliances.' -f $ApplianceConnection.Name, $ApplianceConnection.ApplianceType
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		Try
		{

			if (-not(Get-HPOVOSDeploymentServer -ApplianceConnection $ApplianceConnection -ErrorAction SilentlyContinue))
			{

				$ExceptionMessage = 'The appliance {0} does not have a Deployment Server.  One must be created before attempting to set an Enclosure Group and Logical Interconnect Group policy change.' -f $ApplianceConnection.name
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.DeploymentServerResourceException OsDeploymentServerNotFound ObjectNotFound 'ApplianceConnect' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$MultipleAssociatedEGs = $False

		"[{0}] InputObject: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($InputObject | Out-String) | Write-Verbose 

		# Validate InputObject
		if ($InputObject -is [PCustomObject])
		{

			"[{0}] Processing category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.category | Write-Verbose 

			if ($InputObject.category -eq 'logical-enclosure')
			{

				Try
				{

					$InputObject = Send-HPOVRequest -Uri $InputObject.enclosureGroupUri -ApplianceConnection $InputObject.ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
			}

			elseif ($InputObject.category -eq 'logical-interconnect-groups')
			{

				# Check to see if the LIG is a member of other EG's via the Index?
				try
				{

					$IndexResults = Send-HPOVRequest -Uri ('{0}?childUri={1}&name=ENCLOSURE_GROUP_TO_LOGICAL_INTERCONNECT_GROUP' -f $IndexUri, $InputObject.uri)
					
					$MultipleAssociatedEGs = $IndexResults.count -gt 1

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($InputObject.category -ne 'enclosure-groups')
			{

				$ErrorRecord = New-ErrorRecord
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		# Look for name?
		else
		{

			Try
			{

				$InputObject = Get-HPOVEnclosureGroup -Name $InputObject -ErrorAction Stop

			}

			catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		# Process multiple EG's
		if ($MultipleAssociatedEGs)
		{

			$InputObject = New-Object System.Collections.ArrayList

			"[{0}] Processing multiple Enclosure Group associations to Logical Interconnect Group" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

			ForEach ($_Item in $IndexResults)
			{

				Try
				{

					$EnclosureGroup = Send-HPOVRequest -Uri $_Item.parentUri -Hostname $ApplianceConnection

					[void]$InputObject.Add($EnclosureGroup)

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

		}

		# Single EG
		else
		{

			"[{0}] Processing single Enclosure Group associations to Logical Interconnect Group" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
		
		}

		# Process all EG's by removing the LIG association from Bay3 and Bay6 first
		ForEach ($_EnclosureGroup in $InputObject)
		{

			# EG is already configured for Image Streamer, generate error
			if ($_EnclosureGroup.osDeploymentSettings.manageOSDeployment)
			{

				$ExceptionMessage = 'The Enclosure Group {0} is already configured for Image Streamer.' -f $_EnclosureGroup.name
				$ErrorRecord = New-ErrorRecord HPOneView.EnclosureGroupResourceException EnclosureGroupAlreadyConfigured InvalidParameter 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				# Locate LIG  within EG at Frame 1, Bay 3 and Frame 2, Bay 6
				ForEach ($_LIGUri in ($_EnclosureGroup.interconnectBayMappings | Where-Object { 3,6 -contains $_.interconnectBay }))
				{

					Try
					{

						$Bay3LIG = Send-HPOVRequest -Uri ($_LigUri | Where-Object interconnectBay -eq 3).logicalInterconnectGroupUri
						$Bay6LIG = Send-HPOVRequest -Uri ($_LigUri | Where-Object interconnectBay -eq 6).logicalInterconnectGroupUri
						$associatedig = $Bay3Lig.PSObject.Copy()

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				# LIGs do not match, generate terminating error that it is not supported.
				if ($Bay3Lig.uri -ne $Bay6Lig.uri)
				{

					$ExceptionMessage = 'The Logical Interconnect Groups assigned to Bays 3 and 6 are not the same policy (Bay3: {0}; Bay6: {1}).  Image Streamer is only supported with Redundant Interconnect Modules.' -f $Bay3Lig.name,$Bay6Lig.name
					$ErrorRecord = New-ErrorRecord HPOneView.LogicalInterconnectGroupResourceException UnsupportedLigConfiguration InvalidOperation 'InputObject' -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# UPDATE EG
				$ShouldProcessMessage = "Remove Logical Interconnect Group {0} from Enclosure Group on appliance '{1}'" -f $Bay3Lig.name, $InputObject.ApplianceConnection.Name

				if ($PSCmdlet.ShouldProcess($_EnclosureGroup.name, $ShouldProcessMessage)) 
				{

					# Copy object to then update copy, retain original for use later
					$UpdateEg = $_EnclosureGroup.PSObject.Copy()

					# Strip out Bays 3 and 6 from Interconnect Bay Mappings
					$UpdateEg.interconnectBayMappings | Where-Object { 3,6 -notcontains $_.interconnectBay }

					# Update EG object on appliance
					Try
					{

						$Results = Send-HPOVRequest -Uri $UpdateEg.uri -Method PUT -Body $UpdateEg -ApplianceConnection $UpdateEg.ApplianceConnection | Wait-HPOVTaskComplete

						[void]$_Collection.Add($UpdateEg)

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					if ($Results.taskState -ne 'Completed')
					{

						$ExceptionMessage = 'The Logical Interconnect Groups update did not complete successfully: {0}' -f [String]::Join(' ', $Results.taskErrors.message)
						$ErrorRecord = New-ErrorRecord HPOneView.LogicalInterconnectGroupResourceException InvalidUpdateLigResult InvalidResult 'InputObject' -TargetType $_EnclosureGroup.GetType().Name -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				elseif ($PSBoundParameters['WhatIf'])
				{

					"[{0}] User passed -WhatIf parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

			}

			# Update LIG with new Uplink Set
			$ShouldProcessMessage = "Add new Image Streamer Uplink Set {0}" -f $UplinkSetName

			if ($PSCmdlet.ShouldProcess($associatedig.name, $ShouldProcessMessage)) 
			{

				$UplinkSetParams = @{

					Name        = $UplinkSetName;
					Type        = 'ImageStreamer';
					InputObject = $Bay3Lig;
					Networks    = $DeploymentNetwork;
					UplinkPorts = $UplinkPorts

				}

				Try
				{

					$i3SUplinkSetResults = New-HPOVUplinkSet @UplinkSetParams -ApplianceConnection $InputObject.ApplianceConnection | Wait-HPOVTaskComplete

				}

				Catch
				{

					$PSCmdlet.ThrowterminatingError($_)

				}

			}

			elseif ($PSBoundParameters['WhatIf'])
			{

				"[{0}] User passed -WhatIf parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			# Update each EG with Deployment Network settings and Bay3 and Bay6 LIG mapping; 
			ForEach ($_EnclosureGroupToUpdate in $InputObject)
			{

				# Get EG resource to get updated eTag and modifiedDate values
				Try
				{

					$UpdatedEg = Get-HPOVEnclosureGroup -Name $_EnclosureGroupToUpdate.name -ApplianceConnection $_EnclosureGroupToUpdate.ApplianceConnection -ErrorAction Stop

				}

				Catch
				{

					$PSCmdlet.ThrowterminatingError($_)

				}
				
				# Update original object with new eTag and modifiedDate values
				$_EnclosureGroupToUpdate.eTag         = $UpdatedEg.eTag.Copy()
				$_EnclosureGroupToUpdate.modifiedDate = $UpdatedEg.modifiedDate.Copy()
				
				Try
				{

					Send-HPOVRequest -Uri $_EnclosureGroupToUpdate.uri -Method PUT -Body $_EnclosureGroupToUpdate -ApplianceConnection $_EnclosureGroupToUpdate.ApplianceConnection | Wait-HPOVTaskComplete

				}

				Catch
				{

					$PSCmdlet.ThrowterminatingError($_)

				}

			}

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
