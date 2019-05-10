function Set-HPOVDataCenter
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Float]$Width,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Float]$Depth,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Switch]$Millimeters,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Int]$ElectricalDerating,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateSet ('NaJp', 'Custom', 'None')]
		[String]$ElectricalDeratingType,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Int]$DefaultVoltage,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Currency,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Float]$PowerCosts,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Int]$CoolingCapacity,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Float]$CoolingMultiplier,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
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

		$_ApplianceRemoteSupportCol = New-Object System.Collections.ArrayList

	}

	Process
	{

		if ($InputObject -is [PSCustomObject]) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Remote Support Contact Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

			If ('datacenters' -contains $InputObject.category)
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord HPOneView.DataCenterResourceException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message "The InputObject object resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			else
			{

				$ErrorRecord = New-ErrorRecord HPOneView.DataCenterResourceException InvalidArgumentValue InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message "The InputObject object resource is not an expected type.  The allowed resource category type is 'DataCenters'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else
		{

			Try
			{

				$InputObject = Get-HPOVDataCenter -Name $InputObject -ApplianceConnection $ApplianceConnection -ErrorAction Stop

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		$_DataCenterObject = $InputObject.PSObject.Copy()

		switch ($PSBoundParameters.Keys)
		{

			'Name'
			{

				$_DataCenterObject.name = $Name

			}

			'Width'
			{

				if (-not $Millimeters.IsPresent)
				{

					# Convert from Feet to Millimeters
					$Width = [Math]::Round($Width * .3048 * 1000, 2)

				}	

				$_DataCenterObject.width = $Width

			}

			'Depth'
			{

				if (-not $Millimeters.IsPresent)
				{

					# Convert from Feet to Millimeters
					$Depth = [Math]::Round($Depth * .3048 * 1000, 2)

				}

				$_DataCenterObject.depth = $Depth

			}

			'ElectricalDerating'
			{

				if ($PSBoundParameters['ElectricalDeratingType'] -ne 'Custom')
				{

					$ExceptionMessage = 'The ElectricalDerating paraemter was used with a custom value, without providing the ElectricalDeratingType parameter.  ElectricalDerating will not be set to the value.'
					$ErrorRecord = New-ErrorRecord HPOneview.DataCenterResourceException InvalidParameter InvalidArgument 'ElectricalDerating' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				else
				{

					$_DataCenterObject.deratingPercentage = $ElectricalDerating

				}

			}

			'ElectricalDeratingType'
			{

				if ($PSBoundParameters['ElectricalDerating'] -eq 'Custom' -and (-not $PSBoundParameters['ElectricalDerating']))
				{

					$ExceptionMessage = 'The ElectricalDeratingType paraemter is set to "Custom" without providing the ElectricalDerating parameter.  ElectricalDeratingType will not be set to the value.'
					$ErrorRecord = New-ErrorRecord HPOneview.DataCenterResourceException InvalidParameter InvalidArgument 'ElectricalDeratingType' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				else
				{

					$_DataCenterObject.deratingType = $ElectricalDeratingType

					$NeedToUpdateTwice = $false

					if ($ElectricalDeratingType -eq 'Custom')
					{

						$NeedToUpdateTwice = $true

					}

				}

			}

			'DefaultVoltage'
			{

				$_DataCenterObject.defaultPowerLineVoltage = $DefaultVoltage

			}

			'Currency'
			{

				$_DataCenterObject.currency = $Currency

			}

			'PowerCosts'
			{

				$_DataCenterObject.costPerKilowattHour = $PowerCosts

			}

			'CoolingCapacity'
			{

				$_DataCenterObject.coolingCapacity = $CoolingCapacity

			}

			'CoolingMultiplier'
			{

				$_DataCenterObject.coolingMultiplier = $CoolingMultiplier

			}
			
		}

		Try
		{

			$Resp = Send-HPOVRequest -Uri $_DataCenterObject.uri -Method PUT -Body ($_DataCenterObject | Select-Object * -Exclude RemoteSupportLocation) -Hostname $_DataCenterObject.ApplianceConnection

			if ($NeedToUpdateTwice)
			{

				"[{0}] Need to update the DC object again in order to set deratingPercentage custom value" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$resp.deratingPercentage = $ElectricalDerating

				$Resp = Send-HPOVRequest -Uri $Resp.uri -Method PUT -Body ($Resp | Select-Object * -Exclude RemoteSupportLocation) -Hostname $Resp.ApplianceConnection

			}

			$Resp

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
