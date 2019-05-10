function Remove-HPOVStorageSystem 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default",SupportsShouldProcess,ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("uri","name","StorageSystem")]
		[object]$InputObject,

		[Parameter (Mandatory = $false)]
		[switch]$force,
	
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
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

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command agian."
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

		$_TaskCollection = New-Object System.Collections.ArrayList
		$_StorageSystemCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput -or $InputObject -is [PSCustomObject]) 
		{

			"[{0}] Processing input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Storage System Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

			If ('storage-systems' -contains $InputObject.category)
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject:$($InputObject.Name)" -TargetType PSObject -Message "The Storage System resource object provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_StorageSystemCollection.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject:$($InputObject.Name)" -TargetType PSObject -Message "The Storage System resource object is not an expected category type [$($InputObject.category)].  The allowed resource category type is 'storage-systems'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing Appliance $($_appliance.Name) (of $($ApplianceConnection.Count))" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Processing Storage System Name $($StorageSystem)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_StorageSystem = Get-HPOVStorageSystem $InputObject -ApplianceConnection $_appliance

					$_StorageSystem | ForEach-Object {

						[void]$_StorageSystemCollection.Add($_)

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

		"[{0}] Processing $($_StorageSystemCollection.count) Storage System object resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Process Storage Resources
		ForEach ($_storagesystem in $_StorageSystemCollection)
		{

			if ($PSCmdlet.ShouldProcess($_storagesystem.ApplianceConnection.Name,"Remove Storage System '$($_storagesystem.name)' from appliance")) 
			{

				"[{0}] Removing Storage System '$($_storagesystem.name)' from appliance '$($_storagesystem.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				if ($PSboundParameters['force'])
				{

					$_storagesystem.uri += "?force=true"

				}

				Try
				{

					$_resp = Send-HPOVRequest -Uri $_storagesystem.Uri -Method DELETE -Hostname $_storagesystem.ApplianceConnection.Name -AddHeader @{'If-Match' = '*'}

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
