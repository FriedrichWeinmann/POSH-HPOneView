function Invoke-Upgrade  
{

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory)]
		[ValidateNotNullorEmpty()]
		[Object]$PendingUpdate,

		[Parameter (Mandatory)]
		[ValidateNotNullorEmpty()]
		[HPOneView.Appliance.Connection]$ApplianceConnection

	)

	Begin 
	{
	
		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		$_FinalStatus = $null

	}

	Process 
	{

		Try
		{

			$uri = "{0}?file={1}" -f $ApplianceUpdatePendingUri, $PendingUpdate.fileName
			$_updateTask = Send-HPOVRequest -Uri $uri -Method PUT -Hostname $ApplianceConnection

		}
		
		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$sw = [System.Diagnostics.Stopwatch]::StartNew()

		$_PreviousTaskStep = $null

		# Loop to display progress-bar
		Do 
		{

			# Connect to update monitor web Process
			Try
			{

				$_MonitorUpdate = Send-HPOVRequest -Uri $ApplianceUpdateMonitorUri -Hostname $ApplianceConnection

				if ($_MonitorUpdate.taskStep)
				{

					$_PreviousTaskStep = $_MonitorUpdate.taskStep.Replace(" ", $null)

				}

				else
				{

					$_PreviousTaskStep = $_MonitorUpdate.status.Replace(" ", $null)

				}				

			}
		
			Catch
			{

				# Sleep 30 seconds to see make sure it wasn't a brief Apache issue
				"[{0}] Pausing 30 seconds after '{1}' exception was caught." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_.Exception.Message | Write-Verbose
				Start-Sleep -Seconds 30

				# Attempt a second connection, as appliance may have restarted Apache
				Try
				{

					"[{0}] Trying 2nd time to get update monitor status." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_MonitorUpdate = Send-HPOVRequest -Uri $ApplianceUpdateMonitorUri -Hostname $ApplianceConnection

					if ($_MonitorUpdate.taskStep)
					{

						$_PreviousTaskStep = $_MonitorUpdate.taskStep.Replace(" ", $null)

					}

					else
					{

						$_PreviousTaskStep = $_MonitorUpdate.status.Replace(" ", $null)

					}

				}
			
				Catch
				{
					$PSCmdlet.ThrowTerminatingError($_)

				}						

			}
						
			# Remove % from value in order to get INT
			if ($_MonitorUpdate.percentageCompletion) 
			{ 
				
				$PercentComplete = $_MonitorUpdate.percentageCompletion.Replace("%",$null).Replace(" ",$null)
			
			}
			
			else 
			{ 
				
				$PercentComplete = 0 
			
			}
						
			# Remove " State = " to get proper status
			if ($_MonitorUpdate.status) 
			{ 
				
				$UpdateStatus = $_MonitorUpdate.status.Replace(" ", $null).Replace("State=", $null)

				if ($_MonitorUpdate.phase)
				{
					
					$UpdateStatus = '{0} - {1}' -f $UpdateStatus, $_MonitorUpdate.phase

				}
			
			}

			else 
			{ 
				
				$UpdateStatus = "Starting" 
			
			}

			$Status = "{0} {1}% [{2}min {3}sec]" -f $UpdateStatus, $PercentComplete, $sw.elapsed.minutes, $sw.elapsed.seconds		    
			
			# Handle the call from -Verbose so Write-Progress does not get borked on display.
			if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
			{ 
				
				"[{0}] Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Update Status: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Status | Write-Verbose
			
			}
						  
			else 
			{ 
				
				Write-Progress -id 1 -Activity ("Installing appliance update {0}" -f $PendingUpdate.fileName) -Status $Status -PercentComplete $PercentComplete 
			
			}

			if ($UpdateStatus -match "UpdateReboot") 
			{

				# Handle the call from -Verbose so Write-Progress does not get borked on display.
				if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
				{ 

					"[{0}] pausing for 5 minutes while appliance reboots. Invoking Start-Sleep" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					Start-Sleep -Seconds 300

				}

				else 
				{ 
					
					$time = 300

					foreach ($i in (1..$time)) 
					{

						$percentage = $i / $time
						
						Write-Progress -id 1 -activity ("Installing appliance update {0}" -f $PendingUpdate.fileName) -Status $Status -PercentComplete $PercentComplete

						Write-Progress -id 2 -parent 1 -activity "Appliance Rebooting" -status "Pausing for 5 minutes" -percentComplete ($percentage * 100) -SecondsRemaining ($time - $i)

						Start-Sleep 1

					}
						
					Write-Progress -id 2 -parent 1 -activity "Appliance Rebooting" -status "Pausing for 5 minutes" -Completed			
					
				}

			}

		} Until ([int]$percentComplete -eq 100 -or $_PreviousTaskStep -match 'FAILED')
				
		$sw.Stop()

		"[{0}] Upgrade operation took {1}min, {2}sec." -f $MyInvocation.InvocationName.ToString().ToUpper(), $sw.elapsed.minutes, $sw.elapsed.seconds | Write-Verbose

		# Retrieve final update status
		Try
		{

			$_FinalStatus = Send-HPOVRequest -Uri $ApplianceUpdateNotificationUri -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		Write-Progress -Activity ("Installing appliance update {0}" -f $PendingUpdate.fileName) -status $updateStatus -percentComplete $percentComplete

		Write-Progress -Activity ("Installing appliance update {0}" -f $PendingUpdate.fileName) -status $updateStatus -Completed

	}

	End 
	{

		Return $_FinalStatus

	}

}
