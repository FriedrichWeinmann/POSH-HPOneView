function New-HPOVServerProfileLogicalDiskController
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "Import")]
		[ValidateSet ('Embedded','Mezz 1','Mezz 2','Mezz 3','Mezz 3')]
		[Object]$ControllerID = 'Embedded',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "Import")]
		[ValidateSet ('HBA','RAID','MIXED')]
		[String]$Mode = 'RAID',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "Import")]
		[switch]$Initialize,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "Import")]
		[ValidateSet ('Enabled', 'Disabled', "Unmanaged")]
		[String]$WriteCache = "Unmanaged",

		[Parameter (Mandatory = $false, ParameterSetName = "Import")]
		[switch]$ImportExistingConfiguration,

		[Parameter (Mandatory = $false, ParameterSetName = "Default", ValueFromPipeline)]
		[Object]$LogicalDisk

	)
		
	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Helper cmdlet does not require authentication." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
		# Init object collection
		$_ServerProfileController = NewObject -ServerProfileLocalStorageController
		$_ServerProfileController.deviceSlot          = $ControllerID
		$_ServerProfileController.mode                = $Mode

		if ($ControllerID -notmatch 'Mezz')
		{

			$_ServerProfileController.importConfiguration = $ImportExistingConfiguration.IsPresent
			$_ServerProfileController.initialize          = $Initialize.IsPresent

		}

		if ($PSBoundParameters['WriteCache'])
		{

			"[{0}] Setting controller write cache: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $WriteCache | Write-Verbose

			$_ServerProfileController.driveWriteCache = $WriteCache

		}

		$_id = 1

	}

	Process
	{	

		# THIS IS NOT CORRECT.  HBA MODE SUPPORTS LOGICALDISK
		# # Generate terminating error
		# if ($PSBoundParameters['Mode'] -eq 'HBA' -and $PSBoundParameters['LogicalDisk'])
		# {

		# 	$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedControllerMode InvalidArgument "Mode" -Message "The provide 'HBA' mode does not support assigning of Logical Disks."
		# 	$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		# }

		if ($PSBoundParameters['ImportExistingConfiguration'] -and $PSBoundParameters['LogicalDisk'])
		{

			$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException SupportedParameterUse InvalidArgument "ImportExistingConfiguration" -Message "Combining ImportExistingConfiguration and LogicalDisk Parameters is not supported."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Is an Array
		if ($LogicalDisk -is [System.Collections.IEnumerable])
		{

			"[{0}] Processing LogicalDisks collection" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose			

			ForEach ($_ld in $LogicalDisk)
			{

				"[{0}] {1} of {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ld, $LogicalDisk.Count | Write-Verbose

				if ($_ld.SasLogicalJBOD)
				{

					if ($_ServerProfileController.deviceSlot -eq 'Embedded')
					{

						$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedControllerMode InvalidArgument "LogicalDisks" -TargetType 'PSObject' -Message "The provided Logical Disks contains a SAS JBOD policy, which is not supported with the 'Embedded' Controller."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					$_ld.SasLogicalJBOD.deviceSlot = $_ServerProfileController.deviceSlot

					# Figure out new SasLogicalJBODId
					if ($_ServerProfileController.logicalDrives.sasLogicalJbod.id)
					{

						while ($_ServerProfileController.logicalDrives.sasLogicalJbod.id -contains $_id)
						{

							$_id++

						}			

					}

					$_ld.SasLogicalJBOD.id         = $_id
					$_ld.sasLogicalJBODId          = $_id	

				}

				if (($_ld.raidLevel -and $PSBoundParameters['Mode'] -eq 'HBA') -or (-not($_ld.raidLevel) -and $PSBoundParameters['Mode'] -eq 'RAID'))
				{

					$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedControllerMode InvalidArgument "Mode" -Message "The Controller can only operate in a single mode: RAID or HBA.  One or more of the provided LogicalDisks are defined for the opposite mode."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_ServerProfileController.logicalDrives.Add($_ld)

			}

		}

		elseif ($LogicalDisk -is [PSCustomObject])
		{

			"[{0}] Processing Logical Disk: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalDisk.name | Write-Verbose

			if ($LogicalDisk.SasLogicalJBOD)
			{

				if ($_ServerProfileController.deviceSlot -eq 'Embedded')
				{

					$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedControllerMode InvalidArgument "LogicalDisks" -TargetType 'PSObject' -Message "The provided Logical Disks contains a SAS JBOD policy, which is not supported with the 'Embedded' Controller."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$LogicalDisk.SasLogicalJBOD.deviceSlot = $_ServerProfileController.deviceSlot

				# Figure out new SasLogicalJBODId
				if ($_ServerProfileController.logicalDrives.sasLogicalJbod.id)
				{

					while ($_ServerProfileController.logicalDrives.sasLogicalJbod.id -contains $_id)
					{

						$_id++

					}

					$LogicalDisk.SasLogicalJBOD.id = $_id
					$LogicalDisk.sasLogicalJBODId  = $_id						

				}

			}

			if (($LogicalDisk.raidLevel -and $PSBoundParameters['Mode'] -eq 'HBA') -or (-not($LogicalDisk.raidLevel) -and $PSBoundParameters['Mode'] -eq 'RAID'))
			{

				$ErrorRecord = New-ErrorRecord HPOneview.ServerProfile.LogicalDiskException UnsupportedControllerMode InvalidArgument "Mode" -Message "The Controller can only operate in a single mode: RAID or HBA.  One or more of the provided LogicalDisks are defined for the opposite mode."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			[void]$_ServerProfileController.logicalDrives.Add($LogicalDisk)		

		}



	}

	End
	{

		Return $_ServerProfileController

	}

}
