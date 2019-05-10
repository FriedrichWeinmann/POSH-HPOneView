function Remove-HPOVPendingUpdate 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default', SupportsShouldProcess,ConfirmImpact = 'High')]
	Param 
	(
	
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
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

		$_ColStatus = New-Object System.Collections.ArrayList
	
	}

	Process 
	{ 

		ForEach ($_appliance in $ApplianceConnection)
		{
			
			$_resp = $null

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			# Check to see if ane existing update is present.  Report to user if it is, and tell them to use -InstallNow
			Try
			{
				
				"[{0}] - Checking if Pending update exists" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_PendingUpdate = Send-HPOVRequest -Uri $ApplianceUpdatePendingUri -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
			if ($_PendingUpdate)
			{

				"[{0}] - Update found $($_PendingUpdate.fileName), $($_PendingUpdate.version)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_PendingUpdate.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.Update.Pending')

				$_PendingUpdate

				$RemoveMessage = "remove Pending update, {0}" -f $_PendingUpdate.fileName

				if ($PSCmdlet.ShouldProcess($_appliance.Name, $RemoveMessage)) 
				{

					"[{0}] Removing Pending update from applinace." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{
						
						"[{0}] - Checking if Pending update exists" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_resp = Send-HPOVRequest -Uri $ApplianceUpdatePendingUri -Method DELETE -Hostname $_appliance

						[void]$_ColStatus.Add($_resp)

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				else 
				{

					"[{0}] No Pending update found" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

			}

		}

	}

	End 
	{ 
	
		Return $_ColStatus

	}

}
