function Set-HPOVReservedVlanRange
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	param
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateRange(2, 4095)]
		[Int]$Start,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateRange(60, 128)]
		[int]$Length,

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

			For ([int]$c = 0; $c -gt $ApplianceConnection.Count; $c++)
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

		$_FabricManagerCol = New-Object System.Collections.ArrayList

	}

	Process
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			if ($_appliance.ApplianceType -ne 'Composer')
			{
	
				$ExceptionMessage = 'The ApplianceConnection {0} is an HPE OneView Virtual Machine Appliance, which does not support SAS Logical Interconnect Group resources.' -f $_appliance.Name
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)
	
			}	

			else
			{

				# Generate error that start and length is larger than allowed 4095
				if (($Start + $Length) -gt 4095)
				{

					$ExceptionMessage = 'The provided Length value {0} will exceed the allowed range value beyond 4095.  Specify a lower Start, or shorter Length value.' -f $Length
					$ErrorRecord = New-ErrorRecord HPOneView.Networking.ReservedVlanRangeException  InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_UpdatedVlanRange = NewObject -ReservedVlanRange

				$_UpdatedVlanRange.start = $Start
				$_UpdatedVlanRange.length = $Length

				# Get reserved vlan range URI from appliance
				try
				{

					$_applianceFabrics = Send-HPOVRequest -Uri $DomainFabrics -Hostname $_appliance

				}

				catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				ForEach ($_fabric in $_applianceFabrics.members)
				{

					$_uri = '{0}/reserved-vlan-range' -f $_fabric.uri
		
					Send-HPOVRequest -Uri $_uri -Method PUT -Body $_UpdatedVlanRange -Hostname $_appliance | Wait-HPOVTaskComplete		

				}

			}

		}

	}
	
	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
