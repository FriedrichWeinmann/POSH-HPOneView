function Add-HPOVStoragePool 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Hostname', 'name')]
		[object]$StorageSystem,

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[Alias ('PoolName', 'spName', 'cpg')]
		[object]$Pool,

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

		if (-not($PSboundParameters['StorageSystem']))
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

		$colStatus = New-Object System.Collections.ArrayList

		Write-Warning "This Cmdlet will be deprecated in a future release.  Please update your scripts to use Set-HPOVStoragePool."

	}
	 
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing appliance '{1}' (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose
		
			ForEach ($_pool in $Pool)
			{

				"[{0}] Processing '$_pool'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Validate StroageSystem Parameter object
				if ($StorageSystem -is [PSCustomObject] -and $StorageSystem.ApplianceConnection.Name -ne $_appliance.Name)
				{

					$ErrorRecord = New-ErrorRecord HPOneView.StoragePoolResourceException InvalidateStorageSystemApplianceConnection InvalidArgument 'StorageSystem' -TargetType 'PSObject' -Message "The -StorageSystem object does not appear to originate [$($StorageSystem.ApplianceConnection.Name)] from the same provided ApplianceConnection [$($_appliance.Name)]"
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				elseif ($StorageSystem -is [PsCustomObject] -and $StorageSystem.category -eq "storage-systems") 
				{ 

					"[{0}] Storage System resource object was provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StorageSystem.name, $StorageSystem.uri | Write-Verbose
					
					$_StorageSystem = $StorageSystem.PSObject.Copy()
					
				}
				
				# Else the PsCustomObject is not the correct Category type, so error.
				elseif ($StorageSystem -is [PsCustomObject]) 
				{
				
					$ErrorRecord = New-ErrorRecord HPOneView.StoragePoolResourceException InvalidResourceCategoryValue InvalidArgument 'StorageSystem' -TargetType 'PSObject' -Message "The -StorageSystem Parameter value is the wrong resource type ($($StorageSystem.category)). The correct resource category 'storage-systems' is allowed.  Please check the value and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# Do not allow an array
				elseif ($StorageSystem -is [Array]) 
				{

					$ErrorRecord = New-ErrorRecord HPOneView.StoragePoolResourceException ArrayNotAllow InvalidArgument 'StorageSystem' -TargetType 'PSObject' -Message "The -StorageSystem Parameter only accepts [System.String] or [System.Management.Automation.PSCustomObject] value.  Please correct the value and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				else 
				{

					"[{0}] Storage System Name is passed $($StoragSystem)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting list of Storage Systems" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_storagesystem = Get-HPOVStorageSystem -SystemName $StorageSystem -ApplianceConnection $_appliance.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					# Generate Terminating Error if Storage System resource not found
					if (-not($_storagesystem)) 
					{
							
						"[{0}] Woops! No '$StorageSystem' Storage System found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$ErrorRecord = New-ErrorRecord HPOneView.StoragePoolResourceException StorageSystemResourceNotFound ObjectNotFound 'StorageSystem' -Message "No Storage System with '$StorageSystem' system name found.  Please check the name or use Add-HPOVStorageSystem to add the Storage System."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}
					
				}

				# Get the list of unmanaged and managed pools in the managed domain
				Try
				{
					
					$_Results = Send-HPOVRequest ("{0}?filter=name EQ '{1}'" -f $_storagesystem.storagePoolsUri, $_pool) -Hostname $_appliance.Name
					[PSCustomObject]$_PoolFound = $_Results.members[0]

					"[{0}] Storage Pool object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_PoolFound | Out-String) | Write-Verbose

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if (-not $_PoolFound)
				{

					# Storage pool resource does not exist in the existing managed list or in the unmanaged list in the managed domain
					"[{0}] No Storage pool resource with '{1}'  found in the managed Storage System." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_pool | Write-Verbose

					$ErrorRecord = New-ErrorRecord HPOneView.StoragePoolResourceException StorageSystemResourceNotFound ObjectNotFound 'PoolName' -Message "No Storage pool resource with '$_pool' found in the managed Storage System."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				elseif ($_PoolFound.isManaged)
				{

					"[{0}] Storage pool resource '{1}' already exists in the managed list." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_pool | Write-Verbose

					$ErrorRecord = New-ErrorRecord HPOneView.StoragePoolResourceException StoragePoolResourceExists ResourceExists 'PoolName' -Message "Storage pool resource '$_pool' already exists in the managed list."
					$PSCmdlet.WriteError($ErrorRecord) #"Storage pool resource '$p' already exists"

				}

				else
				{

					# Good here... Add the storage pool
					$_PoolFound.isManaged = $true
					
					# Add the pool to array of pools to manage
					Try
					{

						Send-HPOVRequest -Uri $_PoolFound.uri -method PUT -body $_PoolFound -Hostname $_PoolFound.ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
				}

			}

		}

	}

	End  
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Return $colStatus

	}

}
