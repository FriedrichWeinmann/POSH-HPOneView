function Update-HPOVLogicalSwitch
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[Alias ('LogicalSwitch')]
		[Alias ('LS')]
		[ValidateNotNullorEmpty()]
		[object]$InputObject,
		
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[switch]$Async

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $PSBoundParameters['InputObject'])
		{

			$PiplineInput = $true

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

		$_lsobjects   = New-Object System.Collections.ArrayList

	}

	Process 
	{

		"[{0}] Processing $($InputObject.count) LI objects." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		foreach ($_logicalswitch in $InputObject) 
		{
			
			if (($_logicalswitch -is [PSCustomObject]) -and ($_logicalswitch.category -ieq 'logical-switches')) 
			{

				"[{0}] Logical Switch Object was provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_logicalswitch.name, $_logicalswitch.uri | Write-Verbose

				[void]$_lsobjects.Add($_logicalswitch)

			}

			else 
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType $_li.GetType().Name -Message "An invalid Resource object was provided. $($_li.GetType()) $($_li.category) was provided.  Only type String or PSCustomObject, and 'logical-interconnects' object category are permitted."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

	}

	End 
	{

		# Loop through liobject collection to perform action
		ForEach ($_ls in $_lsobjects)
		{

			"[{0}] Processing Logical Switch: $($_ls.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($PSCmdlet.ShouldProcess($_ls.name,"Refresh Logical Switch"))
			{ 

				Try
				{

					"[{0}] Sending request to refresh Logical Switch." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
					$uri = $_ls.uri + "/refresh"

					$_reply = Send-HPOVRequest $uri PUT -Hostname $_ls.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($PSBoundParameters['Async'])
				{

					$_reply

				}

				else
				{

					$_reply | Wait-HPOVTaskComplete

				}

			}

			elseif ($PSBoundParameters['WhatIf'])
			{
				
				"[{0}] User included -WhatIf." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			else
			{

				"[{0}] User cancelled." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}
		

		}

	}

}
