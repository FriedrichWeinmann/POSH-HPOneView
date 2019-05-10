function New-HPOVLogicalSwitchGroup
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateRange(1,2)]
		[int]$NumberOfSwitches = 1,

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$SwitchType,

		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[Alias ('Appliance')]
		[ValidateNotNullOrEmpty()]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[switch]$Async

	)

	Begin 
	{
		
		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $SwitchType)
		{

			$PipelineInput = $true

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

	}
	
	Process
	{

		# Create new LIgObject
		$_LogicalSwitchGroup = NewObject -LogicalSwitchGroup 
		$_LogicalSwitchGroup.name = $Name

		switch ($SwitchType.GetType().Name) 
		{

			"String" 
			{            

				# Assume Name
				"[{0}] Found VC FF in bay: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_bay.name | Write-Verbose

				Try
				{

					$SwitchType = Get-HPOVSwitchType -Name $SwitchType -ApplianceConnection $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}				

			}

			"PSCustomObject" 
			{

				"[{0}] Processing PSCustomObject: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $SwitchType | Write-Verbose

				# Validate 
				if ($SwitchType.category -ne 'switch-types')
				{

					"[{0}] Invalid switchtype resource.  Generating Terminating Error" -f $MyInvocation.InvocationName.ToString().ToUpper()

					$_Message = 'The provided Switch Type {0} is not a supported object category type.  Expected "switch-types", Received "{1}".' -f $SwitchType.name, $SwitchType.category

					$ErrorRecord = New-ErrorRecord HPOneView.SwitchTypeResourceException InvalidSwitchTypeResource InvalidArgument 'SwitchType' -TargetType 'PSObject' -Message $_Message
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}
			
			# Unsupported SwitchType object type
			default 
			{

				"[{0}] Invalid switchtype resource.  Generating Terminating Error" -f $MyInvocation.InvocationName.ToString().ToUpper()

				$_Message = 'The provided Switch Type {0} is not a supported object type.  Expected either [System.String] or [PSCustomObject], Received "{1}".' -f $SwitchType.name, $SwitchType.GetType().FullName

				$ErrorRecord = New-ErrorRecord HPOneView.SwitchTypeResourceException InvalidSwitchTypeResource InvalidArgument 'SwitchType' -TargetType $SwitchType.GetType().Name -Message $_Message
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		For ($i = 1; $i -le $NumberOfSwitches; $i++)
		{

			"[{0}] Adding Location Entry {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $i | Write-Verbose

			$_SwitchLogicalLocation = NewObject -SwitchLogicalLocation
			$_SwitchLogicalLocation.permittedSwitchTypeUri = $SwitchType.uri

			$_SwitchLocationEntry = NewObject -LocationEntry
			$_SwitchLocationEntry.relativeValue = $i
			$_SwitchLocationEntry.type = "StackingMemberId"

			[void]$_SwitchLogicalLocation.logicalLocation.locationEntries.Add($_SwitchLocationEntry)
			[void]$_LogicalSwitchGroup.switchMapTemplate.switchMapEntryTemplates.Add($_SwitchLogicalLocation)

		}

		"[{0}] LS: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), (ConvertTo-Json -Depth 99 $_LogicalSwitchGroup | out-string) | Write-Verbose 

		"{0}] Sending request to create '{1}'..." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_LogicalSwitchGroup.name | Write-Verbose 
	
		Try
		{
		
			$_Task = Send-HPOVRequest -Uri $LogicalSwitchGroupsUri -Method POST -Body $_LogicalSwitchGroup -Hostname $ApplianceConnection
		
		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not $Async.IsPresent)
		{

			Try
			{

				$_Task = Wait-HPOVTaskComplete -InputObject $_Task

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		$_Task

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
