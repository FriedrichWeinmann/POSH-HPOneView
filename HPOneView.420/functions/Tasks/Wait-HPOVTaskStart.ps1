function Wait-HPOVTaskStart 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[Alias ('taskuri', 'task')]
		[object]$InputObject,

		[Parameter (Mandatory = $false)]
		[string]$resourceName,

		[Parameter (Mandatory = $false)]
		[timespan]$Timeout = $DefaultTimeout,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	) 

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $PSBoundParameters['InputObject']) 
		{ 
			
			$PipelineInput = $True 
		
		}

		else
		{

			if ($InputObject -is [String] -and $ApplianceConnection.Count -gt 1)
			{
			
				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Task' -Message "The -Task Parameter requires an Appliance to be specified.  Please provide the Appliance Connection object or name by using the -ApplianceConnection Parameter."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			else
			{


				"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				if (-not($ApplianceConnection) -and -not(${Global:ConnectedSessions}))
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

		}

	}

	Process 
	{

		if ($PipelineInput) 
		{ 
			
			"[{0}] Task resource passed via pipeline input." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		}

		# Validate the task object
		if (($InputObject -is [String]) -and ($InputObject.StartsWith($TasksUri))) 
		{
			
			"[{0}] Task is System.String $($InputObject)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_uri = $InputObject
		
		}

		elseif (($InputObject -is [PSCustomObject] -or $InputObject -is [HPOneView.Appliance.TaskResource]) -and ($InputObject.category -ieq 'tasks')) 
		{
		
			"[{0}] Task is $($InputObject.GetType()). Task URI: $($taInputObjectsk.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$ApplianceConnection = $InputObject.ApplianceConnection

			$_uri = $InputObject.uri
		
		}

		else 
		{

			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -Message "Invalid task.  Please verify the task object you are passing and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$sw = [diagnostics.stopwatch]::StartNew()

		Try
		{

			$taskObj = Send-HPOVRequest -uri $_uri -HostName $ApplianceConnection.name

		}
		
		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}
		
		$i = 0

		if ($resourceName) 
		{ 
			
			$taskname = "Waiting for '{0} {1}' task to start" -f $taskObj.name, $resourceName
		
		}

		else 
		{ 
			
			$taskName = "Waiting for '{0}' task to start" -f $taskObj.name
		
		}

		"[{0}] $taskName" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
		{ 
			
			"[{0}] Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		while ($taskObj.taskState -ieq "Adding" -or
			   $taskObj.taskState -ieq "New" -or
			   $taskObj.taskState -ieq "Starting") 
		{

			Try
			{

				$taskObj = Send-HPOVRequest -Uri $taskObj.uri -Hostname $taskObj.ApplianceConnection.Name

			}

			Catch
			{
			
				$PSCmdlet.ThrowTerminatingError($_)
			
			}
			
			if ($sw.Elapsed -gt $timeout) 
			{
				
				$ErrorRecord = New-ErrorRecord InvalidOperationException TaskWaitExceededTimeout OperationTimeout  'Wait-HPOVTaskStart' -Message "The time-out period expired before waiting for task '$taskName' to start." #-verbos
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			# Display Progress Bar

			# Display the task status
			if ($taskObject.taskStatus)
			{

				$progressStatus = $taskObject.taskStatus

			}
						
			elseif ($taskObject.taskState)
			{

				$progressStatus = $taskObject.taskState

			}

			else
			{

				$progressStatus = "Waiting $($taskObject.Name)"

			}

			if ($taskObj.expectedDuration) 
			{

				$percentComplete = ($i / $taskObj.expectedDuration * 100)

			}

			else
			{

				$percentComplete = $taskObj.percentComplete 

			}
			
			# Handle the call from -Verbose so Write-Progress does not get borked on display.
			if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
			{ 
				
				"[{0}] Task Status: '$taskName' $progressStatus $($percentComplete)% Complete" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}
			 
			else 
			{

				Write-Progress -activity $taskName -status $progressStatus -percentComplete $percentComplete
				
			}

			Start-Sleep 1

			$i++

		}

		Write-Progress -activity $taskName -Completed

		$taskObj

	}

	End 
	{
	
		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
