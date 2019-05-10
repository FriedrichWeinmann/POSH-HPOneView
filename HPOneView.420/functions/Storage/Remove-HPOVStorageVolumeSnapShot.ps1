function Remove-HPOVStorageVolumeSnapshot
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Snapshot')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false)]
		[Switch]$Async,

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
		
		$_VolumeSnapshotCollection = New-Object System.Collections.ArrayList
		$_TaskCollection           = New-Object System.Collections.ArrayList

	}

	Process 
	{ 
		
		# Generate error Snapshot is not an object or correct object
		if (-not($InputObject -is [PSCustomObject]) -and $InputObject.category -ne 'storage-volumes' -and (-not($InputObject -match '/snapshots/')))
		{

			$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStorageVolumeResource InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message "The provided Volume Snapshot Parameter value is not a supported type or object.  Please provide a Storage Volume Snapshot resource object and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		"[{0}] Received Storage Volume Snapshot: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

		[void]$_VolumeSnapshotCollection.Add($InputObject)

	}

	End 
	{

		"[{0}] Processing {1} Storage Volume Snapshot resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper(),$_VolumeSnapshotCollection.count | Write-Verbose 

		# Process Resources
		ForEach ($_resource in $_VolumeSnapshotCollection)
		{

			if ($PSCmdlet.ShouldProcess($_resource.ApplianceConnection.Name,("remove volume snapshot '{0}'" -f $_resource.name))) 
			{

				"[{0}] Removing resource '{1}' from appliance '{2}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_resource.name,$_resource.ApplianceConnection.Name | Write-Verbose 

				Try
				{
					
					$_resp = Send-HPOVRequest -uri $_resource.Uri -Method DELETE -Hostname $_resource.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($PSBoundParameters['WhatIf'])
			{

				"[{0}] WhatIf Parameter was passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			if (-not $PSBoundParameters['Async'])
			{

				$_resp | Wait-HPOVTaskComplete

			}

			else
			{

				$_resp

			}

		}

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
