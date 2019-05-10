function Update-HPOVLogicalEnclosureFirmware 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(
		
		[Parameter (ValueFromPipeline, Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('le','LogicalEnclosure')]
		[object]$InputObject,
		
		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[object]$Baseline,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateSet('EnclosureOnly', 'SharedInfrastructureOnly', 'SharedInfrastructureAndServerProfiles')]
		[String]$FirmwareUpdateProcess,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateSet('Orchestrated','Parallel')]
		[String]$InterconnectActivationMode = 'Orchestrated',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Switch]$ForceInstallation,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Switch]$Async,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Default")]
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

		ForEach ($_InputObject in $InputObject)
		{

			# Resource Validations

			# Validate the Input object is the allowed category
			if ($_InputObject.category -ne $ResourceCategoryEnum.LogicalEnclosure)
			{

				$ExceptionMessage = "The provided LogicalEnclosure object {0} category '{1}' is not an allowed value.  Expected category value is 'logical-enclosures'. Please correct your input value." -f $_InputObject.name, $_InputObject.category
				$ErrorRecord = New-ErrorRecord HPOneView.LogicalEnclosureResourceException InvalidLogicalEnclosureCategory InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if ($Baseline.category -ne $ResourceCategoryEnum.Baseline -or $Baseline.bundleType -ne 'SPP')
			{

				$ExceptionMessage = "The provided Baseline object {0} is not a valid resource object.  Only an SPP can be used to update firmware. Please correct your input value." -f $Baseline.name
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException InvalidBaselineObject InvalidArgument 'Baseline' -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if (-not $baseline.ApplianceConnection.Equals($_InputObject.ApplianceConnection))
			{

				$ExceptionMessage = "The provided LogicalEnclosure object {0} and baseline object {1} are not from the same HPE OneViwe appliance." -f $_InputObject.name, $Baseline.name
				$ErrorRecord = New-ErrorRecord HPOneView.LogicalEnclosureResourceException InvalidLogicalEnclosureCategory InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			"[{0}] Processing Logical Enclosure: {0} [{1}]'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_InputObject.name, $_InputObject.uri | Write-Verbose

			$_FirmwareUpdate = NewObject -LogicalEnclosureFirmareUpdate

			$_FirmwareUpdate.firmwareBaselineUri           = $Baseline.uri
			$_FirmwareUpdate.firmwareUpdateOn              = $LogicalEnclosureFirmwareUpdateMethodEnum[$FirmwareUpdateProcess]
			$_FirmwareUpdate.forceInstallFirmware          = $ForceInstallation.IsPresent
			$_FirmwareUpdate.logicalInterconnectUpdateMode = $LogicalInterconnectUpdateModeEnum[$InterconnectActivationMode]

			$_PatchOperation = NewObject -PatchOperation

			$_PatchOperation.op = "replace"
			$_PatchOperation.path = "/firmware"
			$_PatchOperation.value = $_FirmwareUpdate

			Switch ($LogicalEnclosureFirmwareUpdateMethodEnum[$FirmwareUpdateProcess])
			{

				'EnclosureOnly'
				{

					$_ShouldProcessMessage = 'update enclosure controller (Onboard Administrator or Frame Link Module(s)) only'

				}

				'SharedInfrastructureOnly'
				{

					if ($LogicalInterconnectUpdateModeEnum[$InterconnectActivationMode] -eq $LogicalInterconnectUpdateModeEnum['Parallel'])
					{

						Write-Warning "Parallel activation is optimized for faster updates and will cause service outages. Firmware updates using parallel activation should be performed within a maintenance window."

					}

					$_ShouldProcessMessage = 'update all infrastructure components, enclosure controller (Onboard Administrator or Frame Link Module(s)) and Virtual Connect.  Servers without assigned Server Profiles will also be updated.'

				}

				'SharedInfrastructureAndServerProfiles'
				{

					if ($LogicalInterconnectUpdateModeEnum[$InterconnectActivationMode] -eq $LogicalInterconnectUpdateModeEnum['Parallel'])
					{

						Write-Warning "Parallel activation is optimized for faster updates and will cause service outages. Firmware updates using parallel activation should be performed within a maintenance window."

					}

					$_ShouldProcessMessage = 'update all components within the logical enclosure, including enclosure controller, Virtual Connect and servers'

				}

			}			

			if ($ForceInstallation.IsPresent)
			{

				Write-Warning "Downgrading the firmware can result in the installation of unsupported firmware and cause hardware to cease operation."

			}			

			if ($PSCmdlet.ShouldProcess($_InputObject.name, $_ShouldProcessMessage))
			{ 

				"[{0}] Sending request to update firmware on the Logical Enclosure with {1} mode" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalEnclosureFirmwareUpdateMethodEnum[$FirmwareUpdateProcess] | Write-Verbose

				Try
				{

					$_task = Send-HPOVRequest -Uri $_InputObject.uri -Method PATCH -Body $_PatchOperation -AddHeader @{'If-Match' = $_InputObject.eTag} -Hostname $_InputObject.ApplianceConnection

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


			elseif ($PSBoundParameters['WhatIf'])
			{
				
				"[{0}] User included -WhatIf." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# // TODO: Need to get API calls to supply the report
				# if ($PSCmdlet.ParameterSetName -eq 'Update')
				# {

				# 	Try
				# 	{

				# 		Compare-LogicalInterconnect -InputObject $_leObject

				# 	} 

				# 	Catch
				# 	{

				# 		$PSCmdlet.ThrowTerminatingError($_)

				# 	}

				# }
			
			}

			else
			{

				"[{0}] User cancelled." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}    

		}

	}

	End
	{
		
		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
