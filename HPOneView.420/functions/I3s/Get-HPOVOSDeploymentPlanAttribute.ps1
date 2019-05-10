function Get-HPOVOSDeploymentPlanAttribute
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = ($ConnectedSessions | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $PSBoundParameters['InputObject'])
		{

			$PipelineInput = $true

		}

		else
		{

			"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if (-not($ApplianceConnection) -and -not($ConnectedSessions))
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

		$_PlanAttributesCol = New-Object System.Collections.ArrayList

	}

	Process
	{

		if ($PipelineInput)
		{

			$ApplianceConnection = $ConnectedSessions | Where-Object Name -eq $ApplianceConnection.Name

		}

		If ($ApplianceConnection.ApplianceType -ne 'Composer')
		{

			$ExceptionMessage = 'The ApplianceConnection {0} ({1}) is not a Synergy Composer.  This Cmdlet only support Synergy Composer management appliances.' -f $ApplianceConnection.Name, $ApplianceConnection.ApplianceType
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_OSDeploymentSettingsCollection = New-Object 'HPOneView.ServerProfile.OSDeployment.OsDeploymentPlanParametersCollection[HPOneView.ServerProfile.OSDeployment.OSDeploymentParameter]'

		if ($InputObject.category -eq $ResourceCategoryEnum.ServerProfileTemplate)
		{

			# Process the osDeploymentSettings.osCustomAttributes for plan attributs to return

			ForEach ($_SptDeploymentPlanAttribute in $InputObject.osDeploymentSettings.osCustomAttributes)
			{

				'[{0}] Add {1} = {2} into OsCustomAttributesCollection' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_SptDeploymentPlanAttribute.name, $_SptDeploymentPlanAttribute.value | Write-Verbose

				$_PlanAttribute = New-Object HPOneView.ServerProfile.OSDeployment.OSDeploymentParameter ($_SptDeploymentPlanAttribute.name, $_SptDeploymentPlanAttribute.value)

				[void]$_OSDeploymentSettingsCollection.Add($_PlanAttribute)

			}

		}

		elseif ($InputObject.category -eq 'os-deployment-plans')
		{

			$ExpectedParamForNic = @{
				connectionid = $null;
				dhcp         = $False;
				ipv4disable  = $False;
				networkuri   = $null;
				constraint   = "auto"
			}

			#Build initial collection of Build Plan Parameters
			ForEach ($_PlanAttribute in $InputObject.additionalParameters)
			{

				'[{0}] Attribute name: {1}, type: {2}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_PlanAttribute.name, $_PlanAttribute.caType | Write-Verbose

				if ($_PlanAttribute.caType -eq 'nic')
				{

					ForEach ($AdditionalNicParam in ($ExpectedParamForNic.GetEnumerator() | Sort-Object keys ))
					{

						$_ParameterName = '{0}.{1}' -f $_PlanAttribute.name, $AdditionalNicParam.key

						'[{0}] Add "{1}" NIC "{2}" = "{3}" into OsCustomAttributesCollection' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_PlanAttribute.name, $_ParameterName, $AdditionalNicParam.value | Write-Verbose					

						$_Attribute = New-Object HPOneView.ServerProfile.OSDeployment.OSDeploymentParameter($_ParameterName, $AdditionalNicParam.value)

						[void]$_OSDeploymentSettingsCollection.Add($_Attribute)

					}

				}

				if ([System.Convert]::ToBoolean($_PlanAttribute.caEditable) -and $_PlanAttribute.caType -ne 'nic')
				{

					'[{0}] Add {1} = {2} into OsCustomAttributesCollection' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_PlanAttribute.name, $_PlanAttribute.value | Write-Verbose

					$_PlanAttribute = New-Object HPOneView.ServerProfile.OSDeployment.OSDeploymentParameter ($_PlanAttribute.name, $_PlanAttribute.value)

					[void]$_OSDeploymentSettingsCollection.Add($_PlanAttribute)

				}

			}
		}

		$_OSDeploymentSettingsCollection

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
