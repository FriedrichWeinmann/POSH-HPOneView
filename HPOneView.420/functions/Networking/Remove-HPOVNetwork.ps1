function Remove-HPOVNetwork 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('uri', 'name', 'network','Resource')]
		[System.Object]$InputObject,
	
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[switch]$Force

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['Resource'])) 
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

		$_TaskCollection    = New-Object System.Collections.ArrayList
		$_NetworkCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Network Object provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
			"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.uri | Write-Verbose
			"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.ApplianceConnection.Name | Write-Verbose
			"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.category | Write-Verbose

			If ('ethernet-networks','fc-networks','fcoe-networks' -contains $InputObject.category)
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "Network:$($InputObject.Name)" -TargetType PSObject -Message "The Network resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_NetworkCollection.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "Network:$($InputObject.Name)" -TargetType PSObject -Message "The Network resource is not an expected category type [$($InputObject.category)].  Allowed resource category types are 'ethernet-networks', 'fc-networks', or 'fcoe-networks'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			foreach ($net in $InputObject) 
			{

				# Network passed is a URI
				if (($net -is [String]) -and [System.Uri]::IsWellFormedUriString($net,'Relative')) 
				{

					"[{0}] Received URI: $($net)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting Network Name" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$net = Send-HPOVRequest $net -ApplianceConnection $ApplianceConnection

					}

					Catch
					{

					  $PSCmdlet.ThrowTerminatingError($_)

					}
					
				}

				# Network passed is the Name
				elseif (($net -is [string]) -and (!$net.startsWith("/rest"))) 
				{

					"[{0}] Received Network Name $($net)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting Network object from Get-HPOVNetwork" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					# // NEED APPLIANCE NAME HERE with If Condition
					$net = Get-HPOVNetwork $net -ApplianceConnection $ApplianceConnection

					if ($network.count -gt 1 ) 
					{ 

						$ErrorRecord = New-ErrorRecord InvalidOperationException NetworkResourceNameNotUnique InvalidResult 'Remove-HPOVNetwork' -Message "Invalid Network Parameter: $net"
						$PSCmdlet.WriteError($ErrorRecord)                
					
					}

				}

				# Network passed is the object
				elseif ($net -is [PSCustomObject] -and ('ethernet-networks', 'fc-networks', 'fcoe-networks' -match $net.category)) 
				{
					
					"[{0}] Network Object provided.)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $net.name | Write-Verbose
					"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $net.uri | Write-Verbose
					"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $net.ApplianceConnection.Name | Write-Verbose
					"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $net.category | Write-Verbose
				
				}

				else 
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Network' -TargetType 'PSObject' -Message "Invalid Network Parameter: $($net )"
					$PSCmdlet.WriteError($ErrorRecord)

				}

				[void]$_NetworkCollection.Add($InputObject)

			}

		}
		
	}

	End
	{

		"[{0}] Processing $($_NetworkCollection.count) Network resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Process Network Resources
		ForEach ($_network in $_NetworkCollection)
		{

			if ($PSCmdlet.ShouldProcess($_network.name,"Remove Network from appliance '$($_network.ApplianceConnection.Name)'")) 
			{

				"[{0}] Removing Network '$($_network.name)' from appliance '$($_network.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					
					if ($PSBoundParameters['Force'])
					{

						$_network.uri += "?force=true"

					}

					$_resp = Send-HPOVRequest $_network.Uri DELETE -Hostname $_network.ApplianceConnection.Name

					[void]$_TaskCollection.Add($_resp)

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($PSBoundParameters['WhatIf'])
			{

				"[{0}] WhatIf Parameter was passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

		}

		Return $_TaskCollection

	}

}
