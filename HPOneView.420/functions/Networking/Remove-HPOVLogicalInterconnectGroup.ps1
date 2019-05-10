function Remove-HPOVLogicalInterconnectGroup 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("uri","name","Lig",'Resource')]
		[Object]$InputObject,
	
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false, ParameterSetName = "default")] 
		[switch]$force

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

		$_taskcollection = New-Object System.Collections.ArrayList
		$_ligcollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput -or $InputObject -is [PSCustomObject]) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] LIG Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

			If ('sas-logical-interconnect-groups','logical-interconnect-groups' -contains $InputObject.category)
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "LIG:$($InputObject.Name)" -TargetType PSObject -Message "The LIG resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_ligcollection.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "LIG:$($InputObject.Name)" -TargetType PSObject -Message "The LIG resource is not an expected category type [$($InputObject.category)].  Allowed resource category type is 'logical-interconnect-groups'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			foreach ($_lig in $InputObject) 
			{

				# LIG passed is a URI
				if (($_lig -is [String]) -and [System.Uri]::IsWellFormedUriString($_lig,'Relative')) 
				{

					"[{0}] Received URI: $($_lig)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting Network Name" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					if ($ApplianceConnection.count -gt 1)
					{

						$ErrorRecord = New-ErrorRecord InvalidOperationException NetworkResourceNameNotUnique InvalidResult 'Resource' -Message "The provided Resource value is an URI, however a specific Appliance Connection was not provided.  Please specify an Appliance Connection."
						$PSCmdlet.WriteError($ErrorRecord)

					}

					else
					{

						Try
						{

							$_resp = Send-HPOVRequest $_lig -Appliance $ApplianceConnection.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						[void]$_ligcollection.Add($_resp)

					}
					
				}

				# LIG passed is the Name
				elseif (($_lig -is [string]) -and (-not($_lig.startsWith("/rest/")))) 
				{

					"[{0}] Received LIG Name $($_lig)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting LIG object from Get-HPOVLogicalInterconnectGroup" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					Try
					{

						$_lig = Get-HPOVLogicalInterconnectGroup $_lig -ApplianceConnection $ApplianceConnection.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					[void]$_ligcollection.Add($_lig)

				}

				# LIG passed is the object
				elseif ($_lig -is [PSCustomObject] -and ('sas-logical-interconnect-groups','logical-interconnect-groups' -contains $_lig.category)) 
				{
					
					"[{0}] LIG Object provided: $($_lig )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					[void]$_ligcollection.Add($_lig)
				
				}

				elseif ($_lig -is [PSCustomObject] -and ('sas-logical-interconnect-groups','logical-interconnect-groups' -notcontains $_lig.category))
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Resource' -TargetType 'PSObject' -Message "Invalid LIG Parameter: $($_lig )"
					$PSCmdlet.WriteError($ErrorRecord)

				}

			}

		}
		
	}

	End
	{

		"[{0}] Processing $($_ligcollection.count) LIG resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Process LIG Resources
		ForEach ($_lig in $_ligcollection)
		{
		
			if ($PSCmdlet.ShouldProcess($_lig.name,"Remove Logical Interconnect Group from appliance '$($_lig.ApplianceConnection.Name)'")) 
			{

				"[{0}] Removing LIG '$($_lig.name)' from appliance '$($_lig.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					
					if ($force.IsPresent)
					{

						$_lig.uri += "?force=true"

					}

					$_resp = Send-HPOVRequest $_lig.Uri DELETE -Hostname $_lig.ApplianceConnection.Name

					[void]$_taskcollection.Add($_resp)

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

		Return $_taskcollection

	}

}
