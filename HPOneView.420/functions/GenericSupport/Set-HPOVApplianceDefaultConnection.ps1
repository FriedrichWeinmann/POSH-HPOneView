function Set-HPOVApplianceDefaultConnection
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance', 'Connection')]
		[Object]$ApplianceConnection

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		# Check to see if there is only a single connection in the global tracker
		If (${Global:ConnectedSessions}.Count -eq 1)
		{

			Write-Warning 'There is only a single Appliance Connection.  This Cmdlet only supports multiple Appliance Connections.'

			if (-not($Global:ConnectedSessions[0].Default))
			{

				'Appliance Connection "{0}" was not found to be the default connection.  Setting as default.' -f ${Global:ConnectedSessions}[0].Name | Write-Warning 

				$Global:ConnectedSessions[0].SetDefault($True)

			}
			
			Break

		}

		if ($ApplianceConnection -is [System.String])
		{

			"[{0}] Connection Name provided.  Looking in Global connection tracker variable." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$ApplianceConnection = ${Global:ConnectedSessions} | Where-Object Name -eq $ApplianceConnection

			}

			Catch [System.Management.Automation.ValidationMetadataException]
			{

				"[{0}] Connection was not found.  Looking for matching name in Global connection tracker variable." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$ApplianceConnection = ${Global:ConnectedSessions} | Where-Object Name -Match $ApplianceConnection

				}
				
				Catch
				{

					$_Message = "Unable to find an appliance connection with the provided ApplianceConnection Name, {0}.  Please provide the Connection Object or validate the Name and try again." -f $ApplianceConnection
					$ErrorRecord = New-ErrorRecord InvalidOperationException ApplianceConnectionNotFound ObjectNotFound 'ApplianceConnection' -Message $_Message
					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
		}

	}

	Process
	{

		if ($ApplianceConnection -isnot [HPOneView.Appliance.Connection])
		{

			$ExceptionMessage = "An invalid connection argument value type was provided, {0}.  Please provide either a [String] or [HPOneView.Appliance.Connection] object." -f $ApplianceConnection
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidConnectionParameterValue InvalidArgument 'ApplianceConnection' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Check for existing Default Connection
		if (${Global:ConnectedSessions} | Where-Object Default)
		{

			# Unset it
			(${Global:ConnectedSessions} | Where-Object Default).SetDefault($false)

		}

		"[{0}] Setting {1} as the new default Appliance Connection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $ApplianceConnection.Name | Write-Verbose

		(${Global:ConnectedSessions} | Where-Object Name -eq $ApplianceConnection.Name).SetDefault($true)

	}

	End
	{

		Return ${Global:ConnectedSessions}

	}

}
