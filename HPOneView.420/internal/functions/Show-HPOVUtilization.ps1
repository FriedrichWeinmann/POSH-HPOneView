function Show-HPOVUtilization
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

    [CmdletBinding ()]
    Param 
	(

        [Parameter (Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
		[Alias ('Resource')]
        [Object]$InputObject,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

    )

	Begin
	{

		# Throw "Not implemented"

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

        "[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		# Key off of ApplianceConnection for Pipeline Input
		if (-not($PSBoundParameters['InputObject']))
		{

			$PipelineInput = $True

		}

		else
		{

			Try
			{

				$Resource.ApplianceConnection = Test-HPOVAuth $Resource.ApplianceConnection

			}

			Catch [HPOneview.Appliance.AuthSessionException] 
			{

				$errorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError $ApplianceConnection[$c].Name -Message $_.Exception.Message -InnerException $_.Exception
				$PSCmdlet.ThrowTerminatingError($errorRecord)

			}

			Catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

	}

	Process
	{

		ForEach ($_resource in $InputObject)
		{

			"[$($MyInvocation.InvocationName.ToString().ToUpper())] Processing object: {0}" -f $_resource.name | Write-Verbose 

			switch ($_resource.category)
			{

				${ResourceCategoryEnum.ServerProfile}
				{

					$_uri = $_resource.serverHardwareUri + '/utilization'

				}

				'server-hardware'
				{

					$_uri = $_resource.uri + '/utilization'

				}

			}

			# Check to see if the resource is eligable for performance monitoring.

			Try
			{

				$_UtilizationData = Send-HPOVRequest -uri $_uri -Hostname $_resource.ApplianceConnection.Name

			}

			Catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			switch ($_resource.category)
			{

				'server-hardware'
				{

					$_UtilizationObj = New-Object HPOneView.ServerUtilization($_resource.name, $_resource.uri, [HPOneView.Library.ApplianceConnection]$_resource.ApplianceConnection)

				}

				'enclosures'
				{

					$_UtilizationObj = New-Object HPOneView.EnclosureUtilization($_resource.name, $_resource.uri, [HPOneView.Library.ApplianceConnection]$_resource.ApplianceConnection)

				}

				default
				{

					# Resource is unsupported, generate error

				}

			}

			ForEach ($_item in $_UtilizationData.metricList)
			{
			
				switch ($_item.metricName)
				{
			
					'AmbientTemperature'
					{
			
						$_total = 0
						$_count = 0
						$_item.metricSamples | ForEach-Object { $_[1] | ForEach-Object { $_total += $_; $_count++ } }
			
						$_UtilizationObj.AmbientTemperatureAverage = [Math]::Round(($_total / $_count), 2)
						$_UtilizationObj.AmbientTemperature = $_item.metricCapacity
					
					}
			
					'AveragePower'
					{
			
						$_total = 0
						$_count = 0
						($_item.metricSamples | ForEach-Object { $_[1] | ForEach-Object { $_total += $_; $_count++ } })
					
						$_UtilizationObj.PowerAverage = [Math]::Round(($_total / $_count), 2)
						
					}

					'CpuAverageFreq'
					{

						$_total = 0
						$_count = 0
						($_item.metricSamples | ForEach-Object { $_[1] | ForEach-Object { $_total += $_; $_count++ } })

						$_UtilizationObj.CpuAverage = [Math]::Round(($_total / $_count), 2)

					}

					'CpuUtilization'
					{


					}
			
					'PeakPower'
					{
					
						$_PeakValue = 0
			
						ForEach ($_Sample in $_item.metricSamples)
						{
			
			
							if ($_Sample[1] -gt $_PeakValue)
							{
			
								$_PeakValue = $_Sample[1]
			
							}
			
						}
			
						$_UtilizationObj.PowerPeak = $_PeakValue
					
					}
			
				}
			
				
				
			}

			$_UtilizationObj

		}

	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
