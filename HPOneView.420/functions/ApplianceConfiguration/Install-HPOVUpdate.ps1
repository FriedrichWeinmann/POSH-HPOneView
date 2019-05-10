function Install-HPOVUpdate 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Update', SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Update')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Stage')]
		[Alias ('f')]
		[ValidateScript({Test-Path $_})]
		[string]$File,
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Update')]
		[Parameter (Mandatory = $false, ParameterSetName = 'StageInstall')]
		[string]$Eula,

		[Parameter (Mandatory = $false, ParameterSetName = 'Update')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Stage')]
		[Parameter (Mandatory = $false, ParameterSetName = 'List')]
		[switch]$DisplayReleaseNotes,

		[Parameter (Mandatory, ParameterSetName = 'Stage')]
		[switch]$Stage,

		[Parameter (Mandatory, ParameterSetName = 'StageInstall')]
		[switch]$InstallNow,
		
		[Parameter (Mandatory, ParameterSetName = 'List')]
		[Alias ('list')]
		[switch]$ListPending,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Update")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Stage")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "List")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "StageInstall")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $File)
		{

			$Pipeline = $true

		}

		else
		{

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

		$_StatusCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			# Check to see if ane existing update is present.  Report to user if it is, and tell them to use -InstallNow
			Try
			{
				
				"[{0}] - Checking if Pending update exists" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_PendingUpdate = Send-HPOVRequest -Uri $ApplianceUpdatePendingUri -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
			if ($_PendingUpdate)
			{

				"[{0}] - Update found '{1}', '{2}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_PendingUpdate.fileName, $_PendingUpdate.version | Write-Verbose

				$_PendingUpdate.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.Update.Pending')

			}

			Switch ($PSCmdlet.ParameterSetName) 
			{
				
				# List staged update
				"List" 
				{

					# If the request is to install a staged update, we need to handle no response.  If request is Update, then no Pending update will exist yet.
					If (-not($_PendingUpdate)) 
					{

						"[{0}] - No Pending update found. Return is Null" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$ErrorRecord = New-ErrorRecord InvalidOperationException PendingUpdateNotFound ObjectNotFound 'Install-HPOVUpdate' -Message "No Pending update found. Please first upload update and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					$_PendingUpdate
					
					If ($PSBoundParameters['DisplayReleaseNotes'])
					{
						
						"[{0}] - Displaying Release Notes" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						# Display Release Notes
						Try
						{

							$uri = "/rest/appliance/firmware/document-content/{0}/release" -f $Upload.fileName
							Send-HPOVRequest -Uri $uri -Hostname $_appliance | ConvertFrom-HTML

						}
							
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						"[{0}] - Done. Displayed update release notes." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					}
					
					Return
				}

				# Stage Update
				"Stage" 
				{              

					if (-not($_PendingUpdate)) 
					{

						"[{0}] - Stage Only" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						"[{0}] - UPLOAD FILE: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $File | Write-Verbose

						Try 
						{
					
							# Upload update
							$FileName = Get-Item $File

							$_upload = Upload-File -Uri $ApplianceUpdateImageUri -File $File -ApplianceConnection $_appliance.Name
					
						}

						Catch 
						{
						
							$ErrorRecord = New-ErrorRecord InvalidOperationException StageUpdateFailed InvalidResult 'Install-HPOVUpdate' -Message $_.Exception.Message
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						If ($PSBoundParameters['DisplayReleaseNotes'])
						{
						
							"[{0}] - Displaying Release Notes" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							# Display Release Notes
							Try
							{

								$uri = "/rest/appliance/firmware/document-content/{0}/release" -f $Upload.fileName
								Send-HPOVRequest -Uri $uri -Hostname $_appliance | ConvertFrom-HTML

							}
							
							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

							"[{0}] - Done. Displayed update release notes." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						}

						Return $_upload

					}

					else 
					{
					
						$ExceptionMessage = "An existing appliance update has been staged. Version: '{0}' Filename: '{1}'  Please use the -InstallUpdate Parameter to proceed with the update, or use Remove-HPOVPendingUpdate cmdlet to remove the staged update." -f $_PendingUpdate.version, $_PendingUpdate.fileName
						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.FirmwareUpdateException PendingUpdateConflict ResourceExists 'File' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				# Upload update then install update below.
				"Update" 
				{

					if ($_PendingUpdate) 
					{

						$ExceptionMessage = "A Pending update was found.  File name: '{0}'; Update Version: '{1}'. Please remove the update before continuing and try again." -f $_PendingUpdate.version, $_PendingUpdate.fileName
						$ErrorRecord = New-ErrorRecord InvalidOperationException PendingUpdateFound ResourceExists 'File' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
					}
									
					"[{0}] - UPLOAD FILE: '{1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $File | Write-Verbose

					Try 
					{
					
						# Upload update
						$FileName = Get-Item $File

						$_PendingUpdate = Upload-File -Uri $ApplianceUpdateImageUri -File $File -ApplianceConnection $_appliance.Name

						# Pause for 30 seconds? need to make sure appliance has finished Processing update file before invoking update
						"[{0}] - Sleeping for 5 seconds." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Start-Sleep -Seconds 5
				
					}

					Catch 
					{

						$ErrorRecord = New-ErrorRecord InvalidOperationException UploadUpdateFailed InvalidResult 'File' -Message $_.Exception.Message
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

			}

			# Process Pending update
			if (($PSCmdlet.ParameterSetName -eq "StageInstall") -or ($PSCmdlet.ParameterSetName -eq "Update" )) 
			{

				# If the request is to install a staged update, we need to handle no response.  If request is Update, then no Pending update will exist yet.
				If ((-not($_PendingUpdate)) -and ($PSCmdlet.ParameterSetName -eq "StageInstall")) 
				{

					"[{0}] - No Pending update found. Return is Null" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					$ErrorRecord = New-ErrorRecord InvalidOperationException StorageSystemResourceNotFound ObjectNotFound 'Install-HPOVUpdate' -Message "No Pending update found. Please first upload update and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}


				"[{0}] - Install Now" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_PendingUpdate

				If ($Eula -ne "accept") 
				{

					"[{0}] - EULA NOT Accepted" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					$Url = "https://{0}/ui-js/pages/upgrade/eula_content.html" -f $_appliance.Name

					try
					{

						# Display eula of update

						$_WebClient = (New-Object HPOneView.Utilities.Net).RestClient($Url, 'GET', 600)

						[System.Net.WebResponse]$_response = $_WebClient.GetResponse()
						$_reader = New-Object IO.StreamReader($_response.GetResponseStream())
						$_reader.ReadToEnd() | ConvertFrom-HTML -NoClobber
						$_reader.close()

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					Do { $acceptEula = Read-Host "Accept EULA (Must type ACCEPT)" } Until ($acceptEula -eq "Accept")

				}
					
				"[{0}] - EULA Accepted" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] - Beginning update $($_PendingUpdate.fileName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] - Estimated Upgrade Time $($_PendingUpdate.estimatedUpgradeTime) minutes" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_resp = $Null

				# Check to see if the update requires an appliance reboot.
				if ($_PendingUpdate.rebootRequired) 
				{

					"[{0}] - Appliance reboot required $($_PendingUpdate.rebootRequired)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] - Prompting for confirmation" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] - Is confirmation overridden $([bool]$confirm)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Write-Warning "Reboot required for the update."

					# If it does require a reboot, then we need to prompt for confirmation. Overriden by -confirm:$false
					if ($PSCmdlet.ShouldProcess($_appliance.Name,"upgrade appliance using $($_PendingUpdate.fileName)")) 
					{

						"[{0}] - Appliance reboot required and user selected YES or passed -Confirm:`$false, executing Invoke-Upgrade" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Try
						{

							$_resp = Invoke-Upgrade $_PendingUpdate -ApplianceConnection $_appliance

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}
						
					}

					else 
					{

						if ($PSBoundParameters['whatif']) 
						{ 

							write-warning "-WhatIf was passed, would have initiated appliance update."

						}

						else 
						{

							# If here, user chose "No", End Processing
							"[{0}] - User selected NO." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose						

						}

					}

				}

				else
				{
					 
					"[{0}] - Appliance reboot NOT required, executing Invoke-Upgrade" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					Try
					{

						$_resp = Invoke-Upgrade $_PendingUpdate -ApplianceConnection $_appliance

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}					

				}

				if ($null -ne $_resp)
				{

					# Update PSLibraryVersion variable with new appliance version
					Try
					{

						$applVersionInfo = Send-HPOVRequest -Uri $ApplianceVersionUri -Hostname $_appliance
						$PSLibraryVersion."$($_appliance.Name)" = New-Object HPOneView.Appliance.NodeInfo ($applVersionInfo.softwareVersion, (Get-HPOVXApiVersion -ApplianceConnection $_appliance).currentVersion, $applVersionInfo.modelNumber)

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}				

				$_resp

			}

		}

	}

	End
	{

		"[{0}] - Finished" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
