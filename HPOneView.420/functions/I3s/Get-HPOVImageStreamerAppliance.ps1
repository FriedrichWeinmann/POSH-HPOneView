function Get-HPOVImageStreamerAppliance
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

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

		$_ImageStreamerCollection = New-Object System.Collections.ArrayList

	}

	Process
	{

		$_uri = $AvailableDeploymentServersUri

		if ($Name)
		{

			$_uri = "{0}?filter=name matches '{1}'" -f $_uri, $Name.Replace('*','%25').Replace('?','%26')

		}

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of $($ApplianceConnection.Count))" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			If ($_appliance.ApplianceType -ne 'Composer')
			{

				$ExceptionMessage = 'The ApplianceConnection {0} ({1}) is not a Synergy Composer.  This Cmdlet only support Synergy Composer management appliances.' -f $_appliance.Name, $_appliance.ApplianceType
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

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

					$ExceptionMessage = 'Image Streamer Appliance "{0}" was not found on "{1}" appliance connection.' -f $Name, $_appliance.Name
					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ImageStreamerResourceException ResourceNotFound ObjectNotFound "Name" -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)

				}

				else
				{

					$_CollectionResults.members | ForEach-Object {

						$_.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.ImageStreamerAppliance')
					
						$_

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
