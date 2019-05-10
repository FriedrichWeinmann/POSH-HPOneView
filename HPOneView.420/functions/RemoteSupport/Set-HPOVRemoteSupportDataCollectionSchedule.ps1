function Set-HPOVRemoteSupportDataCollectionSchedule
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateSet ('AHS','Basic')]
		[String]$Type,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[DateTime]$DateTime,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Switch]$Async,

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

		$_SchedulesToUpdate = New-Object System.Collections.ArrayList

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

					$_schedule = $_Schedules.members | Where-Object serviceName -eq 'Active_Health_Service_Collection'

					"[{0}] Processing schedule: {1}({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_schedule.scheduleName, $_schedule.serviceName | Write-Verbose
					$_schedule.hourOfDay = [int]$DateTime.Hour
					$_schedule.minute    = $DateTime.Minute	
					$_schedule.dayOfWeek = [int]$DateTime.DayOfWeek + 1 # Needs to be a value of 1 through 7. Windows defaults to 0 - 6.

					$_PatchOperation = NewObject -PatchOperation

					$_PatchOperation.op    = 'replace'
					$_PatchOperation.path  = '/schedules/{0}' -f $_schedule.taskKey
					$_PatchOperation.value = $_schedule

					[void]$_SchedulesToUpdate.Add($_PatchOperation)		
					
				}

				'Basic'
				{

					$_schedule = $_Schedules.members | Where-Object serviceName -eq 'Server_Basic_Configuration_Collection'

					"[{0}] Processing schedule: {1}({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_schedule.scheduleName, $_schedule.serviceName | Write-Verbose
					$_schedule.hourOfDay = [int]$DateTime.Hour
					$_schedule.minute    = $DateTime.Minute	
					$_schedule.dayOfMonth = [int]$DateTime.Day

					$_PatchOperation = NewObject -PatchOperation

					$_PatchOperation.op    = 'replace'
					$_PatchOperation.path  = '/schedules/{0}' -f $_schedule.taskKey
					$_PatchOperation.value = $_schedule

					[void]$_SchedulesToUpdate.Add($_PatchOperation)		

				}
				
			}

			Try
			{

				$_resp = Send-HPOVRequest -Uri $RemoteSupportUri -Method PATCH -Body $_SchedulesToUpdate -Hostname $_Appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($PSBoundParameters['Async'])
			{

				$_resp

			}

			else
			{

				$_resp | Wait-HPOVTaskComplete

			}

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
