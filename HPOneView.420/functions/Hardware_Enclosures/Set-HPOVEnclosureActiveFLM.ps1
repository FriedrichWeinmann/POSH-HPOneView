function Set-HPOVEnclosureActiveFLM
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default", SupportsShouldProcess,ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[object]$Enclosure,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Int]$BayID,

		[Parameter (Mandatory = $false)]
		[switch]$Force

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

		}


		$_TaskCollection      = New-Object System.Collections.ArrayList
		
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

		$_Operation = NewObject -PatchOperation
		$_Operation.op    = 'replace'
		$_Operation.path  = '/managerBays/{0}/role' -f $BayID
		$_Operation.value = 'Active'
				
		"[{0}] Requesting to Activate FLM in Bay {1} within {2} Enclosure" -f $MyInvocation.InvocationName.ToString().ToUpper(), $BayID, $Enclosure.name | Write-Verbose
		
		if ($PSCmdlet.ShouldProcess(('FLM Bay {0} within {1} Enclosure' -f $BayID, $Enclosure.name),'Change FLM State to Active'))
		{

			Try
			{

				$_resp = Send-HPOVRequest $Enclosure.Uri PATCH $_Operation -Hostname $Enclosure.ApplianceConnection.Name | Wait-HPOVTaskStart

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
