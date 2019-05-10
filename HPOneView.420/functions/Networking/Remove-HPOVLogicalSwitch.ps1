function Remove-HPOVLogicalSwitch
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("ls",'LogicalSwitch')]
		[Object]$InputObject,
	
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false, ParameterSetName = "default")] 
		[switch]$Force,

		[Parameter (Mandatory = $false, ParameterSetName = "default")] 
		[switch]$Async

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

		$_taskcollection          = New-Object System.Collections.ArrayList
		$_logicalswitchcollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

			If ('logical-switches' -eq $InputObject.category)
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message "The Logical Switch resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_logicalswitchcollection.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message "The Logical Switch resource is not an expected category type [$($InputObject.category)].  Allowed resource category type is 'logical-switches'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			foreach ($_resource in $InputObject) 
			{

				if ($_resource -is [String])
				{

					"[{0}] Received URI: $($_resource)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$ErrorRecord = New-ErrorRecord InvalidOperationException UnsupportedParameterType InvalidArgumetn 'InputObject' -Message "The provided Resource value is a String, only PSCustomObject types are supported."
					$PSCmdlet.WriteError($ErrorRecord)

				}

				# LIG passed is the object
				elseif ($_resource -is [PSCustomObject] -and 'logical-switches' -eq $_resource.category)
				{
					
					"[{0}] Object provided: $($_resource )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					[void]$_logicalswitchcollection.Add($_resource)
				
				}

				elseif ($_resource -is [PSCustomObject] -and 'logical-switches' -ne $_resource.category)
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Resource' -TargetType 'PSObject' -Message "Invalid Logical Switch Parameter: $($_lig )"
					$PSCmdlet.WriteError($ErrorRecord)

				}

			}

		}
		
	}

	End
	{

		"[{0}] Processing $($_logicalswitchcollection.count) resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Process Resources
		ForEach ($_ls in $_logicalswitchcollection)
		{
		
			if ($PSCmdlet.ShouldProcess($_ls.ApplianceConnection.Name,("Remove Logical Switch '{0}'" -f $_ls.name))) 
			{

				"[{0}] Removing '$($_ls.name)' from appliance '$($_ls.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					
					if ($force.IsPresent)
					{

						$_ls.uri += "?force=true"

					}

					$_reply = Send-HPOVRequest $_ls.uri DELETE -Hostname $_ls.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($PSboundParameters['Async'])
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

				"[{0}] WhatIf Parameter was passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

		}

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
