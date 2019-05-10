function New-HPOVQosConfig
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Passthrough")]
	Param 
	(

		[Parameter (Mandatory = $False, ParameterSetName = "Passthrough")]
		[Parameter (Mandatory, ParameterSetName = "Custom")]
		[ValidateSet ("Passthrough", "CustomNoFCoE", "CustomWithFCoE", IgnoreCase = $False)]
		[String]$ConfigType = "Passthrough",

		[Parameter (Mandatory = $False, ParameterSetName = "Custom")]
		[ValidateSet ("DSCP", "DOT1P", "DOT1P_AND_DSCP", IgnoreCase = $False)]
		[String]$UplinkClassificationType = "DOT1P",

		[Parameter (Mandatory = $False, ParameterSetName = "Custom")]
		[ValidateSet ("DSCP", "DOT1P", "DOT1P_AND_DSCP", IgnoreCase = $False)]
		[String]$DownlinkClassificationType = "DOT1P_AND_DSCP",

		[Parameter (Mandatory = $False, ParameterSetName = "Custom")]
		[System.Collections.ArrayList]$TrafficClassifiers = @()

	)

	Begin
	{

		# Helper CMDLET. Does not require appliance authentication.

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		# Validate the caller 
		if (($PSBoundParameters['UplinkClassificationType'] -or $PSBoundParameters['DownlinkClassificationType'] -or $PSBoundParameters['TrafficClassifiers']) -and $ConfigType -eq 'Passthrough')
		{

			$ParameterNames = New-Object System.Collections.ArrayList
		
			switch ($PSBoundParameters.Keys)
			{

				'UplinkClassificationType'   { [void]$ParameterNames.Add('UplinkClassificationType') }
				'DownlinkClassificationType' { [void]$ParameterNames.Add('DownlinkClassificationType') }
				'TrafficClassifiers'         { [void]$ParameterNames.Add('TrafficClassifiers') }

			}

			$Message = "ConfigType Parameter value was set to 'Passthrough' and $($ParameterNames -join ", ") Parameter (s) were provided.  When choosing 'Passthrough' QOS Config Type, the other Parameters cannot be used."
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'ConfigType' -Message $Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

	}

	Process
	{

		$_QosConfigurationObject            = NewObject -QosConfiguration
		$_QosConfigurationObject.configType = $ConfigType
		
		switch ($ConfigType)
		{

			'CustomNoFCoE'
			{

				"[{0}] Building 'CustomNoFCoE' QOS Configuration." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				if ($PSBoundParameters['TrafficClassifiers'])
				{

					"[{0}] Adding Custom Traffic Classifiers." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$TrafficClassifiers | ForEach-Object { [void]$_QosConfigurationObject.qosTrafficClassifiers.Add($_) }

				}
				
				else 
				{

					"[{0}] Adding Default NoFCoELossless Traffic Classifiers." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_QosConfigurationObject.qosTrafficClassifiers = NewObject -DefaultNoFCoELosslessQosTrafficClassifiers

				}

				$_QosConfigurationObject.uplinkClassificationType   = $UplinkClassificationType
				$_QosConfigurationObject.downlinkClassificationType = $DownlinkClassificationType
			
			}
			
			'CustomWithFCoE'
			{

				"[{0}] Building 'CustomWithFCoE' QOS Configuration." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				if ($PSBoundParameters['TrafficClassifiers'])
				{

					if ($TrafficClassifiers.Count -gt 6)
					{

						$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'TrafficClassifiers' -TargetType 'System.Collections.ArrayList' -Message "The number of provided TrafficClassifiers is exceeded by $($TrafficClassifiers.Count - 2).  When defining the QOS Configuration Type to 'CustomWithFCoE', only 6 Custom Traffic Classes are allowed."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					elseif ($TrafficClassifiers.Count -le 6)
					{

						1..($TrafficClassifiers.Count - 6) | ForEach-Object { 
						
							$_NewBaseTrafficClass = NewObject -BaseTrafficClass
							
							$_NewBaseTrafficClass.qosTrafficClass.className += $_

							[void]$_QosConfigurationObject.qosTrafficClassifiers.Add($_NewBaseTrafficClass) 
						
						}

					}

					"[{0}] Adding Custom Traffic Classifiers." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# Check to make sure caller has not provided 'Best effort' or 'FCoE lossless' Classes
					$TrafficClassifiers | ForEach-Object { 
					
						# Generate Error
						if ($_.name -eq 'FCoE lossless')
						{

							$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'TrafficClassifiers' -TargetType 'System.Collections.ArrayList' -Message "The 'FCoE lossless' traffic class is reserved.  Please remove it from the TrafficClassifiers Parameter and try again."
							
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}	
						
						# Add to collection
						[void]$_QosConfigurationObject.qosTrafficClassifiers.Add($_) 
					
					}

					# Add FCoE Class
					[void]$_QosConfigurationObject.qosTrafficClassifiers.Add((NewObject -FCoELossLessTrafficClass))

				}
				
				else 
				{

					"[{0}] Adding Default With FCoELossless Traffic Classifiers." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_QosConfigurationObject.qosTrafficClassifiers = NewObject -DefaultFCoELosslessQosTrafficClassifiers

				}
								
				$_QosConfigurationObject.uplinkClassificationType   = $UplinkClassificationType
				$_QosConfigurationObject.downlinkClassificationType = $DownlinkClassificationType

			}

		}

	}

	End
	{

		$_QosConfigurationObject.qosTrafficClassifiers | ForEach-Object { 
			
			if ($_.PSObject.TypeNames -notcontains 'HPOneView.Networking.Qos.TrafficClassifier')	
			{
			
				$_.PSObject.TypeNames.Insert(0,'HPOneView.Networking.Qos.TrafficClassifier') 
			
			}
		
		}

		$_QosConfigurationObject.PSObject.TypeNames.Insert(0,'HPOneView.Networking.Qos.Configuration')

		Return $_QosConfigurationObject

	}

}
