function New-HPOVServerProfileLogicalDisk 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[Parameter (Mandatory, ParameterSetName = "SynergyJBOD")]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false , ParameterSetName = "SynergyJBOD")]
		[ValidateSet ('RAID0', 'RAID1', 'RAID1ADM', 'RAID10', 'RAID5', 'RAID6', 'NONE')]
		[string]$RAID = 'RAID1',

		[Parameter (Mandatory = $false , ParameterSetName = "Default")]
		[Parameter (Mandatory = $false , ParameterSetName = "SynergyJBOD")]
		[ValidateNotNullOrEmpty()]
		[Int]$NumberofDrives = 2,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SynergyJBOD")]
		[ValidateSet ('SAS', 'SATA', 'SASSSD', 'SATASSD', 'NVMeSas', 'NVMeSata', 'Auto')]
		[string]$DriveType = 'Auto',

		[Parameter (Mandatory = $false, ParameterSetName = "SynergyJBOD")]
		[ValidateSet ('DriveType', 'SizeAndTechnology')]
		[String]$DriveSelectionBy = 'SizeAndTechnology',

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "SynergyJBOD")]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Storage.AvailableDriveType]$AvailableDriveType,

		[Parameter (Mandatory = $false , ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SynergyJBOD")]
		[ValidateSet ('Internal', 'External')]
		[String]$StorageLocation = "External",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateSet ('Enabled', 'Disabled', "SsdSmartPath", "Unmanaged")]
		[String]$Accelerator = "Unmanaged",

		[Parameter (Mandatory = $false, ParameterSetName = "SynergyJBOD")]
		[ValidateNotNullOrEmpty()]
		[Int]$MinDriveSize,

		[Parameter (Mandatory = $False, ParameterSetName = "SynergyJBOD")]
		[ValidateNotNullOrEmpty()]
		[Int]$MaxDriveSize,

		[Parameter (Mandatory = $False, ParameterSetName = "SynergyJBOD")]
		[ValidateNotNullOrEmpty()]
		[Bool]$EraseDataOnDelete = $false,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SynergyJBOD")]
		[ValidateNotNullOrEmpty()]
		[bool]$Bootable

	)
	
	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Helper cmdlet does not require authentication." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
		# Init object collection
		$_LogicalDiskCol = New-Object System.Collections.ArrayList
		if ($PSCmdlet.ParameterSetName -eq 'Default' -and $StorageLocation -eq 'External')
		{

			$StorageLocation = 'Internal'

		}

	}

	Process 
	{

		switch ($PSCmdlet.ParameterSetName)
		{

			'Default'
			{

				# Perform validation
				if ($RAID -eq 'RAID1' -and $NumberofDrives -ne 2)
				{

					$ExceptionMessage = "The specified RAID Mode 'RAID1' is invalid with more or less than 2 drives.  Please correct either the -RAID or -NumberofDrives parameter to the supported value."
					$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException InvalidRaidModeForNumberofDrives InvalidArgument "NumberofDrives" -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				elseif ($RAID -eq 'RAID1ADM' -and $NumberofDrives -ne 3)
				{

					$ExceptionMessage = "The specified RAID Mode 'RAID1ADM' is invalid with more or less than 3 drives.  Please correct either the -RAID or -NumberofDrives parameter to the supported value."
					$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException InvalidRaidModeForNumberofDrives InvalidArgument "NumberofDrives" -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_LogicalDisk = NewObject -ServerProfileLocalStorageLogicalDrive

				$_LogicalDisk.name              = $Name
				$_LogicalDisk.bootable          = [bool]$Bootable
				$_LogicalDisk.raidLevel         = $RAID.ToUpper()
				$_LogicalDisk.numPhysicalDrives = $NumberofDrives
				$_LogicalDisk.driveTechnology   = $LogicalDiskTypeEnum[$DriveType]

				if ($PSBoundParameters['Accelerator'])
				{

					Switch ($Accelerator)
					{

						'SsdSmartPath'
						{

							if ($DriveType -Match "SSD")
							{

								$_LogicalDisk.accelerator = "IOBypass"

							}

							else
							{

								$ExceptionMessage = "Accelerator parameter value 'SsdSmartPath' is only supported with SSD drives."
								$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedControllerMode InvalidArgument "Accelerator" -Message $ExceptionMessage
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

						}

						"Enabled"
						{

							$_LogicalDisk.accelerator = "ControllerCache"

						}

						"Disabled"
						{

							$_LogicalDisk.accelerator = "None"

						}

						# "Unmanaged" is the default setting from NewObject call

					}

				}

			}

			'SynergyJBOD'
			{

				$_SasLogicalJBOD = NewObject -ServerProfileSasLogicalJBOD
				$_LogicalDisk    = NewObject -ServerProfileLocalStorageLogicalDrive
				
				$_SasLogicalJBOD.id                = 1;
				$_SasLogicalJBOD.name              = $Name
				$_SasLogicalJBOD.eraseData         = $EraseDataOnDelete
				$_SasLogicalJBOD.numPhysicalDrives = $NumberofDrives

				if ($AvailableDriveType)
				{

					$_SasLogicalJBOD.driveTechnology = $LogicalDiskTypeEnum[$AvailableDriveType.Type]
					$_SasLogicalJBOD.driveMinSizeGB  = $AvailableDriveType.Capacity
					$_SasLogicalJBOD.driveMaxSizeGB  = $AvailableDriveType.Capacity

				}

				else
				{

					$_SasLogicalJBOD.driveMinSizeGB  = $MinDriveSize
					$_SasLogicalJBOD.driveMaxSizeGB  = if (-not $PSBoundParameters['MaxDriveSize']) { $MinDriveSize } Else { $MaxDriveSize }
					$_SasLogicalJBOD.driveTechnology = $LogicalDiskTypeEnum[$DriveType]

				}				

				if ($PSBoundParameters['RAID'])
				{

					if ($DriveType -eq 'Auto' -and -not $AvailableDriveType -and $StorageLocation -eq 'External')
					{

						$ExceptionMessage = "DriveType parameter must not be 'Auto' when configuring an HP Synergy D3940 LogicalDisk."
						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedControllerMode InvalidArgument "DriveType" -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if ($RAID -eq 'RAID1' -and $NumberofDrives -ne 2)
					{

						$ExceptionMessage = "The specified RAID Mode 'RAID1' is invalid with more or less than 2 drives.  Please correct either the -RAID or -NumberofDrives parameter to the supported value."
						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException InvalidRaidModeForNumberofDrives InvalidArgument "NumberofDrives" -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					elseif ($RAID -eq 'RAID1ADM' -and $NumberofDrives -ne 3)
					{

						$ExceptionMessage = "The specified RAID Mode 'RAID1ADM' is invalid with more or less than 3 drives.  Please correct either the -RAID or -NumberofDrives parameter to the supported value."
						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException InvalidRaidModeForNumberofDrives InvalidArgument "NumberofDrives" -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					$_LogicalDisk.raidLevel        = $RAID.ToUpper()
					$_LogicalDisk.sasLogicalJBODId = 1
					$_LogicalDisk.bootable         = [bool]$Bootable

				}

				else
				{

					$_LogicalDisk.sasLogicalJBODId = 1

				}

				$_LogicalDisk | Add-Member -NotePropertyName SasLogicalJBOD -NotePropertyValue $_SasLogicalJBOD -Force
				
			}

		}       

		"[{0}] Created Logical Disk object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_LogicalDisk | Format-List * | Out-String) | Write-Verbose

		$_LogicalDisk
		
	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
