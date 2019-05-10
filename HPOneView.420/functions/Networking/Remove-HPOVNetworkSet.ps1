function Remove-HPOVNetworkSet 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = "default" ,SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(
		
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("uri","name")]
		[Object]$NetworkSet,

		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose
		
		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['NetworkSet']))
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

				# Check for URI Parameters with multiple appliance connections
				if($ApplianceConnection.Count -gt 1)
				{

					if (($NetworkSet -is [String] -and ($NetworkSet.StartsWith($NetworkSetsUri))) -or ($NetworkSet -is [Array] -and ($NetworkSet | ForEach-Object { $_.startswith($NetworkSetsUri) }))) 
					{
					
						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'NetworkSet' -Message "The NetworkSet Parameter as URI is unsupported with multiple appliance connections.  Please check the -NetworkSet Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
					}

				}


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
		
		$_NetSetsToRemoveCol = New-Object System.Collections.ArrayList

		$_TaskCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput)
		{

			"[{0}] Processing NetworkSet object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $NetworkSet.name | Write-Verbose
			"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $NetworkSet.uri | Write-Verbose
			"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $NetworkSet.ApplianceConnection.Name | Write-Verbose
			"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $NetworkSet.category | Write-Verbose

			if ($NetworkSet.category -ne 'network-sets')
			{

				$ErrorRecord = New-ErrorRecord HPOneView.NetworkSetResourceException InvalidArgumentValue InvalidArgument 'NetworkSet' -TargetType 'PSObject' -Message "The provided Network Set {$($NetworkSet.Name)} is an unsupported object category, '$($NetworkSet.category)'.  Only 'network-sets' category objects are supported. please chceck the Parameter value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			[void]$_NetSetsToRemoveCol.Add($NetworkSet)

		}

		Else
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing $($_appliance.Name) appliance connection (of $($ApplianceConnection.Count))." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					"[{0}] Getting Network Set object from Get-HPOVNetworkSet." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$NetworkSet = Get-HPOVNetworkSet $NetworkSet -ApplianceConnection $_appliance

					[void]$_NetSetsToRemoveCol.Add($NetworkSet)

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

		"[{0}] Begin resource removal process." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		foreach ($_NetSet in $_NetSetsToRemoveCol) 
		{

			if ($PSCmdlet.ShouldProcess($_NetSet.name,"Remove Network Set from appliance '$($_NetSet.ApplianceConnection.Name)'"))
			{   
			 
				
				Try
				{
					
					$_task = Send-HPOVRequest $_NetSet.uri DELETE -Hostname $_NetSet.ApplianceConnection.Name

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
