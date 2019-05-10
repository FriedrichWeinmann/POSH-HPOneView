function Reset-HPOVEnclosureDevice
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "ManagerOrDeviceBay")]
		[ValidateNotNullOrEmpty()]
		[Object]$Enclosure,

		[Parameter (ParameterSetName = "default", Mandatory)]
		[Parameter (ParameterSetName = "ManagerOrDeviceBay", Mandatory)]
		[ValidateNotNullorEmpty()]
		[ValidateSet ('FLM','Appliance','ICM','Device')]
		[String]$Component,

		[Parameter (ParameterSetName = "default", Mandatory)]
		[Parameter (ParameterSetName = "ManagerOrDeviceBay", Mandatory)]
		[ValidateNotNullorEmpty()]
		[Int]$DeviceID,

		[Parameter (ParameterSetName = 'ManagerOrDeviceBay', Mandatory)]
		[Switch]$Reset,

		[Parameter (ParameterSetName = 'default', Mandatory = $False)]
		[Switch]$Efuse,

		[Parameter (ParameterSetName = 'default', Mandatory = $False)]
		[Parameter (ParameterSetName = 'ManagerOrDeviceBay', Mandatory = $False)]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "ManagerOrDeviceBay")]
		[ValidateNotNullorEmpty()]
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
		
			$PipelineInput = $True 
			
		}

		else
		{

			if ($Enclosure -isnot [PSCustomObject])
			{

				$_Message = 'An invalid Enclosure object type was provided, {0}.  This Cmdlet only support PSObject types from Get-HPOVEnclosure.  Please check the value and try agin.'
				$ErrorRecord = New-ErrorRecord HPOneview.EnclosureResourceException InvalidObjectType InvalidArgument 'Enclosure' -TargetType $Enclosure.Gettype().Name -Message $_Message
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

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

		$_TaskCollection      = New-Object System.Collections.ArrayList
		$_EnclosureCollection = New-Object System.Collections.ArrayList
		
	}

	Process
	{

		if ($Enclosure -isnot [PSCustomObject] -and $Enclosure.category -ne 'enclosures')
		{

			$_Message = 'An invalid Enclosure object type was provided, {0}.  This Cmdlet only support PSObject types from Get-HPOVEnclosure.  Please check the value and try agin.' -f $Enclosure.Gettype().Name
			$ErrorRecord = New-ErrorRecord HPOneview.EnclosureResourceException InvalidObjectType InvalidArgument 'Enclosure' -TargetType $Enclosure.Gettype().Name -Message $_Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if (-not($Enclosure.ApplianceConnection))
		{

			$_Message = 'The provided Enclosure resource object is missing the ApplianceConnection property.  This Cmdlet only support PSObject types from Get-HPOVEnclosure.  Please check the value and try agin.'
			$ErrorRecord = New-ErrorRecord HPOneview.EnclosureResourceException InvalidObjectType InvalidArgument 'Enclosure' -TargetType $Enclosure.Gettype().Name -Message $_Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_Operation       = NewObject -PatchOperation
		$_Operation.op    = 'replace'
		$_Operation.value = 'E-Fuse'

		switch ($Component)
		{

			'FLM'
			{

				$_Operation.path = '/managerBays/{0}/bayPowerState' -f $DeviceID

				if ($PSBoundParameters['Reset'])
				{

					$_Operation.value = 'Reset'

				}

			}

			'Device'
			{
				
				$_Operation.path = '/deviceBays/{0}/bayPowerState' -f $DeviceID

				if ($PSBoundParameters['Reset'])
				{

					$_Operation.value = 'Reset'

				}

			}

			'ICM'
			{

				$_Operation.path = '/interconnectBays/{0}/bayPowerState' -f $DeviceID

			}

			'Appliance'
			{

				$_Operation.path = '/applianceBays/{0}/bayPowerState' -f $DeviceID

			}
		
		}

		"[{0}] Power Operation: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_Operation | Out-String) | Write-Verbose

		if ($PSCmdlet.ShouldProcess(('{0} {1} within {2}' -f $Component, $DeviceID, $Enclosure.name),'Reset power for device'))
		{

			Try
			{

				$_resp = Send-HPOVRequest -Uri $Enclosure.Uri -Method PATCH -Body $_Operation -AddHeader @{'If-Match' = $Enclosure.eTag} -Hostname $Enclosure.ApplianceConnection.Name | Wait-HPOVTaskStart

				if (-not($PSBoundParameters['Async']))
				{

					$_resp = Wait-HPOVTaskComplete $_resp

				}

				[Void]$_TaskCollection.Add($_resp)

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}
		
		elseif ($PSCmdlet.PSBoun['WhatIf'])
		{

			"[{0}] WhatIf operation." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		else
		{

			"[{0}] User cancelled operation." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

	}

	End
	{

		Return $_TaskCollection

	}

}
