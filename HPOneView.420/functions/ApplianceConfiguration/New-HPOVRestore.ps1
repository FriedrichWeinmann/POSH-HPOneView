function New-HPOVRestore 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("File")]
		[string]$FileName,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
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

		$_ApplianceStatus = New-Object System.Collections.ArrayList

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose
			
			# Validate the path exists.  If not, create it.
			if (-not(Test-Path $FileName))
			{
				 
				"[{0}] Backup file specified does not exist." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.RestoreException BackupFileNotFound ObjectNotFound 'FileName' -Message "'$FileName' was not found. Please check the directory and/or name and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if ($PSCmdlet.ShouldProcess($_appliance.Name,'restore backup to appliance')) 
			{    
			
				# Send the request
				"[{0}] Please wait while the appliance backup is uploaded.  This can take a few minutes..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$resp = Upload-File -Uri $ApplianceRestoreRepoUri $FileName -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
				if ($resp.id)
				{

					"[{0}] Sending request to restore appliance" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_restoreObject = [PSCustomObject]@{

						type                 = "RESTORE"
						uriOfBackupToRestore = $resp.uri

					}

					Try
					{
					
						$_restoreStatus = Send-HPOVRequest -Uri $ApplianceRestoreUri -Method POST -Body $_restoreObject -Hostname $_appliance
					
						Write-warning "Appliance restore in progress.  All users are now logged off."
					
					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$sw = [System.Diagnostics.Stopwatch]::StartNew()

					While ($_restoreStatus.status -eq "IN_PROGRESS") 
					{

						$_statusMessage = "{0} {1}% [{2}min {3}sec]" -f $ApplianceUpdateProgressStepEnum[$_restoreStatus.progressStep],$_restoreStatus.percentComplete, $sw.Elapsed.Minutes, $sw.Elapsed.Seconds

						# Handle the call from -Verbose so Write-Progress does not get borked on display.
						if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
						{ 

							"[{0}] - $_statusMessage" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						}

						else 
						{ 

							Write-Progress -id 1 -activity "Restoring Appliance Backup $($_restoreStatus.id)" -status $_statusMessage -percentComplete $_restoreStatus.percentComplete
						
						}


						Try
						{
					
							$_restoreStatus = Send-HPOVRequest $_restoreStatus.uri -Hostname $_appliance
									
						}
					
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					} # Until ($restoreStatus.percentComplete -eq 100 -or $restoreStatus -ne "IN_PROGRESS")

					$sw.Stop()

					"[{0}] - Operation took $($sw.elapsed.minutes)min $($sw.elapsed.seconds)sec" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Write-Progress -id 1 -activity "Restoring Appliance Backup $($_restoreStatus.id)" -status $_statusMessage -Completed

					Write-warning "Appliance restore in has completed for $($_appliance.Name). Address Pool ranges will need to be re-enabled, and verify the managed or monitored resources do not need a refresh."

				}

				[void]$_ApplianceStatus.Add($_restoreStatus)

			}

		}
	
	}

	End 
	{

		Return $_ApplianceStatus
	
	}

}
