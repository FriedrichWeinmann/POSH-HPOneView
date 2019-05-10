function Get-HPOVXApiVersion 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Alias ('appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{ 

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Cmdlet does not require authentication." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Check to see if a connection to the appliance exists
		# If ($ApplianceConnection -isnot [HPOneView.Appliance.Connection] -and $ApplianceConnection -isnot [System.Collections.IEnumerable] -and $ApplianceConnection -is [String])
		if ($ApplianceConnection -is [String])
		{

			if ((${Global:ConnectedSessions}.Name -notcontains $ApplianceConnection) -and (-not(${Global:ConnectedSessions} | Where-Object Name -eq $ApplianceConnection).SessionID))
			{

				"[{0}] Appliance Session not found. Running FTS sequence?" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Creating temporary Session object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_ApplianceName = $ApplianceConnection

				[HPOneView.Appliance.Connection]$ApplianceConnection = New-TemporaryConnection $ApplianceConnection

				# $ApplianceConnection.Name = $_ApplianceName

				"[{0}] $($ApplianceConnection | Format-List * )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			}

			else
			{

				[HPOneView.Appliance.Connection]$ApplianceConnection = ${Global:ConnectedSessions} | Where-Object Name -eq $ApplianceConnection

			}

		}

		$_XAPICollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($ApplianceConnection -is [System.Collections.IEnumerable] -and $ApplianceConnection -isnot [System.String])
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				Try
				{

					$_XAPIVersion = Send-HPOVRequest -Uri $ApplianceXApiVersionUri -Hostname $_appliance

				}
			
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				finally
				{

					# Remove Temporary appliance connection
					if ((${Global:ConnectedSessions} | Where-Object Name -eq $_appliance.Name).SessionID -eq 'TemporaryConnection')
					{

						"[{0}] Removing temporary Session object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$ConnectedSessions.RemoveConnection($_appliance)

					}

				}

				$_XAPIVersion | ForEach-Object { $_.PSObject.TypeNames.insert(0,'HPOneView.Appliance.XAPIVersion') }

				[void]$_XAPICollection.Add($_XAPIVersion)
		
			}

		}		

		else
		{

			Try
			{

				$_XAPIVersion = Send-HPOVRequest -Uri $ApplianceXApiVersionUri -Hostname $ApplianceConnection

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			finally
			{

				# Remove Temporary appliance connection
				if ((${Global:ConnectedSessions} | Where-Object Name -eq $ApplianceConnection.Name).SessionID -eq 'TemporaryConnection')
				{

					"[{0}] Removing temporary Session object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$ConnectedSessions.RemoveConnection($ApplianceConnection)

				}

			}

			New-Object HPOneView.Appliance.XApiVersion( $_XAPIVersion.currentVersion, $_XAPIVersion.minimumVersion, $_XAPIVersion.ApplianceConnection)
		
		}

	}

	End 
	{ 
	
		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
	}

}
