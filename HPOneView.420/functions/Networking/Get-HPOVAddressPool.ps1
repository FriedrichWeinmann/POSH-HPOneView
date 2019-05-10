function Get-HPOVAddressPool 
{  

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(
		
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateSet ('vmac', 'vwwn', 'vsn', 'IPv4', 'all')]
		[Array]$Type = "all",
		
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

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

		"[{0}] Requested Address Pool type: $($Type) " -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if ($Type -ieq "all") { $Type = @("VMAC", "VWWN", "VSN", "IPv4") }

		$_AddressPoolCollection = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			switch ($Type) 
			{

				'IPv4'
				{

					"[{0}] Retrieve IPv4 Address Pool details." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
					# Get the VMAC Pool object
					Try
					{

						$_IPv4Pool = Send-HPOVRequest $ApplianceIPv4PoolsUri -Hostname $_appliance.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$_IPv4Pool | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AddressPool") } 
					
					[void]$_AddressPoolCollection.Add($_IPv4Pool)

				}

				"vmac" 
				{ 

					"[{0}] Retrieve VMAC Address Pool details." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
					# Get the VMAC Pool object
					Try
					{

						$_VMACPool = Send-HPOVRequest $ApplianceVmacPoolsUri -Hostname $_appliance.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$_VMACPool | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AddressPool") } 
					
					[void]$_AddressPoolCollection.Add($_VMACPool)

				}

				"vwwn" 
				{ 

					"[{0}] Retrieve VWWN Address Pool details." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose	
			
					# Get the VWWN Pool object
					Try
					{

						$_VWWNPool = Send-HPOVRequest $ApplianceVwwnPoolsUri -Hostname $_appliance.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$_VWWNPool | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AddressPool") } 
					
					[void]$_AddressPoolCollection.Add($_VWWNPool)

				}
				
				"vsn" 
				{

					"[{0}] Retrieve VSN Address Pool details." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# Get the VSN Pool object
					Try
					{

						$_VWWNPool = Send-HPOVRequest $ApplianceVsnPoolsUri -Hostname $_appliance.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$_VWWNPool | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AddressPool") } 
					
					[void]$_AddressPoolCollection.Add($_VWWNPool)

				}

			}

		}

	}

	End 
	{

		return $_AddressPoolCollection 

	}

}
