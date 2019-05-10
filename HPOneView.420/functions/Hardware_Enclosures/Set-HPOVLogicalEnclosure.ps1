function Set-HPOVLogicalEnclosure
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ('eg')]
		[object]$EnclosureGroup,

		[Parameter (Mandatory = $false)]
		[ValidateSet ('RedundantPowerFeed', 'RedundantPowerSupply')]
		[String]$PowerMode,

		[Parameter (Mandatory = $false)]
		[ValidateSet ('ASHRAE_A3', 'ASHRAE_A4', 'Standard', 'Telco')]
		[String]$AmbientTemperatureSetting,
		
		[Parameter (Mandatory = $false)]
		[switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject']))
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

	}

	Process 
	{

		if ((${Global:ConnectedSessions} | Where-Object Name -EQ $ApplianceConnection.Name).ApplianceType -ne 'Composer')
		{

			$Message = 'The Appliance {0} is not a Synergy Composer, and this operation is not supported.  Only Synergy managed resources are supported with this Cmdlet.' -f $ApplianceConnection.Name
			$ErrorRecord = New-ErrorRecord HPOneView.Appliance.ComposerNodeException UnsupportedMethod InvalidOperation 'ApplianceConnection' -TargetType 'HPOneView.Appliance.Connection' -Message $Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}	

		if ($PipelineInput) 
		{
				
			"[{0}] Synergy Frame object was passed via pipeline."  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}		

		# Get type
		switch ($InputObject.GetType().Name)
		{

			'PSCustomObject'
			{

				"[{0}] Synergy Frame object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($InputObject | Out-String) | Write-Verbose 

				if ($InputObject.category -ne $ResourceCategoryEnum['LogicalEnclosure'])
				{
				
					$ExceptionMessage = "The provided -Enclosure resource object is not an Enclosure or Synergy Frame.  Please correct the input object and try again."
					$ErrorRecord = New-ErrorRecord HPOneView.InputObjectResourceException InvalidResourceObject InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
				}

				Try
				{

					"[{0}] Getting associated Enclosure Group to identify enclosure type." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
					
					$_EnclosureGroup = Send-HPOVRequest -Uri $InputObject.enclosureGroupUri -Hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
				if ($_EnclosureGroup.enclosureTypeUri -NotMatch 'SY12000')
				{

					# Throw error, wrong resource
					$ExceptionMessage = "The provided input object is not a Synergy Frame resource object.  Only Synergy Frames and associated Logical Enclosures are supported with this Cmdlet."
					$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException UnsupportedEnclosureType InvalidArgument -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_UpdatedLogicalEnclosure = $InputObject.PSObject.Copy()

			}

			'String'
			{

				"[{0}] Synergy Frame name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject | Write-Verbose 

				Try
				{

					$_UpdatedLogicalEnclosure = Get-HPOVLogicalEnclosure -Name $InputObject -ErrorAction Stop -ApplianceConnection $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				Try
				{

					"[{0}] Getting associated Enclosure Group to identify enclosure type." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
					
					$_EnclosureGroup = Send-HPOVRequest -Uri $InputObject.enclosureGroupUri -Hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
				if ($_EnclosureGroup.enclosureTypeUri -NotMatch 'SY12000')
				{

					# Throw error, wrong resource
					$ExceptionMessage = "The provided input object is not a Synergy Frame resource object.  Only Synergy Frames and associated Logical Enclosures are supported with this Cmdlet."
					$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException UnsupportedEnclosureType InvalidArgument -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

		}

		switch ($PSBoundParameters.Keys)
		{

			'Name'
			{

				$_UpdatedLogicalEnclosure.name = $Name

			}

			'EnclosureGroup'
			{

				# Validate EG
				switch ($EnclosureGroup.GetType().Name)
				{

					'PSCustomObject'
					{

						"[{0}] Enclosure Group object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($EnclosureGroup | ConvertTo-Json -Depth 99 | Out-String) | Write-Verbose 

						if ($EnclosureGroup.category -ne $ResourceCategoryEnum['EnclosureGroup'])
						{
						
							$ExceptionMessage = "The provided -EnclosureGroup resource object is not an Enclosure Group.  Please correct the input object and try again."
							$ErrorRecord = New-ErrorRecord HPOneView.EnclosureGroupResourceException InvalidResourceObject InvalidArgument -TargetType 'PSObject' -Message $ExceptionMessage
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

				$_UpdatedLogicalEnclosure.enclosureGroupUri = $EnclosureGroup.uri

			}

			'PowerMode'
			{

				$_UpdatedLogicalEnclosure.powerMode = $FramePowerModeEnum[$PowerMode]

			}

			'AmbientTemperatureSetting'
			{

				$_UpdatedLogicalEnclosure.ambientTemperatureMode = $FrameAmbientTemperatureEnum[$AmbientTemperatureSetting]

			}

		}

		Try
		{

			$resp = Send-HPOVRequest -Uri $InputObject.uri -Method PUT $_UpdatedLogicalEnclosure -Hostname $ApplianceConnection.Name
			
			if (-not($PSBoundParameters['Async']))
			{
				
				$resp = $resp | Wait-HPOVTaskComplete -TimeOut (New-TimeSpan -Minutes 45)
				
			}

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}
		
		$resp

	}

	End 
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
