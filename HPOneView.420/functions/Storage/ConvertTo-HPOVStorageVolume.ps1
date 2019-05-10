function ConvertTo-HPOVStorageVolume
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty ()]
		[Alias ('Snapshot')]
		[Object]$InputObject,

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty ()]
		[String]$Name,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty ()]
		[String]$Description,

		[Parameter (Mandatory = $false)]
		[ValidateSet ('Private', 'Shared')]
		[String]$SharingMode,

		[Parameter (Mandatory = $false)]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
		[ValidateNotNullorEmpty ()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject']))
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
		
		$_VolumeSnapshotTaskCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{ 
		
		# Generate error Snapshot is not an object or correct object
		if (-not($InputObject -is [PSCustomObject]) -and $InputObject.category -ne 'storage-volumes' -and (-not($InputObject -match '/snapshots/')))
		{

			$ExceptionMessage = "The provided InputObject parameter value is not a supported type or object.  Please provide a Storage Volume Snapshot resource object and try again."
			$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStorageSnapshotResource InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		"[{0}] Processing Storage Volume Snapshot: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

		$_ConvertSnapshotToVol                        = NewObject -ConvertSnapshotToVol
		$_ConvertSnapshotToVol.properties.name        = $Name
		$_ConvertSnapshotToVol.properties.description = $Description
		$_ConvertSnapshotToVol.snapshotUri            = $InputObject.uri
		
		# Get parent volume snapshotUri value
		Try
		{

			$_ParentVol = Send-HPOVRequest -Uri $InputObject.storageVolumeUri -Hostname $InputObject.ApplianceConnection.Name

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$_ConvertSnapshotToVol.properties.snapshotPool     = $_ParentVol.deviceSpecificAttributes.snapshotPoolUri
		$_ConvertSnapshotToVol.properties.storagePool      = $_ParentVol.storagePoolUri
		$_ConvertSnapshotToVol.properties.provisioningType = $_ParentVol.provisioningType

		if (-not $_ParentVol.volumeTemplateUri) 
		{

			# Need to get root template from system via storage pool
			try
			{

				$_AssociatedPool = Send-HPOVRequest -Uri $_ParentVol.storagePoolUri -Hostname $InputObject.ApplianceConnection.Name

				"[{0}] Getting storage system root volume template." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				$_Uri = '{0}/templates?filter=isRoot EQ true' -f $_AssociatedPool.storageSystemUri
				$_RootTemplate = (Send-HPOVRequest -Uri $_Uri -Hostname $InputObject.ApplianceConnection.Name).members[0]

				$_ConvertSnapshotToVol.templateUri = $_RootTemplate.uri

			}

			catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		else
		{

			$_ConvertSnapshotToVol.templateUri = $_ParentVol.volumeTemplateUri	
			
		}

		if (-not $PSBoundParameters['SharingMode'])
		{

			$_ConvertSnapshotToVol.properties.isShareable = $_ParentVol.isShareable

		}

		else
		{

			$_ConvertSnapshotToVol.properties.isShareable = $SharingMode.IsPresent

		}
		
		# Send the query
		Try
		{

			$_VolumeSnapshotResp = Send-HPOVRequest -Uri $StorageVolumeFromSnapshotUri -Method POST -Body $_ConvertSnapshotToVol -appliance $InputObject.ApplianceConnection.Name

		}

		Catch
		{

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
