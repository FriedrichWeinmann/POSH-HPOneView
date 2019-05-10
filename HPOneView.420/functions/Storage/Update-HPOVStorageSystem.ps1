function Update-HPOVStorageSystem 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Name','StorageSystem')]
		[Object]$InputObject,
		
		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Default")]
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

		$_StorageSystemRefreshCollection = New-Object System.Collections.ArrayList
	
	}

	Process 
	{ 

		ForEach ($_system in $InputObject) 
		{

			switch ($_system.gettype().name) 
			{

				"String" 
				{ 
					

					"[{0}] System Name was provided, calling Get-HPOVStorageSystem." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_system = Get-HPOVStorageSystem $_system

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
				}

				"PSCustomObject" 
				{
				
					if ($_system.category -eq "storage-systems") 
					{
					
						"[{0}] Storage System resource object provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						"[$($MyInvocation.InvocationName.ToString().ToUpper())] Storage System Name: {0}" -f $_system.name | Write-Verbose
						"[$($MyInvocation.InvocationName.ToString().ToUpper())] Storage System URI: {0}"  -f $_system.uri | Write-Verbose

					}

					else 
					{

						# Wrong category, generate error
						$ErrorRecord = New-ErrorRecord HPOneView.StorageSystemResourceException WrongCategoryType InvalidResult 'InputObject' -TargetType 'PSObject' -Message ("The '{0}' is the wrong value.  Only 'storage-systems' category is allowed.  Please check the value and try again." -f $_system.category)#-verbose
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				default 
				{                         
					
					# Wrong category, generate error
					$ErrorRecord = New-ErrorRecord HPOneView.StorageSystemResourceException UnsupportedDataType InvalidArgument 'InputObject' -TargetType $_system.GetType().Name -Message ("The {0} is unsupported.  Only [System.String], [System.Array] of [System.String] or [System.Management.Automation.PSCustomObject] are allowed.  Please check the value and try again." -f $_system.Gettype().Name )
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
						
				}

			}

			# Update object to refresh state
			$_system.refreshState = "RefreshPending"

			Try
			{

				$_results = Send-HPOVRequest $_system.uri PUT $_system -Hostname $_system.ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
			[void]$_StorageSystemRefreshCollection.Add($_results)

		}
   
	}

	End 
	{

		Return $_StorageSystemRefreshCollection

	}

}
