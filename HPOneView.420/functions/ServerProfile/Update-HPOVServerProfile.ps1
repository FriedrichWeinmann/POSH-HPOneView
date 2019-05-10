function Update-HPOVServerProfile
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Default')]
	Param 
	(
		
		[Parameter (ValueFromPipeline, Mandatory, ParameterSetName = 'Default')]
		[Parameter (ValueFromPipeline, Mandatory, ParameterSetName = 'Reapply')]
		[ValidateNotNullOrEmpty()]
		[Alias ('profile','ServerProfile')]
		[object]$InputObject,

		[Parameter (Mandatory, ParameterSetName = 'Reapply')]
		[Switch]$Reapply,

		[Parameter (Mandatory = $false, ParameterSetName = 'Reapply')]
		[Switch]$Baseline,

		[Parameter (Mandatory = $false, ParameterSetName = 'Reapply')]
		[Switch]$AdapterAndBoot,

		[Parameter (Mandatory = $false, ParameterSetName = 'Reapply')]
		[Switch]$Connections,

		[Parameter (Mandatory = $false, ParameterSetName = 'Reapply')]
		[Switch]$LocalStorage,

		[Parameter (Mandatory = $false, ParameterSetName = 'Reapply')]
		[Switch]$SANStorage,

		[Parameter (Mandatory = $false, ParameterSetName = 'Reapply')]
		[Switch]$BIOS,

		[Parameter (Mandatory = $false, ParameterSetName = 'Reapply')]
		[Switch]$OSDeployment,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = 'Reapply')]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Reapply')]
		[Switch]$Async

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject']))
		{

			$PipelineInput = $True

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

		$_TaskCollection          = New-Object System.Collections.ArrayList
		$_ServerProfileCollection = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		if ($PipelineInput) 
		{
		
			"[{0}] Processing Pipeline input." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		# Process server profile resource name
		if ($InputObject -is [String])
		{

			Try
			{

				$InputObject = Get-HPOVServerProfile -Name $InputObject -ApplianceConnection $ApplianceConnect -ErrorAction Stop

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		elseif ($InputObject.category -eq $ResourceCategoryEnum['ServerHardware'])
		{

			"[{0}] Server hardware resource provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($null -eq $InputObject.serverProfileUri)
			{

				$ExceptionMessage = 'The provided server hardware "{0}" does not have an assigned server profile.' -f $InputObject.name
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerHardwareNullServerProfileAssignment InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Try
			{

				$InputObject = Send-HPOVRequest -Uri ($InputObject.serverProfileUri) -Hostname $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		# Validate the Input object is the allowed category
		elseif ($InputObject.category -ne $ResourceCategoryEnum['ServerProfile'])
		{

			$ExceptionMessage = "The provided InputObject object ({0}) category '{1}' is not an allowed value.  Expected category value is '{2}'. Please correct your input value." -f $InputObject.name, $InputObject.category, $ResourceCategoryEnum.ServerProfile
			$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerProfilesCategory InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if (-not $InputObject.ApplianceConnection)
		{

			$ExceptionMessage = "The provided InputObject object ({0}) does not contain the required 'ApplianceConnection' object property. Please correct your input value." -f $InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerProfileObject InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		"[{0}] Processing Server Profile: '{1} [{2}]'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

		$_NotCompliant = $true

		switch ($PSCmdlet.ParameterSetName)
		{

			'Reapply'
			{

				# Error if the profile is not assigned to a server resource
				if ($null -eq $InputObject.serverHardwareUri)
				{

					$ExceptionMessage = 'The Server Profile {0} is not assigned to a server hardware resource.' -f $InputObject.name
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerProfilesAssignmet InvalidArgument 'ServerProfile' -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}
				
				# Get power state of assigned profile
				Try
				{

					$_server = Send-HPOVRequest -Uri $InputObject.serverHardwareUri -Hostname $ApplianceConnection
					
				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)
					
				}

				if ($_server.powerState -eq 'On')
				{

					$ExceptionMessage = 'The associated server resource {0} to the Server Profile {1} is powered on.  This operation only supports servers in a powered off state.  Please use Stop-HPOVServer before continuing.' -f $_server.name, $InputObject.name
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerProfilesAssignmet InvalidArgument 'ServerProfile' -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_PatchOperations = New-Object System.Collections.ArrayList
				$_ReapplyOperations = New-Object System.Collections.ArrayList

				Switch ($PSBoundParameters.Keys)
				{

					'Baseline'
					{

						$_Operation = NewObject -PatchOperation
		
						$_Operation.op    = "replace"
						$_Operation.path  = "/firmware/reapplyState"
						$_Operation.value = "ApplyPending" 

						[void]$_PatchOperations.Add($_Operation)
						[void]$_ReapplyOperations.Add('Baseline')

					}

					'AdapterAndBoot'
					{					

						$_Operation = NewObject -PatchOperation
		
						$_Operation.op    = "replace"
						$_Operation.path  = "/serverHardwareReapplyState"
						$_Operation.value = "ApplyPending" 

						[void]$_PatchOperations.Add($_Operation)
						[void]$_ReapplyOperations.Add('AdapterAndBoot')

					}

					'Connections'
					{					

						$_Operation = NewObject -PatchOperation
		
						$_Operation.op    = "replace"
						$_Operation.path  = "/connectionSettings/reapplyState"
						$_Operation.value = "ApplyPending" 

						[void]$_PatchOperations.Add($_Operation)
						[void]$_ReapplyOperations.Add('Connections')

					}

					'LocalStorage'
					{					

						$_Operation = NewObject -PatchOperation
		
						$_Operation.op    = "replace"
						$_Operation.path  = "/localStorage/reapplyState"
						$_Operation.value = "ApplyPending" 

						[void]$_PatchOperations.Add($_Operation)
						[void]$_ReapplyOperations.Add('LocalStorage')

					}

					'SANStorage'
					{					

						$_Operation = NewObject -PatchOperation
		
						$_Operation.op    = "replace"
						$_Operation.path  = "/sanStorage/reapplyState"
						$_Operation.value = "ApplyPending" 

						[void]$_PatchOperations.Add($_Operation)
						[void]$_ReapplyOperations.Add('SANStorage')

					}

					'BIOS'
					{					

						$_Operation = NewObject -PatchOperation
		
						$_Operation.op    = "replace"
						$_Operation.path  = "/bios/reapplyState"
						$_Operation.value = "ApplyPending" 

						[void]$_PatchOperations.Add($_Operation)
						[void]$_ReapplyOperations.Add('BIOS')

					}

					'OSDeployment'
					{
						
						if ($ApplianceConnection.ApplianceType -ne 'Composer')
						{

							$ExceptionMessage = 'The ApplianceConnection {0} is not a Synergy Composer.  OS Deployment Plans are only supported with HPE Synergy.' -f $ApplianceConnection
							$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						elseif ($null -eq $InputObject.osDeploymentSettings.osDeploymentPlanUri)
						{

							$ExceptionMessage = 'Server Profile {0} does not contain an OS Deployment Plan.  In order to use the -OSDeployment switch, the HPE Synergy Server Profile needs to have an OS Deployment Plan associated.' -f $InputObject.name

						}

						else
						{

							$_Operation = NewObject -PatchOperation
		
							$_Operation.op    = "replace"
							$_Operation.path  = "/osDeploymentSettings/reapplyState"
							$_Operation.value = "ApplyPending" 

							[void]$_PatchOperations.Add($_Operation)
							[void]$_ReapplyOperations.Add('OSDeployment')

						}						

					}

					default
					{

						[void]$_ReapplyOperations.Add('All')

						# BASELINE
						$_Operation = NewObject -PatchOperation
		
						$_Operation.op    = "replace"
						$_Operation.path  = "/firmware/reapplyState"
						$_Operation.value = "ApplyPending" 

						[void]$_PatchOperations.Add($_Operation)

						# ADAPTERANDBOOT
						$_Operation = NewObject -PatchOperation
		
						$_Operation.op    = "replace"
						$_Operation.path  = "/serverHardwareReapplyState"
						$_Operation.value = "ApplyPending" 

						[void]$_PatchOperations.Add($_Operation)

						# LOCALSTORAGE
						$_Operation = NewObject -PatchOperation
		
						$_Operation.op    = "replace"
						$_Operation.path  = "/localStorage/reapplyState"
						$_Operation.value = "ApplyPending" 

						[void]$_PatchOperations.Add($_Operation)

						# SANSTORAGE
						$_Operation = NewObject -PatchOperation
		
						$_Operation.op    = "replace"
						$_Operation.path  = "/sanStorage/reapplyState"
						$_Operation.value = "ApplyPending" 

						[void]$_PatchOperations.Add($_Operation)

						# BIOS
						$_Operation = NewObject -PatchOperation
		
						$_Operation.op    = "replace"
						$_Operation.path  = "/bios/reapplyState"
						$_Operation.value = "ApplyPending" 

						[void]$_PatchOperations.Add($_Operation)

						if ($ApplianceConnection.ApplianceType -eq 'Composer' -and $null -ne $InputObject.osDeploymentSettings.osDeploymentPlanUri)
						{

							$_Operation = NewObject -PatchOperation
		
							$_Operation.op    = "replace"
							$_Operation.path  = "/osDeploymentSettings/reapplyState"
							$_Operation.value = "ApplyPending" 

							[void]$_PatchOperations.Add($_Operation)

						}

					}

				}

				$_ShouldProcessMessage = "reapply server profile {0} configuration" -f [String]::Join($_ReapplyOperations.ToArray())

			}

			'Refresh'
			{

				$_Operation = NewObject -PatchOperation
		
				$_Operation.op    = "replace"
				$_Operation.path  = "/refreshState"
				$_Operation.value = "RefreshPending" 

				$_ShouldProcessMessage = "refresh server profile configuration."

			}

			default
			{

				$_Operation = NewObject -PatchOperation
		
				$_Operation.op    = "replace"
				$_Operation.path  = "/templateCompliance"
				$_Operation.value = "Compliant" 

				"{0}] Is Server Profile 'Compliant': {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.templateCompliance | Write-Verbose

				if ($InputObject.templateCompliance -ne 'Compliant')
				{

					try
					{

						$_spUpdateOperations = Send-HPOVRequest -Uri ($InputObject.uri + '/compliance-preview') -Hostname $InputObject.ApplianceConnection.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$ReviewObject = New-Object HPOneView.ServerProfile.CompliancePreview ($InputObject.name, 
																						  $_spUpdateOperations.isOnlineUpdate, 
																						  $_spUpdateOperations.ApplianceConnection)

					$_spUpdateOperations.automaticUpdates | ForEach-Object { [void]$ReviewObject.AutomaticUpdates.Add($_) }
					$_spUpdateOperations.manualUpdates | ForEach-Object { [void]$ReviewObject.ManualUpdates.Add($_) }

					$_ShouldProcessMessage = "Update Server Profile configuration. WARNING: Depending on this action, there might be a brief outage."

				}

				else
				{

					Write-Warning ('Skipping {0} Server Profile, as it is Compliant.' -f $InputObject.name)
					$_NotCompliant = $false

				}

			}

		}

		if ($_NotCompliant -and $PSCmdlet.ShouldProcess($InputObject.name, $_ShouldProcessMessage))
		{ 

			"[{0}] Sending request to {1} configuration" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PSCmdlet.ParameterSetName | Write-Verbose

			Try
			{

				$_task = Send-HPOVRequest -Uri $InputObject.uri -Method PATCH -Body $_Operation -Hostname $InputObject.ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if (-not($PSBoundParameters['Async']))
			{
			
				$_task = $_task | Wait-HPOVTaskComplete
		
			}

			$_task
			
		}

		elseif ($PSBoundParameters['WhatIf'])
		{
		
			"[{0}] User included -WhatIf." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Need to return the HPOneView.ServerProfile.ComplianceReview object
			if ($PSCmdlet.ParameterSetName -eq 'Default')
			{

				$ReviewObject

			}			
	
		}

		else 
		{

			"[{0}] User cancelled or server profile is compliant." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}    

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
