function Get-HPOVRemoteSupportDataCollectionSchedule
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = "default")]
	Param 
	(
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateSet ('AHS','Basic')]
		[String]$Type,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
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

	}

	Process 
	{

		ForEach($_Appliance in $ApplianceConnection)
		{

			# Get the default schedules on the appliance
			Try
			{

				$_Schedules = Send-HPOVRequest -Uri $RemoteSupportDataCollectionScheduleUri -Hostname $_Appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if (-not $PSBoundParameters['Type'])
			{

				$_Type = 'AHS','Basic'

			}

			else
			{

				$_Type = $Type

			}

			Switch ($_Type)
			{

				'AHS'
				{

					$_Schedules.members | Where-Object serviceName -eq 'Active_Health_Service_Collection' | ForEach-Object {

						New-Object HPOneView.Appliance.RemoteSupport.Schedule($_.scheduleName,
																				$_.repeatOption,
																				$_.hourOfDay,
																				$_.minute,
																				[DayOfWeek]$_.dayOfWeek,
																				$_.ApplianceConnection)

					}
					
				}

				'Basic'
				{

					$_Schedules.members | Where-Object serviceName -eq 'Server_Basic_Configuration_Collection' | ForEach-Object {

						New-Object HPOneView.Appliance.RemoteSupport.Schedule($_.scheduleName,
																			  $_.repeatOption,
																			  $_.hourOfDay,
																			  $_.minute,
																			  $_.dayOfMonth,
																			  $_.ApplianceConnection)

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
