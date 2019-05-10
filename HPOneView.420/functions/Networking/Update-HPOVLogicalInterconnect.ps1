function Update-HPOVLogicalInterconnect 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "Reapply")]
		[ValidateNotNullorEmpty()]
		[Alias ('uri', 'li','name','Resource')]
		[object]$InputObject,
		
		[Parameter (ValueFromPipelineByPropertyName, ParameterSetName = "default", Mandatory = $false)]
		[Parameter (ValueFromPipelineByPropertyName, ParameterSetName = "Reapply", Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory, ParameterSetName = "Reapply")]
		[switch]$Reapply

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

		$_returntasks = New-Object System.Collections.ArrayList
		$_liobjects   = New-Object System.Collections.ArrayList

	}

	Process 
	{

		"[{0}] Processing $($InputObject.count) LI objects." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		foreach ($_li in $InputObject) 
		{
			
			# Name provided
			if (($_li -is [String]) -and (-not($_li.StartsWith($LogicalInterconnectsUri))))
			{

				"[{0}] LI Name was provided '$($_li)'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Loop through appliance connections to add LI objects to collection
				ForEach ($_appliance in $ApplianceConnection)
				{

					Try 
					{

						Get-HPOVLogicalInterconnect -Name $_li -ApplianceConnection $_appliance.Name | ForEach-Object { [void]$_liobjects.Add($_) }

					}
						
					Catch
					{

						"[{0}] $_.FullyQualifiedErrorId Error Caught:  $($_.Exception.Message)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				"[{0}] Retrieved $($_liobjects.count) LI Objects" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			elseif (($_li -is [String]) -and ($_li.StartsWith($LogicalInterconnectsUri))) 
			{

				# User didn't provide an appliance connection during call
				if (-not($PSBoundParameters['ApplianceConnection']) -and $ApplianceConnection.Count -gt 1)
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException LogicalInterconnectUriNoApplianceConnection InvalidArgument 'ApplianceConnection' -Message "A Logical Interconnect URI was provided in the -Resource Parameter, but no Appliance Connection specified.  URI's are unique per appliance connection.  Please specify an Appliance Connection and try your call again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}
				
				# User provided more than 1 appliance connection, and LI URI, generate error
				elseif ($ApplianceConnection.Count -gt 1)
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException LogicalInterconnectUriMultipleApplianceConnections InvalidArgument 'ApplianceConnection' -Message "A Logical Interconnect URI was provided in the -Resource Parameter, with multiple Appliance Connections specified.  URI's are unique per appliance connection.  Please specify an Appliance Connection and try your call again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				"[{0}] LI URI was provided $($_li)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try 
				{

					Send-HPOVRequest $_li -HostName $ApplianceConnection.Name | ForEach-Object { [void]$_liobjects.Add($_) }

				}
						
				Catch
				{

					"[{0}] $_.FullyQualifiedErrorId Error Caught:  $($_.Exception.Message)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif (($_li -is [PSCustomObject]) -and ($_li.category -ieq 'logical-interconnects')) 
			{

				"[{0}] LI Object was provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_li.name, $_li.uri | Write-Verbose

				[void]$_liobjects.Add($_li)

			}

			else 
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Resource' -TargetType $_li.GetType().Name -Message "An invalid Resource object was provided. $($_li.GetType()) $($_li.category) was provided.  Only type String or PSCustomObject, and 'logical-interconnects' object category are permitted."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

	}

	End 
	{

		# Loop through liobject collection to perform action
		ForEach ($_liobject in $_liobjects)
		{

			"[{0}] Processing Logical Interconnect: $($_liobject.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($PSboundParameters['Reapply'])
			{ 

				"[{0}] Reapply LI configuration requested." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
				if ($PSCmdlet.ShouldProcess($_liobject.name,"Reapply Logical Interconnect configuration. WARNING: Depending on this action, there might be a brief outage."))
				{ 

					Try
					{

						"[{0}] Sending request to reapply configuration" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
						$uri = $_liobject.uri + "/configuration"

						$task = Send-HPOVRequest $uri PUT -Hostname $_liobject.ApplianceConnection.Name

						[void]$_returntasks.Add($task)

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				elseif ($PSBoundParameters['WhatIf'])
				{
					
					"[{0}] User included -WhatIf." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

				else
				{

					"[{0}] User cancelled." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}
				
			}

			else 
			{
				
				# Do not Process LI if consistencyStatus is good.
				if ($_liobject.consistencyStatus -eq 'CONSISTENT')
				{

					Write-Warning 'Logical Interconnect is Consistent with Policy.  Nothing to do.'

				}

				else
				{

					"[{0}] Update '$($liDisplayName)' Logical Interconnect from parent $($parentLig.name)." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_ligname = (Send-HPOVRequest $_liobject.logicalInterconnectGroupUri -HostName $_liobject.ApplianceConnection.Name).Name
					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
						
					if ($PSCmdlet.ShouldProcess($_liobject.name,"Update Logical Interconnect from Group '$_ligname'. WARNING: Depending on the Update, there might be a brief outage."))
					{    
						
						Try
						{

							"[{0}] Sending request"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$uri = $_liobject.uri + "/compliance"

							$task = Send-HPOVRequest $uri PUT -Hostname $_liobject.ApplianceConnection.Name

							[void]$_returntasks.Add($task)

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

					elseif ($PSBoundParameters['WhatIf'])
					{
						
						"[{0}] User included -WhatIf." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Try
						{
	
							Compare-LogicalInterconnect -InputObject $_liobject
	
						} 
	
						Catch
						{
	
							$PSCmdlet.ThrowTerminatingError($_)
	
						}
					
					}

					else
					{

						"[{0}] User cancelled." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					}

				}

			}

		}

		return $_returntasks

	}

}
