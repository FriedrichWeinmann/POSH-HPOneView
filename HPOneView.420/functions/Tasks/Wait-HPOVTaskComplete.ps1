function Wait-HPOVTaskComplete 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param
	(

		[Parameter (ValueFromPipeline, Mandatory)]
		[Alias ('TaskUri','Task')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false)]
		[timespan]$Timeout = $DefaultTimeout,

		[Parameter (Mandatory = $false)]
		[Switch]$ApplianceWillReboot,

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
		
		# Task isn't provided by pipeline, but check for ApplianceConnection property
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

		$TaskCollection          = New-Object System.Collections.ArrayList
		$FinishedTasksCollection = New-Object System.Collections.ArrayList
		$_TaskIds                = New-Object System.Collections.ArrayList

		$i = 1

	}

	Process 
	{

		if ($PipelineInput) 
		{ 
			
			"[{0}] Task resource passed via pipeline input." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		}

		# Validate the task object 
		ForEach ($_task in $InputObject)
		{

			"[{0}] Processing task resources." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if (($_task -is [String]) -and ($_task.StartsWith($TasksUri))) 
			{

				"[{0}] Task is URI $($_task)"-f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Use to track -ID in Write-Progress
				$_task = [PSCustomObject]@{
					id                  = $i; 
					uri                 = $_task; 
					taskState           = $Null; 
					ApplianceConnection = $ApplianceConnection 
				}

			}

			elseif ($_task -is [PSCustomObject] -and $_task.category -ieq 'tasks')
			{

				"[{0}] Task is $($_task.GetType()). Task URI: $($_task.uri)"-f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				# Use to track -ID in Write-Progress
				$_task | Add-Member -NotePropertyName id -NotePropertyValue $i -force
				
			}

			else 
			{

				$ExceptionMessage = "Invalid task object provided.  Please verify the task object you are passing and try again."
				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument $_task -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			[void]$TaskCollection.Add($_task)
			[void]$_TaskIds.Add($i)

			$i++
			
		}

	}

	End
	{

		$_taskCollection = $TaskCollection.Clone()		

		# Start Stopwatch
		$sw = [diagnostics.stopwatch]::StartNew()

		while ($_taskCollection.Count -gt 0 -and $sw.Elapsed -lt $timeout)
		{

			"[{0}] Processing taskcollection." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($sw.Elapsed -gt $timeout) 
			{

				# Tear down Write-Progress
				$_taskCollection | ForEach-Object { Write-Progress -id $_.id -Activity $_.Activity -Completed }

				# Return 'finished' collection to caller then display error
				if ($_taskCollection.Count -gt 0)
				{

					$_taskCollection

				}
				
				if ($FinishedTasksCollection.Count -gt 0)
				{

					$FinishedTasksCollection

				}

				# UPDATE ERROR MESSAGE to state timeout waiting for tasks to complete
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.TaskResourceException TaskWaitExceededTimeout OperationTimeout  'Wait-HPOVTaskComplete' -Message "The time-out period expired before waiting for task '$taskName' to start." #-verbos
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			$_t = 1

			ForEach ($_task in $_taskCollection)
			{

				# Get task object from API
				Try
				{

					"[{0}] Getting task object from API." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_taskObj = Send-HPOVRequest $_task.uri -Hostname $_task.ApplianceConnection.Name

				}

				Catch
				{

					if ($ApplianceWillReboot.IsPresent -and $_taskObj.progressUpdates.statusUpdate -match 'Rebooting')
					{

						Write-Host "`r`n"
						Write-Warning "Appliance is rebooting..."

						# Sleep for 30 seconds so the web service isn't available, and should trigger Wait-HPOVApplianceStart
						Start-Sleep -Seconds 30 

					}

					else
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}					

				}

				$Activity = '{0} {1}' -f $_taskObj.name, $_taskObj.associatedResource.resourceName
			
				# Task is in a finished state
				if ($TaskFinishedStatesEnum -contains $_taskObj.taskState)
				{

					"[{0}] Task is finished, removing from collection." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					  
					"[{0}] Task Collection size: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $TaskCollection.count | Write-Verbose

					# Remove task object from base arraylist
					[void]$TaskCollection.Remove($_task)

					"[{0}] Updated Task Collection size: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $TaskCollection.count | Write-Verbose

					# Add Task Object from API to return back to caller
					[void]$FinishedTasksCollection.Add($_taskObj)

					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{
						
						"[{0}] {1} [{2}{3}] Task finished. " -f $MyInvocation.InvocationName.ToString().ToUpper(), $_taskObj.name, $_taskObj.ApplianceConnection.Name, $_taskObj.uri | Write-Verbose
					
					}

					else 
					{
					
						Write-Progress -id $_task.id -activity $Activity -Completed
					
					}

				}

				# Display Progress Bar
				else
				{

					# Check for running associated tasks for -CurrentOperation status messages
					Try
					{

						$AssociatedChildTasksInexUri = "{0}?sort=created:desc&start=0&category=tasks&query=parentTaskUri:'{1}' AND state:'Running'" -f $IndexUri, $_taskObj.uri

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$CurrentOperation = $null

					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{ 
						
						"[{0}] Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						
						"[{0}] CMDLET Task Track ID: {1}`nTask Object Name: {2}`nAssociated Resource Name: {3}`nPrecent Complete: {4}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_task.id, $_taskObj.name,$_taskObj.associatedResource.resourceName,$_taskObj.percentComplete | Write-Verbose
					
						If ($_taskObj.progressUpdates[-1].statusUpdate)
						{

							"[{0}] Child tasks - Child task: {1} ParentId: {2} {3} ({4})" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_task.id + 100), $_task.id, $_taskObj.progressUpdates[-1].statusUpdate, $_taskObj.taskStatus | Write-Verbose

						}

						if ($CurrentOperation)
						{

							"[{0}] Current operation: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $CurrentOperation | Write-Verbose

						}

					}
					
					else 
					{

						# Display the task status, and associated child tasks
						if ($_taskObj.progressUpdates.count -gt 0) 
						{ 

							# StatusUpdate contains an embedded JSON object as a string.
							if ($_taskObj.progressUpdates[-1].statusUpdate -match '{')
							{

								$ChildTaskMessage = $_taskObj.progressUpdates[-1].statusUpdate.Substring($_taskObj.progressUpdates[-1].statusUpdate.IndexOf('{'), ($_taskObj.progressUpdates[-1].statusUpdate.IndexOf('}') - $_taskObj.progressUpdates[-1].statusUpdate.IndexOf('{') + 1)) | ConvertFrom-Json
								$StatusMessage  = '{0}{1}' -f $_taskObj.progressUpdates[-1].statusUpdate.Substring(0, $_taskObj.progressUpdates[-1].statusUpdate.IndexOf('{')), $ChildTaskMessage.name

							}

							else
							{

								$StatusMessage  = '{0}' -f $_taskObj.progressUpdates[-1].statusUpdate

							}	

							if ($null -eq $StatusMessage -or [System.String]::IsNullOrWhiteSpace($StatusMessage))
							{

								$StatusMessage = $_taskObj.taskState

							}	

							# Child task is executing, display reported status
							# Need to add child task object to trask tracker so to remove them when finished from Write-Progress nested view
							If ($_taskObj.progressUpdates[-1].statusUpdate) 
							{

								if ($_TaskIds -notcontains ($_task.id + 100))
								{

									[void]$_TaskIds.Add($_task.id + 100)

								}

								$ChildTaskStatus = '{0} {1}' -f $_taskObj.name, $_taskObj.associatedResource.resourceName

								Write-Progress -id ($_task.id + 100) -ParentId $_task.id -activity $ChildTaskStatus -status $StatusMessage -CurrentOperation $CurrentOperation -percentComplete $_taskObj.computedPercentComplete
							
							}

							# There is a child task, but it's statusUpdate value is NULL, so just display the parent task status
							else 
							{
							
								if ($_taskObj.taskStatus)
								{

									$progressStatus = $_taskObj.taskStatus

								}
								
								else
								{

									$progressStatus = $_taskObj.taskState

								}

								Write-Progress -Activity $Activity -Status $StatusMessage -CurrentOperation $CurrentOperation -percentComplete $_taskObj.percentComplete
							
							}

						}

						#Just display the task status, as it has no child tasks
						elseif ($_taskObj.taskStatus) 
						{
							
							Write-Progress -activity $Activity -status $_taskObj.taskStatus -CurrentOperation $CurrentOperation -percentComplete $_taskObj.percentComplete 
						
						}
						
						else 
						{
							
							Write-Progress -activity $Activity -status $_taskObj.taskState -CurrentOperation $CurrentOperation -percentComplete $_taskObj.percentComplete 
						
						}

					}
					
				}
				
				if ($_t -ge $_taskCollection.count)
				{

					Start-Sleep -seconds 2
					$_t = 1 # Reset counter

				}

				else
				{

					$_t++

				}

			}

			# Reclone $_taskCollection object to update array with current task ArrayList
			$_taskCollection = $TaskCollection.Clone()

		}

		# Tear down any remaining Write-Progress displays before returning back to the user
		$_TaskIds | ForEach-Object { Write-Progress -id $_ -Activity "Completed" -Completed }

		Return $FinishedTasksCollection

	}

}
