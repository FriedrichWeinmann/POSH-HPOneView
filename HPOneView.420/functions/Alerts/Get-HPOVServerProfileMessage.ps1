Function Get-HPOVServerProfileMessage
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param
	(

		[Parameter (Mandatory = $False, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$ServerProfile,
		
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($PSCmdlet.ParameterSetName -eq 'ResourcePipeline') 
		{ 
			
			$Pipelineinput = $True 
		
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
		
		$_AlertResources = New-Object System.Collections.ArrayList

	}
	
	Process 
	{

		# Input object is a Server Profile resource, get special alerts URI
		if ($ServerProfile.category -eq $ResourceCategoryEnum.ServerProfile) 
		{
		
			"[{0}] Input object is a Server Profile. Getting special URI for alert messages." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			Try
			{

				[Array]$_serverAlerts = Send-HPOVRequest ($InputObject.uri + "/messages") -Hostname $InputObject.ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
				
			"[{0}] Processing {1} Server Profile messages." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_serverAlerts.Count | Write-Verbose

			foreach ($_alert in $_serverAlerts) 
			{

				switch ($_alert.PSObject.Properties.Name) 
				{

					"connections" 
					{ 
							
						if ($_alert.connections.count -gt 0) 
						{ 

							"[{0}] Processing {1} Server Profile 'Connections' messages." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_alert.connections.count | Write-Verbose
								
							$_alert.connections.messages | ForEach-Object { 
									
								$_.PSObject.TypeNames.Insert(0,"HPOneView.ServerProfileMessage")

								Add-Member -InputObject $_ -NotePropertyName ServerProfileName -NotePropertyValue $InputObject.name

								[void]$_AlertResources.Add($_)
								
							}

						} 
						
					}

					"serverHardware" 
					{ 
							
						if ($_alert.serverHardware.count -gt 0) 
						{

							"[{0}] Processing {1} Server Profile 'ServerHardware' messages." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_alert.serverHardware.count | Write-Verbose

							$_alert.serverHardware.messages | ForEach-Object { 
									
								$_.PSObject.TypeNames.Insert(0,"HPOneView.ServerProfileMessage")

								Add-Member -InputObject $_ -NotePropertyName ServerProfileName -NotePropertyValue $InputObject.name

								[void]$_AlertResources.Add($_)
								
							}
							
						} 
						
					}
						
					"firmwareStatus" 
					{ 
							
						if ($_alert.firmwareStatus.count -gt 0) 
						{ 

							"[{0}] Processing {1} Server Profile 'FirmwareStatus' messages." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_alert.firmwareStatus.count | Write-Verbose
								
							$_alert.firmwareStatus.messages | ForEach-Object { 
									
								$_.PSObject.TypeNames.Insert(0,"HPOneView.ServerProfileMessage")

								Add-Member -InputObject $_ -NotePropertyName ServerProfileName -NotePropertyValue $InputObject.name

								[void]$_AlertResources.Add($_)
								
							}
							
						} 
						
					}
				
				}

			}

		}

		else 
		{

			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidAlertObject InvalidArgument  "ServerProfile" -TargetType 'PSObject' -Message ("An invalid object was provided, {0}.  Only Server Profile objects are supported." -f $ServerProfile.category)
			$PSCmdlet.WriteError($ErrorRecord)

		}

	}

	End 
	{

		Return $_AlertResources

	}

}
