function Remove-HPOVStoragePool 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default",SupportsShouldProcess,ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "StorageSystem")]
		[ValidateNotNullOrEmpty()]
		[Alias ("uri", "name", 'StoragePool')]
		[Object]$InputObject,

		[Parameter (Mandatory, ParameterSetName = "StorageSystem")]
		[ValidateNotNullOrEmpty()]
		[Alias ("storage")]
		[Object]$StorageSystem,
		
		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[Parameter (Mandatory = $False, ParameterSetName = "StorageSystem")]
		[switch]$Force,
	
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "StorageSystem")]
		[ValidateNotNullOrEmpty()]
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

		$_TaskCollection        = New-Object System.Collections.ArrayList
		$_StoragePoolCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput -or $InputObject -is [PSCustomObject]) 
		{

			"[{0}] Processing input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Storage Pool Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

			If ($InputObject -is [HPOneView.Storage.StoragePool] -or 'storage-pools' -contains $InputObject.category)
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject:$($InputObject.Name)" -TargetType PSObject -Message "The Storage Pool resource object provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_StoragePoolCollection.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject:$($InputObject.Name)" -TargetType PSObject -Message "The Storage Pool resource object is not an expected category type [$($StoragePool.category)].  The allowed resource category type is 'storage-pools'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing Appliance $($_appliance.Name) (of $($ApplianceConnection.Count))" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Processing Storage Pool Name $($InputObject)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_StoragePool = Get-HPOVStoragePool $InputObject -ApplianceConnection $_appliance -ErrorAction Stop

					$_StoragePool | ForEach-Object {

						[void]$_StoragePoolCollection.Add($_)

					}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}				

			}

		}

	}

	End 
	{

		"[{0}] Processing $($_StoragePoolCollection.count) Storage Pool object resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Process Storage Resources
		ForEach ($_storagepool in $_StoragePoolCollection)
		{

			if ($PSCmdlet.ShouldProcess($_storagepool.ApplianceConnection.Name,"Remove Storage Pool '$($_storagepool.name)' from appliance")) 
			{

				"[{0}] Setting Storage Pool '$($_storagepool.name)' to 'Unmanaged' on appliance '$($_storagepool.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					
					$__pool = Send-HPOVRequest -Uri $_storagepool.uri -Hostname $_storagepool.ApplianceConnection
					
				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				# Good here... unmanage the storage pool
				$__pool.isManaged = $false

				Try
				{

					$_resp = Send-HPOVRequest -Uri $_storagepool.Uri -Method PUT -Body $__pool -Hostname $_storagepool.ApplianceConnection

					[void]$_TaskCollection.Add($_resp)

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

		}

		Return $_TaskCollection

	}

}
