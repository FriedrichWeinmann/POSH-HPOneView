function Get-HPOVOSDeploymentServer
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Label,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = ($ConnectedSessions | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection) -and -not($ConnectedSessions))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command agian."
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

	Process
	{

		$_uri = $DeploymentServersUri

		if ($Name)
		{

			if ($Name.Contains('*'))
			{

				$Name = $Name.Replace("*","%25").Replace("&","%26")

			}

			$_uri = '{0}?filter=name matches "{1}"' -f $_uri, $Name

		}

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			If ($_appliance.ApplianceType -ne 'Composer')
			{

				$ExceptionMessage = 'The ApplianceConnection {0} ({1}) is not a Synergy Composer.  This Cmdlet only support Synergy Composer management appliances.' -f $_appliance.Name, $_appliance.ApplianceType
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				if ($PSBoundParameters['Label'])
				{

					$_uri = '{0}?category:deployment-servers&query=labels:{1}' -f $IndexUri, $Label

					Try
					{

						"[{0}] Getting OS Deployment Servers from Index for Label lookup" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_IndexMembers = Send-HPOVRequest -Uri $_uri -Hostname $_appliance

						# Loop through all found members and get full SVT object
						ForEach ($_member in $_IndexMembers.members)
						{

							Try
							{

								$_member = Send-HPOVRequest -Uri $_member.uri -Hostname $_appliance

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}						

							$_member.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.OSDeploymentServer')

							$_member

						}

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				else
				{

					"[{0}] Getting OS Deployment servers from primary URI" -f $MyInvocation.InvocationName.ToString().ToUpper()| Write-Verbose

					Try
					{

						$_CollectionResults = Send-HPOVRequest -uri $_uri -Hostname $_appliance.Name			

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					if ($Name -and -not $_CollectionResults.members)
					{

						$ExceptionMessage = 'OS Deployment Server "{0}" was not found on "{1}" appliance connection.' -f $Name, $_appliance.Name
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ImageStreamerResourceException ResourceNotFound ObjectNotFound "Name" -Message $ExceptionMessage
						$PSCmdlet.WriteError($ErrorRecord)

					}

					else
					{

						ForEach ($_DeploymentServer in $_CollectionResults.members)
						{
							
							$_DeploymentServer.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.OSDeploymentServer')

							$_DeploymentServer

						}

					}

				}

			}

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
