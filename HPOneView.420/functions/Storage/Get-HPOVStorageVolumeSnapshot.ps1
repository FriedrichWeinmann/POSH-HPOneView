function Get-HPOVStorageVolumeSnapShot
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Name', 'Volume')]
		[Object]$InputObject,

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

	}

	Process 
	{ 
		
		# Generate error Volume is not an object
		if (-not($InputObject -is [PSCustomObject]) -and $InputObject.category -ne 'storage-volumes')
		{

			$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStorageVolumeResource InvalidArgument 'Volume' -TargetType $Volume.GetType().Name -Message "The provided Volume Parameter value is not a supported type or object.  Please provide a Storage Volume resource object and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}


		"[{0}] Processing Storage Volume: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

		$uri = $InputObject.uri + '/snapshots'

		# Send the query
		Try
		{

			$_VolumeSnapshots = Send-HPOVRequest -Uri $uri -appliance $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not($_VolumeSnapshots.members))
		{

			"[{0}] No Storage Volume Snapshots found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		else 
		{

			$_VolumeSnapshots.members | ForEach-Object { 

				$_.PSObject.TypeNames.Insert(0,"HPOneView.Storage.VolumeSnapshot") 
					
				$_
					
			} 	

		}

	}

	End 
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
