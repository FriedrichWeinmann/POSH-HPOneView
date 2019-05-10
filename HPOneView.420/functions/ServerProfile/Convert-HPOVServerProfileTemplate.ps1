function Convert-HPOVServerProfileTemplate
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('ServerProfileTemplate', 'SPT')]
		[Object]$InputObject,
		
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$ServerHardwareType,
		
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Object]$EnclosureGroup,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
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

			$PipelineInput = $True

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

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError 'ApplianceConnection' -Message $_.Exception.Message -InnerException $_.Exception
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}     

		$_taskCollection = New-Object System.Collections.ArrayList

	}

	Process
	{

		$_TransformType = New-Object System.Collections.ArrayList

		$_ServerHardwareTypeUri = $null
		$_EnclosureGroupUri = $null

		# Process InputObject
		if ($InputObject.category -ne $ResourceCategoryEnum.ServerProfileTemplate)
		{

			# Throw exception
			$ExceptionMessage = 'The provided object {0} is not supported.  Only Server Profile Template is supported.' -f $InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneview.InputObjectResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Process SHT
		if ($PSBoundParameters['ServerHardwareType'] -and $ServerHardwareType.category -ne $ResourceCategoryEnum.ServerHardwareType)
		{

			# Throw exception
			$ExceptionMessage = 'The provided object {0} is not supported.  Only Server Hardware Type is supported.' -f $ServerHardwareType.name
			$ErrorRecord = New-ErrorRecord HPOneview.ServerHardwareTypeResourceException InvalidServerHardwareTypeResource InvalidArgument "ServerHardwareType" -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif ($PSBoundParameters['ServerHardwareType'])
		{

			$_ServerHardwareTypeUri = $ServerHardwareType.uri

			[void]$_TransformType.Add('server hardware type')

		}

		elseif (-not $PSBoundParameters['ServerHardwareType'])
		{

			$_ServerHardwareTypeUri = $InputObject.serverHardwareTypeUri

			[void]$_TransformType.Add('server hardware type')

		}

		# Process EG
		if ($PSBoundParameters['EnclosureGroup'] -and $EnclosureGroup.category -ne $ResourceCategoryEnum.EnclosureGroup)
		{

			# Throw exception
			$ExceptionMessage = 'The provided object {0} is not supported.  Only Enclosure Group is supported.' -f $EnclosureGroup.name
			$ErrorRecord = New-ErrorRecord HPOneview.EnclosureGroupResourceException InvalidEnclosureGroupResource InvalidArgument "EnclosureGroup" -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}
		
		# Allow transformation of a Server Profile Template designed for DL/ML/Apollo to BL/WS
		elseif (($PSBoundParameters['EnclosureGroup'] -and $null -ne $InputObject.enclosureGroupUri) -or
				($PSBoundParameters['EnclosureGroup'] -and $ServerHardwareType.model -match 'BL|WS|SY'))
		{

			$_EnclosureGroupUri = $EnclosureGroup.uri

			[void]$_TransformType.Add('enclosure group')

		}

		elseif (-not $PSBoundParameters['EnclosureGroup'] -and $null -ne $InputObject.enclosureGroupUri)
		{

			$_EnclosureGroupUri = $InputObject.enclosureGroupUri

			[void]$_TransformType.Add('enclosure group')

		}

		elseif ($PSBoundParameters['EnclosureGroup'] -and $null -eq $InputObject.enclosureGroupUri)
		{

			$ExceptionMessage = 'The provided Server Profile Template object {0} is likely a DL/ML/Apollo resource and does not support Enclosure Group objects.' -f $InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneview.EnclosureGroupResourceException InvalidEnclosureGroupResource InvalidOperation "EnclosureGroup" -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Build final transformation URI
		$_Uri = '{0}/transformation?serverHardwareTypeUri={1}&enclosureGroupUri={2}' -f $InputObject.uri, $_ServerHardwareTypeUri, $_EnclosureGroupUri

		Try
		{

			$_TransformedServerProfileTemplate = Send-HPOVRequest -Uri $_Uri -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$_ShouldProcessMessage = 'transform the server profile template to new {0}' -f [String]::Join(' and ', $_TransformType.ToArray())

		if ($PSCmdlet.ShouldProcess($InputObject.Name, $_ShouldProcessMessage))
		{

			# Saving results back to appliance
			Try
			{

				$_TransformedServerProfileTemplateResults = Send-HPOVRequest -Uri $InputObject.uri -Method PUT -Body $_TransformedServerProfileTemplate -Hostname $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if (-not $PSBoundParameters['Async'])
			{

				$_TransformedServerProfileTemplateResults | Wait-HPOVTaskComplete

			}

			else
			{

				$_TransformedServerProfileTemplateResults

			}

		}
		
	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
