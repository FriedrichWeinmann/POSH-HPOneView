function Get-HPOVRemoteSupportEntitlementStatus
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = "default")]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)
	
	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose
		
		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		
		if (-not $PSBoundParameters['InputObject'])
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

				For ([int]$c = 0; $c -gt $ApplianceConnection.Count; $c++) 
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

		$_ResourcesToProcess = New-Object System.Collections.ArrayList

		switch ($InputObject.category)
		{

			$ResourceCategoryEnum.Enclosure
			{

				"[{0}] Processing Enclosure: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
				
				[void]$_ResourcesToProcess.Add($InputObject.PSObject.Copy())

			}

			$ResourceCategoryEnum.LogicalEnclosure
			{

				"[{0}] Processing Logical Enclosure: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

				ForEach ($_Uri in $InputObject.enclosureUris)
				{

					Try
					{
		
						$_Resource = Send-HPOVRequest -Uri $_Uri -Hostname $ApplianceConnection				
		
					}
		
					Catch
					{
		
						$PSCmdlet.ThrowTerminatingError($_)
		
					}

					[void]$_ResourcesToProcess.Add($_Resource)

				}

			}

			$ResourceCategoryEnum.EnclosureGroup
			{

				"[{0}] Processing Enclosure Group, and getting associated Logical Enclosures: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
				
				$_Uri = '{0}?parentUri={1}&name=ENCLOSURE_GROUP_TO_LOGICAL_ENCLOSURE' -f $AssociationsUri, $InputObject.uri
	
				Try
				{
	
					[Array]$_AssoiatedLEs = (Send-HPOVRequest -Uri $_Uri -Hostname $ApplianceConnection).members | ForEach-Object { Send-HPOVRequest $_.childUri -Hostname $_.ApplianceConnection.Name}

					ForEach ($_Uri in $InputObject.enclosureUris)
					{
	
						Try
						{
			
							$_Resource = Send-HPOVRequest -Uri $_Uri -Hostname $ApplianceConnection				
			
						}
			
						Catch
						{
			
							$PSCmdlet.ThrowTerminatingError($_)
			
						}
	
						[void]$_ResourcesToProcess.Add($_Resource)
	
					}
	
				}
	
				Catch
				{
	
					$PSCmdlet.ThrowTerminatingError($_)
	
				}

			}

			$ResourceCategoryEnum.ServerHardware
			{

				"[{0}] Processing server hardware device: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

				[void]$_ResourcesToProcess.Add($InputObject.PSObject.Copy())

			}

			$ResourceCategoryEnum.ServerProfile
			{

				"[{0}] Processing server profile: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

				if ($Null -eq $InputObject.serverHardwareUri)
				{

					"[{0}] Server Profile is currently unassigned." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

				}

				else
				{

					Try
					{
		
						$_Resource = Send-HPOVRequest -Uri $InputObject.serverHardwareUri -Hostname $ApplianceConnection				
		
					}
		
					Catch
					{
		
						$PSCmdlet.ThrowTerminatingError($_)
		
					}

					[void]$_ResourcesToProcess.Add($_Resource)

				}				

			}

			default
			{

				# Generae error of unsupported resource
				$ExceptionMessage = 'The {0} input object is an unsupported resource category type, "{1}".  Only "server-hardware"., "server-profile", "enclosure-group", "logical-enclosure" or "enclosure" resources are supported.' -f $InputObject.category, $InputObject.name 
				$ErrorRecord = New-ErrorRecord HPOneview.InputObjectResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType 'String' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		ForEach ($_Resource in $_ResourcesToProcess)
		{

			"[{0}] Getting Remote Support status for: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Resource.name | Write-Verbose

			Try
			{

				$_RemoteSupportStatus = Send-HPOVRequest -Uri $_Resource.remoteSupportUri -Hostname $ApplianceConnection				

			}

			Catch [HPOneView.Appliance.RemoteSupportResourceException]
			{

				$ExceptionMessage = "The device {0} is not eligible for Remote Support." -f $_Resource.name
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportResourceException DeviceNotEligible InvalidOperation "Server" -Message $ExceptionMessage -InnerException $_.Exception.InnerException
				$PSCmdlet.WriteError($ErrorRecord)

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($_RemoteSupportStatus.supportEnabled)
			{

				"[{0}] Resource has Remote Support enabled, getting entitlement information." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_ResourceEntitlementStatus = Send-HPOVRequest -Uri $_RemoteSupportStatus.entitlementUri -Hostname $ApplianceConnection

				}

				Catch
				{
	
					$PSCmdlet.ThrowTerminatingError($_)
	
				}

				if ($null -eq $_ResourceEntitlementStatus.obligationStartDate)
				{

					[DateTime]$_ResourceEntitlementStatus.obligationStartDate = '01/01/1970'
					
				}

				if ($null -eq $_ResourceEntitlementStatus.obligationEndDate)
				{

					[DateTime]$_ResourceEntitlementStatus.obligationEndDate = '01/01/1970'

				}

				if ($null -eq $_ResourceEntitlementStatus.offerStartDate)
				{

					[DateTime]$_ResourceEntitlementStatus.offerStartDate = '01/01/1970'

				}

				if ($null -eq $_ResourceEntitlementStatus.offerEndDate)
				{

					[DateTime]$_ResourceEntitlementStatus.offerEndDate = '01/01/1970'

				}

				# Get resource name
				switch ($_Resource.type)
				{

					'server-hardware'
					{

						if ($null -ne $_Resource.serverName)
						{

							$_ResourceName = $_Resource.serverName

						}

						else
						{

							$_ResourceName = $_Resource.name

						}

					}

					'enclosures'
					{

						$_ResourceName = $_Resource.name

					}

				}

				$_EntitlementStatus = New-Object HPOneView.RemoteSupport.ContractAndWarrantyStatus ($_ResourceName,
																									$_Uri,
																									$_Resource.serialNumber,
																									$_ResourceEntitlementStatus.entitlementPackage,
																									$_ResourceEntitlementStatus.entitlementStatus,
																									$_ResourceEntitlementStatus.offerStatus,
																									$_ResourceEntitlementStatus.coverageDays,
																									$_ResourceEntitlementStatus.coverageHoursDay1to5,
																									$_ResourceEntitlementStatus.coverageHoursDay6,
																									$_ResourceEntitlementStatus.coverageHoursDay7,
																									$_ResourceEntitlementStatus.responseTimeDay1to5,
																									$_ResourceEntitlementStatus.responseTimeDay6,
																									$_ResourceEntitlementStatus.responseTimeDay7,
																									[DateTime]$_ResourceEntitlementStatus.obligationStartDate,
																									[DateTime]$_ResourceEntitlementStatus.obligationEndDate,
																									[DateTime]$_ResourceEntitlementStatus.offerStartDate,
																									[DateTime]$_ResourceEntitlementStatus.offerEndDate,
																									$_ResourceEntitlementStatus.countryCode,
																									$_ResourceEntitlementStatus.obligationType,
																									$_ResourceEntitlementStatus.entitlementKey,
																									$_ResourceEntitlementStatus.obligationId,
																									$_ResourceEntitlementStatus.coversHolidays,
																									$_ResourceEntitlementStatus.isEntitled,
																									$_ResourceEntitlementStatus.responseTimeHolidays,
																									$_ResourceEntitlementStatus.explanation,
																									$_resourceEntitlementStatus.ApplianceConnection
																								)

			}

			else
			{

				"[{0}] Remote Support is disabled for the resource, returning ." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_EntitlementStatus = New-Object HPOneView.RemoteSupport.ContractAndWarrantyStatus ($_ResourceName,
																									$_Uri,
																									$_Resource.serialNumber,
																									$false,
																									'INVALID',
																									$_Resource.ApplianceConnection
																									)
				
			}

			$_EntitlementStatus

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}	

}
