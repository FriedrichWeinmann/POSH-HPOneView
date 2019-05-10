function Save-HPOVBackup
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("save")]
		[string]$Location = (get-location).Path,

		[Parameter (Mandatory, ParameterSetName = "SaveRemoteOnly")]
		[Switch]$SaveRemoteOnly,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SaveRemoteOnly")]
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

		# Validate the path exists.  If not, create it.
		if ($PSBoundParameters['Location'] -and -not(Test-Path $Location))
		{
			 
			"[{0}] Directory does not exist.  Creating directory..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			New-Item $Location -itemtype directory | Out-Null

		}

	}

	Process
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			# Check to see if Automatic Backup is set on the appliance.
			Try
			{

				$_AutomaticBackup = Send-HPOVRequest -Uri $ApplianceAutoBackupConfUri -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			"[{0}] Getting appliance created backup file" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_CurrentBackup = Send-HPOVRequest -Uri $ApplianceBackupUri -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($_CurrentBackup.Count -eq 0)
			{

				"[{0}] Appliance does not contain a backup file.  Generate non-terminating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ExceptionMessage = 'No backup files were found on "{0}" appliance.' -f $_appliance
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.ApplianceBackupException EmptyBackupFileList ObjectNotFound ApplianceConnection -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				ForEach ($_BackupToDownload in $_CurrentBackup.members)
				{

					if ($_AutomaticBackup.enabled -and $PSBoundParameters['SaveRemoteOnly'])
					{

						"[{0}] Appliance supports remtoe backups.  Saving backup file to remote location: {1}/{2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_AutomaticBackup.remoteServerName, $_AutomaticBackup.remoteServerDir | Write-Verbose

						Try
						{

							Send-HPOVRequest -Uri $_BackupToDownload.saveUri -Method PUT -Hostname $_BackupToDownload.ApplianceConnection | Wait-HPOVTaskComplete
							
						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}
					
					else
					{

						Try
						{
							
							$_Results = Download-File $_BackupToDownload.downloadUri $_appliance $Location

							[System.IO.FileInfo]$_Results.file

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

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
