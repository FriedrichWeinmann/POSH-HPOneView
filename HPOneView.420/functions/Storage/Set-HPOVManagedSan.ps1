function Set-HPOVManagedSan 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Enable")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Enable")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Disable")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "DisableAlias")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Fabric','Name','ManagedSan','Resource')]
		[object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "Enable")]
		[Parameter (Mandatory = $false, ParameterSetName = "DisableAlias")]
		[Alias ('ZoningEnable','Enable')]
		[switch]$EnableAutomatedZoning,

		[Parameter (Mandatory = $false, ParameterSetName = "Disable")]
		[Alias ('ZoningDisable','Disable')]
		[switch]$DisableAutomatedZoning,

		[Parameter (Mandatory = $false, ParameterSetName = "Enable")]
		[Parameter (Mandatory = $false, ParameterSetName = "Disable")]
		[Parameter (Mandatory = $false, ParameterSetName = "DisableAlias")]
		[ValidateSet ('NoZoning', 'SingleInitiatorAllTargets','SingleInitiatorSingleStorageSystem','SingleInitiatorSingleTarget')]
		[ValidateNotNullOrEmpty()]
		[string]$ZoningPolicy = 'SingleInitiatorAllTargets',
	  
		[Parameter (Mandatory = $false, ParameterSetName = "Enable")]
		[switch]$EnableAliasing,

		[Parameter (Mandatory = $false, ParameterSetName = "DisableAlias")]
		[switch]$DisableAliasing,

		[Parameter (Mandatory = $false, ParameterSetName = "Enable")]
		[ValidateNotNullOrEmpty()]
		[string]$InitiatorNameFormat,

		[Parameter (Mandatory = $false, ParameterSetName = "Enable")]
		[ValidateNotNullOrEmpty()]
		[string]$TargetGroupNameFormat,

		[Parameter (Mandatory = $false, ParameterSetName = "Enable")]
		[ValidateNotNullOrEmpty()]
		[string]$TargetNameFormat,

		[Parameter (Mandatory = $false, ParameterSetName = "Enable")]
		[ValidateNotNullOrEmpty()]
		[string]$ZoneNameFormat,

		[Parameter (Mandatory = $false, ParameterSetName = "Enable")]
		[bool]$UpdateZoneNames,

		[Parameter (Mandatory = $false, ParameterSetName = "Enable")]
		[bool]$UpdateInitiatorAliases,
		
		[Parameter (Mandatory = $false, ParameterSetName = "Enable")]
		[bool]$UpdateTargetAliases,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Enable")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Disable")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "DisableAlias")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['Resource']))
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

		$_ResourceUpdateStatus = New-Object System.Collections.ArrayList

		if ($PSBoundParameters.Keys -Contains 'EnableAutomatedZoning')
		{

			Write-Warning "the -EnableAutomatedZoning parameter is being deprecated.  Please update your scripts to use the -ZoningPolicy parameter."

		}

		if ($PSBoundParameters.Keys -Contains 'DisableAutomatedZoning')
		{

			Write-Warning "the -DisableAutomatedZoning parameter is being deprecated.  Please update your scripts to use the -ZoningPolicy parameter."

		}

	}

	Process 
	{

		switch ($InputObject.GetType().Name)
		{

			'PSCustomObject'
			{

				"[$($MyInvocation.InvocationName.ToString().ToUpper())] Object received: {0}" -f ($InputObject | Out-String) | Write-Verbose

				# Generate error if wrong resource type
				if ($InputObject.category -ne 'fc-sans')
				{

					$ErrorRecord = New-ErrorRecord HPOneView.ManagedSanResourceException InvalidManagedSanResource InvalidArgument 'InputObject' -TargetType 'PSObject' -Message ("The provided Resource object is not a Managed SAN resource.  Expected resource category 'fc-sans'.  Received reource category {0}. Please check the value and try again." -f $InputObject.category)

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# Generate error if wrong resource type
				if (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord HPOneView.SanManagerResourceException InvalidSanManagerResource InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "The provided Resource object is missing the required ApplianceConnection property. Please check the value and try again."

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}
				
				if ($InputObject.isInternal)
				{

					$ExceptionMessage = "The provided Resource object '{0}' is an Internal SAN Manager and unsupported with this Cmdlet. Please check the value and try again." -f $InputObject.name
					$ErrorRecord = New-ErrorRecord HPOneView.SanManagerResourceException InvalidSanManagerResource InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage

					$PSCmdlet.WriteError($ErrorRecord)

				}

			}

			'String'
			{

				"[$($MyInvocation.InvocationName.ToString().ToUpper())] Getting Managed SAN by resource Name: {0}" -f $InputObject | Write-Verbose

				Try
				{

					$InputObject = Get-HPOVManagedSan $InputObject -ApplianceConnection $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

		}

		# Needed in order to support ErrorAction
		if (-not $ErrorRecord)
		{

			"[$($MyInvocation.InvocationName.ToString().ToUpper())] Processing '{0}'" -f $InputObject.name | Write-Verbose 

			# Disable zoning
			if ($DisableAutomatedZoning.IsPresent -or $ZoningPolicy -eq 'NoZoning')
			{ 
					
				$InputObject.sanPolicy.zoningPolicy = "NoZoning"

				# Need to disable Aliasing Support as well with the request
				$InputObject.sanPolicy.enableAliasing = $false
						
			}

			else
			{

				$InputObject.sanPolicy.zoningPolicy = $ZoningPolicy

				if ($EnableAliasing.IsPresent -or $ZoningPolicy -ne 'NoZoning') 
				{ 

					$InputObject.sanPolicy.enableAliasing = $True

					switch ($PSBoundParameters.Keys)
					{
						
						'InitiatorNameFormat'    { $InputObject.sanPolicy.initiatorNameFormat    = $InitiatorNameFormat }
						'TargetGroupNameFormat'  { $InputObject.sanPolicy.targetGroupNameFormat  = $TargetGroupNameFormat }
						'TargetNameFormat'       { $InputObject.sanPolicy.targetNameFormat       = $TargetNameFormat }
						'ZoneNameFormat'         { $InputObject.sanPolicy.zoneNameFormat         = $ZoneNameFormat }
						'UpdateZoneNames'        { $InputObject.sanPolicy.renameZones            = $UpdateZoneNames }
						'UpdateInitiatorAliases' { $InputObject.sanPolicy.renameInitiatorAliases = $UpdateInitiatorAliases }
						'UpdateTargetAliases'    { $InputObject.sanPolicy.renameTargetAliases    = $UpdateTargetAliases }

					}				
						
				}
				
				elseif ($DisableAliasing.IsPresent -or $ZoningPolicy -eq 'NoZoning') 
				{ 
					
					$InputObject.sanPolicy.enableAliasing = $false 
				
				}

			}

			"[$($MyInvocation.InvocationName.ToString().ToUpper())] Updated Managed SAN Object: {0}" -f ($InputObject | out-string) | Write-Verbose 

			Try
			{

				$_Resp = Send-HPOVRequest $InputObject.uri PUT $InputObject -Hostname $InputObject.ApplianceConnection.Name

				$_Resp | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.ManagedSan') }

				[void]$_ResourceUpdateStatus.Add($_Resp)

			}

			Catch
			{

				$_ResourceUpdateStatus

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

	}

	End 
	{
		
		Return $_ResourceUpdateStatus

	}

}
