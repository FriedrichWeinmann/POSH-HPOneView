function New-HPOVQosTrafficClass
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[Alias ('ClassName')]
		[string]$Name,

		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[ValidateRange(1,100)]
		[int]$MaxBandwidth,

		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[string]$BandwidthShare,
		
		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[int]$EgressDot1pValue,

		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[System.Collections.ArrayList]$IngressDot1pClassMapping,
		
		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[System.Collections.ArrayList]$IngressDscpClassMapping,

		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[switch]$RealTime,

		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[switch]$Enabled

	)

	Begin
	{

		# CMDLET doesn't require auth

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		$NoMatch = New-Object System.Collections.ArrayList
		
		# Validate the IngressDscpClassMapping values caller is providing
		ForEach ($item in $IngressDscpClassMapping)
		{

			if (-not($IngressDscpClassMappingEnum -contains $item))
			{

				[void]$NoMatch.Add($item)

			}

		}

		# Check to make sure caller isn't attempting to create an FCoE lossless Class
		if ($Name -eq "FCoE lossless")
		{

			$Message = "The 'FCoE lossless' Traffic Classifier cannot be modified or created.  It is automatically created when using the 'New-HPOVQosConfig' CMDLET."
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Name' -Message $Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($Name -eq "Best effort" -and $PSBoundParameters['MaxBandwidth'] -and $PSBoundParameters.Count -gt 2 -and (-not($PSBoundParameters['verbose']) -or -not($PSBoundParameters['debug']) -or -not($PSBoundParameters['Enabled'])))
		{

			$Message = "The 'Best effort' Traffic Classifier can only be created with providing the 'Name' and 'MaxBandwidth' Parameters."
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Name' -Message $Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($NoMatch)
		{

			$Message = "Invalid IngressDscpClassMapping Parameter values found: $($NoMatch -join ', ').  Please remove these values and try again."
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'IngressDscpClassMapping' -TargetType 'Array' -Message $Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

	}

	Process
	{

		$_BaseTrafficClass = NewObject -BaseTrafficClass

		switch ($PSBoundParameters.Keys)
		{

			"Name"
			{

				$_BaseTrafficClass.qosTrafficClass.className = $Name

			}

			"MaxBandwidth"
			{
			
				$_BaseTrafficClass.qosTrafficClass.maxBandwidth = $MaxBandwidth
			
			}

			"BandwidthShare"
			{

				$_BaseTrafficClass.qosTrafficClass.bandwidthShare = $BandwidthShare
						
			}


			"EgressDot1pValue"
			{
			
				$_BaseTrafficClass.qosTrafficClass.egressDot1pValue = $EgressDot1pValue
			
			}

			"RealTime"
			{
			
				$_BaseTrafficClass.qosTrafficClass.realTime = $RealTime
			
			}
			
			"IngressDot1pClassMapping"
			{

				$IngressDot1pClassMapping | ForEach-Object { [void]$_BaseTrafficClass.qosClassificationMapping.dot1pClassMapping.Add($_) }

			}
			
			"IngressDscpClassMapping"
			{

				$IngressDscpClassMapping | ForEach-Object { [void]$_BaseTrafficClass.qosClassificationMapping.dscpClassMapping.Add($_) }

			}

		}

		# "[{0}] BaseTrafficClass Object: $($_BaseTrafficClass ) $($_BaseTrafficClass.qosTrafficClass ) $($_BaseTrafficClass.qosClassificationMapping )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

	End
	{

		$_BaseTrafficClass.PSObject.TypeNames.Insert(0,'HPOneView.Networking.QosTrafficClassifier')

		Return $_BaseTrafficClass

	}

}
