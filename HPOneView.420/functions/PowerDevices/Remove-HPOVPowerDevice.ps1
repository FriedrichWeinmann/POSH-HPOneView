function Remove-HPOVPowerDevice 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default",SupportsShouldProcess,ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("uri", "name", 'PowerDevice')]
		[object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[switch]$Force,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[switch]$Async,
	
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
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

		$_PowerDeviceCollection = New-Object System.Collections.ArrayList
   
	}

	Process 
	{

		if ($PipelineInput) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] PowerDevice Object provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
			"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.uri | Write-Verbose
			"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.ApplianceConnection.Name | Write-Verbose
			"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.category | Write-Verbose

			If ('power-devices' -contains $InputObject.category)
			{

				If (-not $InputObject.ApplianceConnection)
				{

					$ExceptionMessage = "The PowerDevice object resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$ErrorRecord = New-ErrorRecord HPOneView.PowerDeviceResourceException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_PowerDeviceCollection.Add($InputObject)

			}

			else
			{

				$ExceptionMessage = "The PowerDevice object resource is not an expected category type [{0}].  The allowed resource category type is 'power-devices'.  Please check the object provided and try again." -f $InputObject.category
				$ErrorRecord = New-ErrorRecord HPOneView.PowerDeviceResourceException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing Appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

				"[{0}] Processing Power Device Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject | Write-Verbose

				Try
				{

					$_PowerDevice = Get-HPOVPowerDevice -Name $PowerDevice -ErrorAction Stop -ApplianceConnection $_appliance

					$_PowerDevice | ForEach-Object {

						[void]$_PowerDeviceCollection.Add($_)

					}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}				

			}

		}
		
	}

	End
	{

		"[{0}] Begin resource removal process." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		foreach ($_PowerDevice in $_PowerDeviceCollection) 
		{

			if ($PSCmdlet.ShouldProcess($_PowerDevice.name,"Remove Power Device from appliance '$($_PowerDevice.ApplianceConnection.Name)'"))
			{   
			 				
				Try
				{
					
					$_task = Send-HPOVRequest -Uri $_PowerDevice.uri -Method DELETE -Hostname $_PowerDevice.ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($PSBoundParameters['Async'])
				{

					$_task

				}

				else
				{

					$_task | Wait-HPOVTaskComplete

				}

			}

			elseif ($PSBoundParameters['WhatIf'])
			{

				"[{0}] Caller passed -WhatIf Parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			else
			{

				"[{0}] Caller selected NO to confirmation prompt." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

		}

	}

}
