function Get-HPOVDataCenter
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		$Name,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
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

		$_DCCol = New-Object System.Collections.ArrayList

	}

	Process
	{

		$uri = $DataCentersUri.Clone()

		if ($Name)
		{

			$method = 'EQ'

			if ($Name.Contains('*'))
			{

				$method = 'matches'

			}

			$uri = "{0}?filter=name {1} '{2}'" -f $uri, $method, $Name.Replace('*','%25').Replace('?','%26')

		}

		ForEach ($_appliance in $ApplianceConnection)
		{

			'[{0}] Processing "{1}" appliance connection.' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			try
			{

				$Resp = Send-HPOVRequest -Uri $uri -Hostname $_appliance

			}

			catch
			{
			
				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($Resp.count -eq 0 -and $Name)
			{

				$ExceptionMessage = 'The "{0}" datacenter was not found on {1}.  Please check the name and try again.' -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord HPOneView.ResourceNotFoundException ObjectNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				Try
				{

					$RemoteSupportConfigured = Send-HPOVRequest -Uri $RemoteSupportConfigUri -Hostname $_appliance.Name

				}

				catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($RemoteSupportConfigured.enableRemoteSupport)
				{

					'[{0}] Appliance has Remote Support enabled.  Collecting DataCenter location and contact information.' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

					ForEach ($member in $resp.members)
					{

						Try
						{

							$_DCRemoteSupportLocation = Send-HPOVRequest -uri $member.remoteSupportUri -Hostname $_appliance.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						$member | Add-Member -NotePropertyName RemoteSupportLocation -NotePropertyValue ([HPOneView.Facilities.RemoteSupportLocation]$_DCRemoteSupportLocation)

						$member.PSObject.TypeNames.Insert(0,'HPOneView.Facilities.DataCenter')

						[void]$_DCCol.Add($member)

					}

				}

				else
				{

					$resp.members | ForEach-Object {

						$_.PSObject.TypeNames.Insert(0,'HPOneView.DataCenter')

						[void]$_DCCol.Add($_)

					}

				}

			}

		}

	}

	End
	{

		Return $_DCCol

	}

}
