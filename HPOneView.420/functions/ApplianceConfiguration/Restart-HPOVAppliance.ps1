function Restart-HPOVAppliance 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(
	
		[Parameter (ValueFromPipeline, Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['ApplianceConnection'])) 
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
		
		$TaskCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if (-not($ApplianceConnection))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing Appliance '$($_appliance.Name)' (of $($ApplianceConnection.Count))" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Appliance Restart being request." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Presenting confirmation prompt." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($PSCmdlet.ShouldProcess(("Restart appliance {0}" -f $_appliance.Name),"WARNING: Restarting the appliance will cause all users to be disconnected and all ongoing tasks to be interrupted.",('Perform operation "Restart appliance" on target "{0}"?' -f $_appliance.Name)))
			{

				"[{0}] User confirmed appliance shutdown." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose    
				
				Try
				{

			
					$_resp = Send-HPOVRequest -uri $script:applianceRebootUri -method POST -Hostname $_appliance

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}
			
			elseif ($PSBoundParameters['Whatif'])
			{

				"[{0}] User passed -WhatIf." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			else
			{

				"[{0}] User cancelled shutdown request." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}
		
		}
		
	}

	End
	{

		Return $TaskCollection

	}

}
