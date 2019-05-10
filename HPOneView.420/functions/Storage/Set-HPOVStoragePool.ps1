function Set-HPOVStoragePool 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Pool')]
		[HPOneView.Storage.StoragePool[]]$InputObject,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Bool]$Managed,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
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

	}
	 
	Process 
	{
	
		ForEach ($_pool in $InputObject)
		{

			"[{0}] Processing storage pool {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_pool.Name, $_pool.uri | Write-Verbose

			if ($_pool.isManaged -and $Managed)
			{

				"[{0}] Storage pool resource '{1}' is already managed." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_pool.Name | Write-Verbose

				$ExceptionMessage = "Storage pool resource '{0}' is already managed." -f $_pool.Name
				$ErrorRecord = New-ErrorRecord HPOneView.StoragePoolResourceException StoragePoolResourceExists ResourceExists 'InputObject' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				# Get the list of unmanaged and managed pools in the managed domain
				Try
				{
					
					$__pool = Send-HPOVRequest -Uri $_pool.uri -Hostname $_pool.ApplianceConnection
					
				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				# Good here... Add the storage pool
				$__pool.isManaged = $Managed
				
				# Add the pool to array of pools to manage
				Try
				{

					Send-HPOVRequest -Uri $_pool.uri -method PUT -body $__pool -Hostname $_pool.ApplianceConnection

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

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
