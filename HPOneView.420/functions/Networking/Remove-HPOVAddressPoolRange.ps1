function Remove-HPOVAddressPoolRange
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(
		
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[Alias ('AddressPool')]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName , ParameterSetName = "Default")]
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
		
		$_AddressPoolsToRemoveCol = New-Object System.Collections.ArrayList

		$_TaskCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput)
		{

			"[{0}] Processing pipeline input objects." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		"[{0}] Processing object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
		"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.uri | Write-Verbose
		"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.ApplianceConnection.Name | Write-Verbose
		"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.category | Write-Verbose

		if ($InputObject.category -notmatch 'id-range-')
		{

			$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressSubnetException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "The provided InputObject {$($InputObject.Name)} is an unsupported object category, '$($InputObject.category)'.  Only 'id-range-VMAC', 'id-range-VWWN', 'id-range-VSN' or 'id-range-IPv4-subnet' category objects are supported."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		[void]$_AddressPoolsToRemoveCol.Add($InputObject)

	}

	End
	{

		"[{0}] Begin resource removal process." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		foreach ($_Pool in $_AddressPoolsToRemoveCol) 
		{

			if ($PSCmdlet.ShouldProcess($_Pool.ApplianceConnection.Name,("Remove address pool range 'Start:{0} (End:{1})'" -f $_Pool.startAddress, $_Pool.endAddress)))
			{   
			 
				
				Try
				{
					
					Send-HPOVRequest $_Pool.uri DELETE -Hostname $_Pool.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

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

		# Return $_TaskCollection

	}

}
