function Update-HPOVLogicalEnclosure 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Reapply", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(
		
		[Parameter (ValueFromPipeline, Mandatory = $false, ParameterSetName = "Update")]
		[Parameter (ValueFromPipeline, Mandatory = $false, ParameterSetName = "Reapply")]
		[ValidateNotNullOrEmpty()]
		[Alias ('le','LogicalEnclosure')]
		[object]$InputObject,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Update")]
		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Reapply")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory, ParameterSetName = "Update")]
		[Alias ('UpdateFromGroup')]
		[Switch]$Update,

		[Parameter (Mandatory, ParameterSetName = "Reapply")]
		[Switch]$Reapply,

		[Parameter (Mandatory = $false, ParameterSetName = "Update")]
		[Parameter (Mandatory = $false, ParameterSetName = "Reapply")]
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

		$_TaskCollection             = New-Object System.Collections.ArrayList
		$_LogicalEnclosureCollection = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		if ($PipelineInput -or $InputObject) 
		{
		
			"[{0}] Processing Pipeline input." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Error if the input value is not a PSObject
			if (-not $InputObject -is [PSCustomObject])
			{

				$ErrorRecord = New-ErrorRecord HPOneView.LogicalEnclosureResourceException InvalidLogicalEnclosureObjectType InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "The provided LogicalEnclosure value is not a valid PSObject ($($LogicalEnclosure.GetType().Name)). Please correct your input value."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			"[{0}] LogicalEnclosure PSObject: $($InputObject | Out-String)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Validate the Input object is the allowed category
			if ($InputObject.category -ne $ResourceCategoryEnum['LogicalEnclosure'])
			{

				$ErrorRecord = New-ErrorRecord HPOneView.LogicalEnclosureResourceException InvalidLogicalEnclosureCategory InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "The provided LogicalEnclosure object ($($LogicalEnclosure.name)) category '$($LogicalEnclosure.category)' is not an allowed value.  Expected category value is 'logical-enclosures'. Please correct your input value."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if(-not $InputObject.ApplianceConnection)
			{

				$ErrorRecord = New-ErrorRecord HPOneView.LogicalEnclosureResourceException InvalidLogicalEnclosureObject InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "The provided LogicalEnclosure object ($($LogicalEnclosure.name)) does not contain the required 'ApplianceConnection' object property. Please correct your input value."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			[void]$_LogicalEnclosureCollection.Add($InputObject)
		
		}

		# Not Pipeline input, and support Array of Logical Enclosure Name or PSObject
		else
		{

			"[{0}] Processing InputObject Parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] InputObject is [$($InputObject.GetType().Name)]." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			ForEach ($_le in $InputObject)
			{
					
				"[{0}] InputObject value: $($_le)." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Looking for Logical Enclosure Name on connected sessions provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Loop through all Appliance Connections
				ForEach ($_appliance in $ApplianceConnection)
				{

					"[{0}] Processing '$($_appliance.Name)' Session." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_resp = Get-HPOVLogicalEnclosure $_le -ApplianceConnection $_appliance.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					[void]$_LogicalEnclosureCollection.Add($_resp)

				}

			}

		}

	}

	End
	{
		# Perform the work
		ForEach ($_leObject in $_LogicalEnclosureCollection) 
		{

			"[{0}] Processing Logical Enclosure: '$($_leObject.name) [$($_leObject.uri)]'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$NothingToDo = $false
			
			switch ($PSCmdlet.ParameterSetName) 
			{

				"Reapply" 
				{ 

					"[{0}] Reapply configuration." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					$uri = $_leObject.uri + "/configuration" 
				
				}
				
				"Update"
				{ 

					"[{0}] Update from Group." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					$uri = $_leObject.uri + "/updateFromGroup" 

					if ($_leObject.state -eq 'Consistent')
					{

						$NothingToDo = $true

					}
				
				}
				
			}

			if ((-not $NothingToDo) -and $PSCmdlet.ShouldProcess($_leObject.name,"$($PSCmdlet.ParameterSetName) Logical Enclosure configuration. WARNING: Depending on this action, there might be a brief outage."))
			{ 

				"[{0}] Sending request to $($PSCmdlet.ParameterSetName) configuration" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_task = Send-HPOVRequest $uri PUT -Hostname $_leObject.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if (-not($PSBoundParameters['Async']))
				{
					
					$_task | Wait-HPOVTaskComplete
				
				}

				else
				{

					$_task

				}

			}

			elseif ($NothingToDo)
			{

				Write-Warning ("The {0} Logical Enclosure is already consistent.  There is nothing to do." -f $_leObject.Name)

			}

			elseif ($PSBoundParameters['WhatIf'])
			{
				
				"[{0}] User included -WhatIf." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				if ($PSCmdlet.ParameterSetName -eq 'Update')
				{

					Try
					{

						Compare-LogicalInterconnect -InputObject $_leObject

					} 

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}
			
			}

			else
			{

				"[{0}] User cancelled." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}           

		}

	}

}
