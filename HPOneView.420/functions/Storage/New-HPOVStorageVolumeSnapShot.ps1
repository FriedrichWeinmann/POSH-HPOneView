function New-HPOVStorageVolumeSnapshot
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Volume')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false)]
		[String]$Name = '{volumeName}_{timestamp}',

		[Parameter (Mandatory = $false)]
		[String]$Description,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
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
		
	}

	Process 
	{ 

		# Generate error Volume is not an object
		if ($InputObject -isnot [PSCustomObject] -and $InputObject.category -ne 'storage-volumes')
		{

			$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStorageVolumeResource InvalidArgument 'Volume' -TargetType $Volume.GetType().Name -Message "The provided Volume Parameter value is not a supported type or object.  Please provide a Storage Volume resource object and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		"[{0}] Processing Storage Volume: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

		# Validate the volume is a support volume to create a snapshot of
		# Get Storage Pool and associated SS
		Try
		{

			$_AssociatedPool = Send-HPOVRequest -Uri $InputObject.storagePoolUri -Hostname $ApplianceConnection
			$_AssociatedSS   = Send-HPOVRequest -Uri $_AssociatedPool.storageSystemUri -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}
		
		# Validate SS family
		if ($_AssociatedSS.family -ne 'StoreServ')
		{

			$ExceptionMessage = "The Storage System {0} family ({1}) of the associated storage volume, {2}, is not a StoreServ system.  Volume snapshots are supported with StoreServ class of storage systems." -f $_AssociatedSS.name, $_AssociatedPool.name, $InputObject.name
			$ErrorRecord = New-ErrorRecord ArgumentException InvalidArgumentType InvalidArgument 'DataProtectionLevel' -TargetType $DataProtectionLevel.gettype().Name -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$uri = $InputObject.uri + '/snapshots'

		# Send the query
		Try
		{

			$_VolSnapshot = NewObject -VolSnapshot

			$_VolSnapshot.name        = $Name
			$_VolSnapshot.description = $Description

			$_VolumeSnapshotResp = Send-HPOVRequest -Uri $uri -Method POST -Body $_VolSnapshot -appliance $ApplianceConnection

		}

		Catch
		{

			# Return any task resources at this point, then generate error
			$_VolumeSnapshotCollection

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not $PSBoundParameters['Async'])
		{

			$_VolumeSnapshotResp | Wait-HPOVTaskComplete

		}

		else
		{

			$_VolumeSnapshotResp

		}

	}

	End 
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
