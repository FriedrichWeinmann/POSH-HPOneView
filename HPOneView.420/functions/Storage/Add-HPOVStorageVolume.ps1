function Add-HPOVStorageVolume 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[object]$StorageSystem,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("volid","id","wwn")]
		[string]$VolumeID,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[string]$StorageDeviceName,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("Name")]
		[string]$VolumeName,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[string]$Description = "",

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[switch]$Shared,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.ScopeCollection]$Scope,

		[Parameter (Mandatory = $false, ParameterSetName = "default", ValueFromPipelineByPropertyName)]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['StorageSystem']))
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

		if ($PSBoundParameters['VolumeID'])
		{

			Write-Warning 'The -VolumeID parameter is now deprecated and is no longer used.'

		}

	}

	Process 
	{


		$_addVolume = NewObject -AddStorageVolume
		$_addVolume.deviceVolumeName = $StorageDeviceName
		$_addVolume.name             = $VolumeName
		$_addVolume.description      = $Description
		$_addVolume.isShareable      = $Shared.IsPresent

		Switch ($StorageSystem.GetType().Name) 
		{

			"String" 
			{
							
				if ($StorageSystem.StartsWith($StorageSystemsUri))
				{

					"[{0}] StorageSystem URI provided by caller." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Sending request." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose   
										 
					Try
					{

						$_ss = Send-HPOVRequest -Uri $StorageSystem -Hostname $ApplianceConnection.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
				}

				elseif ($StorageSystem.StartsWith("/rest")) 
				{

					# Invalid Parameter value, generate terminating error.
					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidArgumentValue InvalidArgument 'StorageSystem' -Message "Invalid StorageSystem Parameter value: $($StorageSystem | out-string)"
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				else 
				{
								
					"[{0}] StorageSystem Name provided by caller." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Sending request." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# Get the storage volume template resource.  Terminating error will throw from the Get-* if no resource is found.
					Try
					{

						$_ss = Get-HPOVStorageSystem -SystemName $StorageSystem -ApplianceConnection $ApplianceConnection
					
					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

			}

			"PSCustomObject" 
			{

				# Validate the object
				if ($StorageSystem.category -eq 'storage-systems' -and $StorageSystem.ApplianceConnection.Name -eq $ApplianceConnection.Name) 
				{ 
					
					"[{0}] Storage System Object provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($StorageSystem.name) | Write-Verbose

					$_ss = $StorageSystem.PSObject.Copy()
				
				}

				else 
				{

					$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStorageSystemCategory InvalidArgument 'StorageSystem' -TargetType PSObject -Message "Invalid StorageSystem Parameter value.  Expected Resource Category 'storage-systems', received '$($VolumeTemplate.category)'."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			default 
			{
			
				$ErrorRecord = New-ErrorRecord HPOneView.StorageVolumeResourceException InvalidStorageSystemObject InvalidArgument 'StorageSystem' -TargetType $StorageSystem.GetType().Name -Message "Invalid StorageSystem Parameter value object type.  Only [PSCustomObject] or [String] values are allowed."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}
		
		}

		$_addVolume.storageSystemUri = $_ss.uri

		if ($PSBoundParameters['Scope'])
		{

			ForEach ($_Scope in $Scope)
			{

				"[{0}] Adding resource to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

				[void]$_addVolume.initialScopeUris.Add($_Scope.Uri)

			}

		}

		"[{0}] Add Storage Volume Object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_addVolume | Out-String) | Write-Verbose
 
		# Send the request
		Try
		{

			$_Uri = '{0}/from-existing' -f $StorageVolumesUri

			Send-HPOVRequest -Uri $_Uri -Method POST -Body $_addVolume -Hostname $ApplianceConnection.Name

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		#[void]$colStatus.Add($_resp)
		
	}

	End 
	{

		# Return $colStatus
		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
