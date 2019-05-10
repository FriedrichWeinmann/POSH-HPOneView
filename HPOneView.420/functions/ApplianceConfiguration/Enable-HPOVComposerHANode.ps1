function Enable-HPOVComposerHANode
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory = $False)]
		[switch]$Async,

		[Parameter (Mandatory = $False)]
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

		$_ComposerNodeTaskCollection = New-Object System.Collections.ArrayList
		
	}

	Process
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing Appliance Connection {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			if ($_appliance.ApplianceType -ne 'Composer')
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message ('The ApplianceConnection {0} is not a Synergy Composer.  This Cmdlet is only supported with Synergy Composers.' -f $_appliance.Name)
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				Try
				{

					$_ComposerNodes = Send-HPOVRequest -Uri $ApplianceHANodesUri -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				$_StandbyComposer = $_ComposerNodes.members | Where-Object role -eq 'Standby'

				if ($_StandbyComposer)
				{

					if ($PSCmdlet.ShouldProcess($_StandbyComposer.name,"transition from Standby to Active"))
					{

						$_operation       = NewObject -PatchOperation
						$_operation.op    = 'replace'
						$_operation.path  = '/role'
						$_operation.value = 'Standby'

						Try
						{

							$_resp = Send-HPOVRequest $_StandbyComposer.uri PATCH $_operation -Hostname $_appliance -AddHeader @{'If-Match' = $_StandbyComposer.eTag}

						}
						
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						if (-not($PSBoundParameters['Async']))
						{

							Try
							{

								$_resp = Wait-HPOVTaskComplete $_resp

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}							

						}

						[void]$_ComposerNodeTaskCollection.Add($_resp)

					}

					elseif ($PSBoundParameters['Whatif'])
					{

						"[{0}] -Whatif scenario." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					}

					else
					{

						"[{0}] User cancelled operation." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					}

				}

				else
				{

					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException NoStandbyComposerFound ObjectNotFound 'Composer' -Message ('No standby Composers were found in {0} ApplianceConnection.' -f $_connection.Name)
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}				

			}

		}
		
	}

	End
	{

		Return $_ComposerNodeTaskCollection

	}

}
