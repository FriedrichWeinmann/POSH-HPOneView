function Remove-HPOVStorageVolume 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (SupportsShouldProcess,ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('uri', 'name', 'StorageVolume')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Switch]$ExportOnly,

		[Parameter (Mandatory = $false)]
		[Switch]$Async,
	
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
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
		
		$_TaskCollection    = New-Object System.Collections.ArrayList
		$_VolumeCollection  = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput -or $InputObject -is [PSCustomObject])
		{

			"[{0}] Storage Volume Object provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
			"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.uri | Write-Verbose
			"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.ApplianceConnection.Name | Write-Verbose
			"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.category | Write-Verbose

			If ($InputObject.category -eq 'storage-volumes')
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject:$($InputObject.Name)" -TargetType PSObject -Message "The Storage Volume resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_VolumeCollection.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject:$($InputObject.Name)" -TargetType PSObject -Message "The Storage Volume resource is not an expected category type [$($StorageVolume.category)].  Allowed resource category type is 'storage-volumes'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			foreach ($_vol in $InputObject) 
			{

				# Volume passed is a URI
				if (($_vol -is [String]) -and [System.Uri]::IsWellFormedUriString($_vol,'Relative')) 
				{

					"[{0}] Received URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_vol | Write-Verbose
					"[{0}] Getting Volume object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					if (($ApplianceConnection | Measure-Object).Count -gt 1)
					{

						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException MultipleApplianceConnections InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter contains multiple Appliance Connections.  This CMDLET only supports 1 Appliance Connection in the ApplianceConnect Parameter value when using a Storage Volume Template URI value.  Please correct this and try again.'
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					Try
					{

						$_volObject = Send-HPOVRequest -Uri $_vol -ApplianceConnection $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					[void]$_VolumeCollection.Add($_volObject)

				}

				# Volume passed is the Name
				elseif (($_vol -is [string]) -and (-not($_vol.startsWith("/rest")))) 
				{

					"[{0}] Received Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_vol | Write-Verbose
					"[{0}] Getting Volume object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					ForEach ($_appliance in $ApplianceConnection)
					{

						"[{0}] Processing '$_appliance' Appliance Connection [of $($ApplianceConnection.count)]" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Try
						{

							$_volObject = Get-HPOVStorageVolume -Name $_vol -ApplianceConnection $_appliance -ErrorAction Stop

						}

						Catch
						{
							
							$PSCmdlet.ThrowTerminatingError($_)

						}

						$_volObject | ForEach-Object {

							"[{0}] Adding '$($_.name)' Volume to collection." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							[void]$_VolumeCollection.Add($_)

						}

					}

				}

				# Volume passed is the object
				elseif ($_vol -is [PSCustomObject] -and $_vol.category -ieq 'storage-volumes') 
				{
					
					"[{0}] Volume Object provided.)"-f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
					"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
					"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.uri | Write-Verbose
					"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.ApplianceConnection.Name | Write-Verbose
					"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.category | Write-Verbose

					[void]$_VolumeCollection.Add($_vol)
				
				}

				else 
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "Invalid Volume Parameter: $($_vol | Out-String)"
					$PSCmdlet.WriteError($ErrorRecord)

				}

			}

		}

	}

	End
	{

		"[{0}] Processing {1} Volume resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_VolumeCollection.count | Write-Verbose

		# Process Volume Resources
		ForEach ($_volObject in $_VolumeCollection)
		{

			if ((-not($PSBoundParameters['ExportOnly'])) -and $PSCmdlet.ShouldProcess($_volObject.name,"Remove Storage Volume from appliance '$($_volObject.ApplianceConnection.Name)'")) 
			{

				"[{0}] Removing Volume '$($_volObject.name)' and Export from appliance '$($_volObject.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					
					if ($PSBoundParameters['Force'])
					{

						$_volObject.uri += "?force=true"

					}

					$_resp = Send-HPOVRequest -Uri $_volObject.Uri -Method DELETE -Hostname $_volObject.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

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

			elseif ($PSBoundParameters['ExportOnly'] -and $PSCmdlet.ShouldProcess($_volObject.name,"Remove Storage Volume from appliance '$($_volObject.ApplianceConnection.Name)'")) 
			{

				"[{0}] Removing Volume Export '$($_volObject.name)' from appliance '$($_volObject.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					
					$_uri = '{0}?suppressDeviceUpdates=true' -f $_volObject.Uri

					if ($PSBoundParameters['Force'])
					{

						$_uri += "&force=true"

					}					

					$_resp = Send-HPOVRequest -Uri $_uri -Method DELETE -Hostname $_volObject.ApplianceConnection.Name #-addHeader @{exportOnly = [bool]$ExportOnly}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

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

			elseif ($PSBoundParameters['WhatIf'])
			{

				"[{0}] WhatIf Parameter was passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			

		}

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
