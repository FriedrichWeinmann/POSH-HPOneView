function New-HPOVBackup 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("save")]
		[string]$Location = (get-location).Path,
		
		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[switch]$Force,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[switch]$Async,
			
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

		# Validate the path exists.  If not, create it.
		if ($PSBoundParameters['Location'] -and -not(Test-Path $Location))
		{
			 
			"[{0}] Directory does not exist.  Creating directory..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			New-Item $Location -itemtype directory

		}

		$_BackupFileStatusCollection = New-Object System.Collections.ArrayList

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

			"[{0}] Please wait while the appliance backup is generated.  This can take a few minutes..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{
				
				$_taskStatus = Send-HPOVRequest -Uri $ApplianceBackupUri -Method POST -Hostname $_appliance | Wait-HPOVTaskComplete -timeout (New-Timespan -minutes 45)

				"[{0}] Response: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $($_taskStatus | out-string) | Write-Verbose

				$_backupObject = Send-HPOVRequest -Uri $_taskStatus.associatedResource.resourceUri -Hostname $_appliance
				
			}   

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# If no automatic backup is configured, then download
			if (-not($_AutomaticBackup.enabled) -or $PSBoundParameters['Force'])
			{

				"[{0}] Backup File URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_backupObject.downloadUri | Write-Verbose

				"[{0}] Downloading to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Location | Write-Verbose

				Try
				{

					$_resp = Download-File $_backupObject.downloadUri $_appliance $Location

					[void]$_BackupFileStatusCollection.Add([System.IO.FileInfo]$_resp.file)

				}
			
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			else
			{

				"[{0}] Created backup will be saved to remote location: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_AutomaticBackup.remoteServerName | Write-Verbose

				Try
				{

					$_resp = Send-HPOVRequest -Uri $_backupObject.saveUri -Method PUT -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if (-not($PSboundParameters['Async']))
				{

					"[{0}] Monitoring remote save operation." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_resp = Wait-HPOVTaskComplete $_resp

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				[void]$_BackupFileStatusCollection.Add($_resp)

			}

		}
		
	}

	End
	{

		Return $_BackupFileStatusCollection

	}

}
