function Get-HPOVAvailableDriveType
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName='Default')]

	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $PSBoundParameters['InputObject'])
		{

			$PipelineInput = $true
			
		}

		else
		{

			"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if (-not $ApplianceConnection)
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
			
	}

	Process 
	{

		if (($ConnectedSessions | Where-Object Name -eq $InputObject.ApplianceConnection.Name).ApplianceType -ne 'Composer')
		{

			$ExceptionMessage = 'The ApplianceConnection {0} is not a Synergy Composer.  This Cmdlet is only supported with Synergy Composers.' -f $ApplianceConnection.Name
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
			$PSCmdlet.WriteError($ErrorRecord)

		}

		else
		{

			switch ($InputObject.category)
			{

				'sas-logical-interconnects'
				{

					$_SasLogicalInterconnect = $InputObject.PSObject.Copy()
					$InputObject = New-Object System.Collections.ArrayList

					"[{0}] SAS Logical Interconnect provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_SasLogicalInterconnect.name | Write-Verbose
					"[{0}] Getting all associated drive enclosures: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_SasLogicalInterconnect.driveEnclosureUris.count | Write-Verbose				

					ForEach ($_DriveEnclosureUri in $_SasLogicalInterconnect.driveEnclosureUris)
					{

						Try
						{

							$_DriveEnclosure = Send-HPOVRequest -uri $_DriveEnclosureUri -Hostname $ApplianceConnection

							$_DriveEnclosure | Add-Member -NotePropertyName sasLogicalInterconnectName -NotePropertyValue $_SasLogicalInterconnect.name

							[void]$InputObject.Add($_DriveEnclosure)

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

				}

				'drive-enclosures'
				{

					"[{0}] Drive Enclosure provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

					$_uri = "{0}?category=sas-logical-interconnects&start=0&count=-1&name=DRIVE_ENCLOSURE_TO_SAS_LOGICAL_INTERCONNECT&parentUri={1}" -f $IndexAssociatedResourcesUri, $InputObject.uri

					Try
					{

						$_associatedogicalInterconnect = Send-HPOVRequest -uri $_uri -Hostname $ApplianceConnection

						$InputObject | Add-Member -NotePropertyName sasLogicalInterconnectName -NotePropertyValue $_associatedogicalInterconnect.members[0].childResource.name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				default
				{

					# Generate error due to invalid object
					if ($Inputobject -is [PSCustomObject])
					{

						$_InputObjectName = $InputObject.name

					}

					else
					{

						$_InputObjectName = $InputObject

					}

					$ExceptionMessage = "The specified '{0}' InputObject parameter value is not supported type.  Only SAS Logical Interconnect or Disk Drive resources are allowed." -f $_InputObjectName
					$ErrorRecord = New-ErrorRecord HPOneView.InputObjectResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			ForEach ($_DriveEnclosure in $InputObject)
			{

				"[{0}] Processing drive enclosure: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_DriveEnclosure.name | Write-Verbose

				$_uri = "{0}?category=drives&start=0&count=-1&userQuery='{1} AND available=yes'" -f $IndexUri, $_DriveEnclosure.uri

				Try
				{

					$_AvailableDrives = Send-HPOVRequest -uri $_uri -Hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				$_TempDriveCollection = New-Object System.Collections.ArrayList

				ForEach ($_MemberDrive in $_AvailableDrives.members)
				{

					$_AvailableDrive = $null

					'[{0}] Collecting: {1} Type {2} Capacity' -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_MemberDrive.attributes.interfaceType + $_MemberDrive.attributes.mediaType), $_MemberDrive.attributes.capacityInGb | Write-Verbose

					# Filter for the number of drives based on combined interfaceType and interfaceMedia
					[Array]$NumberOfDrives = $_AvailableDrives.members | Where-Object { $_.attributes.interfaceType -eq $_MemberDrive.attributes.interfaceType -and $_.attributes.mediaType -eq $_MemberDrive.attributes.mediaType -and $_.attributes.capacityInGb -eq $_MemberDrive.attributes.capacityInGb }
					
					# Create temporary drive object to store values for compare and new object
					$_DriveAttributes = [PSCustomObject]@{Type = ($_MemberDrive.attributes.interfaceType + $_MemberDrive.attributes.mediaType); Count = $NumberOfDrives.Count; Capacity = [Convert]::ToInt32($_MemberDrive.attributes.capacityInGb)}
					
					if ((-not ($_TempDriveCollection.Type | Where-Object { $_ -contains $_DriveAttributes.Type})) -or (($_TempDriveCollection.Type | Where-Object { $_ -contains $_DriveAttributes.Type}) -and -not ($_TempDriveCollection | Where-Object { $_.Capacity -contains $_DriveAttributes.Capacity})))
					{

						'[{0}] Adding drive type {1} and capacity {2} to collection' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_DriveAttributes.Type, $_DriveAttributes.Capacity | Write-Verbose

						$_AvailableDrive = New-Object HPOneView.Storage.AvailableDriveType($_DriveAttributes.Type, 
																						   $_DriveAttributes.Capacity,
																						   $_DriveAttributes.Count,
																						   $_DriveEnclosure.name, 
																						   $_DriveEnclosure.sasLogicalInterconnectName, 																						    
																						   $ApplianceConnection)

						[Void]$_TempDriveCollection.Add($_AvailableDrive)

					}

				}

				$_TempDriveCollection | Sort-Object Type, Capacity

			}

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
