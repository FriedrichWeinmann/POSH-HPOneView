function Remove-HPOVAddressPoolSubnet 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "IPv4",SupportsShouldProcess,ConfirmImpact = 'High')]
	Param 
	(
		
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "IPv4")]
		[Alias ('Subnet')]
		[ValidateNotNullorEmpty()]
		[Object]$IPv4Subnet,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName , ParameterSetName = "IPv4")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose
		
		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['IPv4Subnet']))
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
		
		$_IPv4SubnetPoolsToRemoveCol = New-Object System.Collections.ArrayList

		$_TaskCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput)
		{

			"[{0}] Processing pipeline input objects." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		# "[{0}] Received object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($IPv4Subnet ) | Write-Verbose

		if ($IPv4Subnet.category -ne 'id-range-IPv4-subnet')
		{

			$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressSubnetException InvalidArgumentValue InvalidArgument 'IPv4Subnet' -TargetType 'PSObject' -Message "The provided IPv4Subnet {$($IPv4Subnet.Name)} is an unsupported object category, '$($IPv4Subnet.category)'.  Only 'id-range-IPv4-subnet' category objects are supported. Please chceck the Parameter value and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		[void]$_IPv4SubnetPoolsToRemoveCol.Add($IPv4Subnet)

	}

	End
	{

		"[{0}] Begin resource removal Process." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		foreach ($_Subnet in $_IPv4SubnetPoolsToRemoveCol) 
		{

			if ($PSCmdlet.ShouldProcess($_Subnet.ApplianceConnection.Name,("Remove IPv4 SubnetID '{0}'" -f $_Subnet.networkId)))
			{   
			 
				
				Try
				{
					
					$_task = Send-HPOVRequest $_Subnet.uri DELETE -Hostname $_Subnet.ApplianceConnection.Name

					[void]$_TaskCollection.Add($_task)

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

		Return $_TaskCollection

	}

}
