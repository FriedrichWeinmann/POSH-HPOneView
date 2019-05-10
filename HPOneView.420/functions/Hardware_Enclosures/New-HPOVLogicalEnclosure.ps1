function New-HPOVLogicalEnclosure
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		 
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[object]$Enclosure,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('eg')]
		[object]$EnclosureGroup,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[string]$FirmwareBaseline,
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[bool]$ForceFirmwareBaseline,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.ScopeCollection]$Scope,
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['Enclosure']))
		{

			$PipelineInput = $true

		}

		else
		{

			"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try 
			{
	
				$ApplianceConnection = Test-HPOVAuth $ApplianceConnection

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

		$_TaskResourceCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput) 
		{
				
			"[{0}] Synergy Frame object was passed via pipeline." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		# Error when target appliance is not a Synergy Composer or the Enclosure object is not a Synergy Frame
		if ((${Global:ConnectedSessions} | Where-Object Name -EQ $ApplianceConnection.Name).ApplianceType -ne 'Composer')
		{

			$Message = 'The Appliance {0} is not a Synergy Composer, and this operation is not supported.  Only Synergy managed resources are supported with this Cmdlet.' -f $ApplianceConnection.Name

			$ErrorRecord = New-ErrorRecord HPOneView.Appliance.ComposerNodeException UnsupportedMethod InvalidOperation 'ApplianceConnection' -TargetType 'HPOneView.Appliance.Connection' -Message $Message

			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_LogicalEnclosure      = NewObject -LogicalEnclosure
		$_LogicalEnclosure.name = $Name

		# Get Frame object type
		switch ($Enclosure.GetType().Name)
		{

			'PSCustomObject'
			{

				"[{0}] Synergy Frame object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($Enclosure | Out-String) | Write-Verbose 

				if ($Enclosure.category -ne $ResourceCategoryEnum['Enclosure'])
				{
				
					$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException InvalidResourceObject InvalidArgument 'Enclosure' -TargetType 'PSObject' -Message "The provided -Enclosure resource object is not an Enclosure or Synergy Frame.  Please correct the input object and try again."

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
				}

				# Validate Frame resource object
				if ($Enclosure.enclosureType -ne 'SY12000')
				{

					# Throw error, wrong resource
					$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException UnsupportedEnclosureType InvalidArgument 'Enclosure' -TargetType 'PSObject' -Message "The provided input object is not a Synergy Frame resource object.  Only Synergy Frames are supported with this Cmdlet."

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				if ($Enclosure.state -ne 'Monitored')
				{

					$ExceptionMessage = "The provided Synergy Frame resource '{0}' is already managed.  Please select another Synergy Frame resource object." -f $Enclosure.name
					$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException InvalidConfigurationState InvalidArgument -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			'String'
			{

				"[{0}] Synergy Frame Name provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Enclosure | Write-Verbose 

				Try
				{

					$Enclosure = Get-HPOVEnclosure -Name $Enclosure -ApplianceConnection $ApplianceConnection

					# Validate Frame resource object
					if ($Enclosure.enclosureType -ne 'SY12000')
					{

						# Throw error, wrong resource
						$ExceptionMessage = "The provided input object is not a Synergy Frame resource object.  Only Synergy Frames are supported with this Cmdlet."
						$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException UnsupportedEnclosureType InvalidArgument -TargetType 'PSObject' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if ($Enclosure.state -ne 'Monitored')
					{

						$ExceptionMessage = "The provided Synergy Frame resource '{0}' is already managed.  Please select another Synergy Frame resource object." -f $Enclosure.name
						$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException InvalidConfigurationState InvalidArgument -TargetType 'PSObject' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

		}

		# Get list of logical Frame members fro ILT
		Try
		{

			$_LinkedSynergyFrames = Send-HPOVRequest -Uri $InterconnectLinkTopologies -Hostname $ApplianceConnection.Name

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$_IltGroup = $_LinkedSynergyFrames.members | Where-Object { $_.enclosureMembers.enclosureUri -contains $Enclosure.uri }
		
		foreach ($_member in $_IltGroup.enclosureMembers)
		{

			"[{0}] Processing Enclosure URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_member.enclosureUri | Write-Verbose

			if ($_member.errorFlag)
			{

				Try
				{

					$_EnclosureObject = Send-HPOVRequest $_member.enclosureUri -Hostname $ApplianceConnection.Name

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
				"[{0}] Synergy Frame is in an Error State: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_EnclosureObject.state, $_EnclosureObject.stateReason | Write-Verbose 

				$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException InvalidConfigurationState InvalidArgument -TargetType 'PSObject' -Message ("The provided or linked Synergy Frame resource '{0}' is in an Error State: {1} ({2})  Please select another Synergy Frame resource object." -f $_EnclosureObject.name, $_EnclosureObject.state, $_EnclosureObject.stateReason)

				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			[void]$_LogicalEnclosure.enclosureUris.Add($_member.enclosureUri)

		}

		# Validate EG
		switch ($EnclosureGroup.GetType().Name)
		{

			'PSCustomObject'
			{

				"[{0}] Enclosure Group object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($EnclosureGroup | ConvertTo-Json -Depth 99 | Out-String) | Write-Verbose 

				if ($EnclosureGroup.category -ne $ResourceCategoryEnum['EnclosureGroup'])
				{
				
					$ErrorRecord = New-ErrorRecord HPOneView.EnclosureGroupResourceException InvalidResourceObject InvalidArgument -TargetType 'PSObject' -Message "The provided -EnclosureGroup resource object is not an Enclosure Group.  Please correct the input object and try again."

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
				}

			}

			'String'
			{

				"[{0}] Enclosure Group Name provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnclosureGroup | Write-Verbose 

				Try
				{

					$EnclosureGroup = Get-HPOVEnclosureGroup -Name $EnclosureGroup -ErrorAction Stop -ApplianceConnection $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

		}
		
		$_LogicalEnclosure.enclosureGroupUri = $EnclosureGroup.uri
		
		if ($PSBoundParameters['FirmwareBasline'])
		{

			# Validate Firmware Baseline
			switch ($FirmwareBasline.GetType().Name)
			{
				
				'PSCustomObject'
				{

					"[{0}] FirmwareBasline object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($FirmwareBasline | Out-String) | Write-Verbose 

					if ($FirmwareBasline.category -ne $ResourceCategoryEnum['Baseline'])
					{
					
						$ErrorRecord = New-ErrorRecord HPOneView.FirmwareBaselineResourceException InvalidResourceObject InvalidArgument -TargetType 'PSObject' -Message "The provided -FirmwareBasline resource object is not a Firmwaer Baseline.  Please correct the input object and try again."

						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
					}

				}

				'String'
				{

					"[{0}] Firmware Baseline Name provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $FirmwareBasline | Write-Verbose 

					Try
					{

						$FirmwareBaslineName = $FirmwareBasline.Clone()
						$FirmwareBasline = Get-HPOVBaseline  -File $FirmwareBasline -ApplianceConnection $ApplianceConnection -ErrorAction SilentlyContinue

						If (-not $FirmwareBasline)
						{

							$ExceptionMessage = "The provided Baseline '{0}' was not found." -f $FirmwareBaslineName
							$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'FirmwareBasline' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

			}

			$_LogicalEnclosure.firmwareBaselineUri  = $FirmwareBaseline.uri
			$_LogicalEnclosure.forceInstallFirmware = $ForceFirmwareBaseline

		}

		# "[{0}] Logical Enclosure object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_LogicalEnclosure | out-string) | Write-Verbose 

		"[{0}] Creating {1} Logical Enclosure" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_LogicalEnclosure.name | Write-Verbose

		if ($PSBoundParameters['Scope'])
		{

			ForEach ($_Scope in $Scope)
			{

				"[{0}] Adding resource to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

				[void]$_LogicalEnclosure.initialScopeUris.Add($_Scope.Uri)

			}

		}

		Try
		{

			$resp = Send-HPOVRequest -URI $LogicalEnclosuresUri -Method 'POST' -Body $_LogicalEnclosure -ApplianceConnection $ApplianceConnection
			
			if (-not $PSBoundParameters['Async'])
			{
				
				$resp = $resp | Wait-HPOVTaskComplete 
				
			}

			else
			{

				$resp

			}

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
