function Get-HPOVPowerPotentialDeviceConnection 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("uri","name")]
		[object]$PowerDevice,
	
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

		if (-not($PSBoundParameters['PowerDevice'])) 
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

			If ('power-devices' -contains $PowerDevice.category)
			{

				If (-not($PowerDevice.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord HPOneView.PowerDeviceResourceException InvalidArgumentValue InvalidArgument "PowerDevice:$($PowerDevice.Name)" -TargetType PSObject -Message "The PowerDevice object resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				Try
				{

					$_resp = Send-HPOVRequest ($powerDevicePotentialConnections + $PowerDevice.uri)

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}				

				if ($_resp)
				{

					$_resp | ForEach-Object { 
						
						$_.PSObject.TypeNames.Insert(0,'HPOneView.PowerDevice.PotentialPowerConnection')
					
						[void]$_PowerDeviceCollection.Add($_)

					}

				}

			}

			else
			{

				$ErrorRecord = New-ErrorRecord HPOneView.PowerDeviceResourceException InvalidArgumentValue InvalidArgument "PowerDevice:$($PowerDevice.Name)" -TargetType PSObject -Message "The PowerDevice object resource is not an expected category type [$($PowerDevice.category)].  The allowed resource category type is 'power-devices'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing Appliance $($_appliance.Name) (of $($ApplianceConnection.Count))" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Processing Power Device Name $($PowerDevice)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_PowerDevice = Get-HPOVPowerDevice $PowerDevice -ApplianceConnection $_appliance

					$_resp = $_PowerDevice | ForEach-Object { Send-HPOVRequest ($powerDevicePotentialConnections + $_.uri) }

					$_resp | ForEach-Object {

						$_.PSObject.TypeNames.Insert(0,'HPOneView.PowerDevice.PotentialPowerConnection')

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

		Return $_PowerDeviceCollection

	}

}
