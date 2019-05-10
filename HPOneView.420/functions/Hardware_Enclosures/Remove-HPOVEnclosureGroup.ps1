function Remove-HPOVEnclosureGroup 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default",SupportsShouldProcess,ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("uri", "name", "EnclosureGroup",'Resource')]
		[object]$InputObject,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
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

		$_TaskCollection           = New-Object System.Collections.ArrayList
		$_EnclosureGroupCollection = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		if  ($ApplianceConnection.Count -eq 0)
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoAuthSessionFound InvalidArgument 'ApplianceConnection' -Message 'No ApplianceConnections were found.  Please use Connect-HPOVMgmt to establish an appliance connection.'
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($PipelineInput) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Enclosure Group Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

			If ($InputObject.category -eq 'enclosure-groups')
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType PSObject -Message "The Enclosure Group resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_EnclosureGroupCollection.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType PSObject -Message "The Enclosure Group resource is not an expected category type [$($InputObject.category)].  Allowed resource category type is 'enclosure-groups'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			foreach ($enclosuregroup in $InputObject) 
			{

				# Enclosure passed is a URI
				if (($enclosuregroup -is [String]) -and [System.Uri]::IsWellFormedUriString($enclosure,'Relative')) 
				{

					"[{0}] Received URI: $($enclosuregroup)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting Enclosure Group Object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# // NEED APPLIANCE NAME HERE with If Condition
					Try
					{
						
						$enclosuregroup = Send-HPOVRequest $enclosuregroup -ApplianceConnection $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				# Enclosure passed is the Name
				elseif (($enclosuregroup -is [string]) -and (-not($enclosuregroup.startsWith("/rest")))) 
				{

					"[{0}] Received Enclosure Group Name $($enclosuregroup)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting Enclosure Group object from Get-HPOVEnclosureGroup" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					# // NEED APPLIANCE NAME HERE with If Condition
					Try
					{

						$enclosuregroup = Get-HPOVEnclosureGroup -Name $enclosuregroup -ErrorAction Stop -ApplianceConnection $ApplianceConnection

					}
					

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				# Enclosure passed is an object
				elseif ($enclosuregroup -is [PSCustomObject] -and ($enclosuregroup.category -ieq 'enclosure-groups')) 
				{
					
					"[{0}] Enclosure Group Object provided: $($enclosuregroup )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				}

				else 
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Resource' -TargetType 'PSObject' -Message "Invalid Resource Parameter: $($enclosuregroup )"
					$PSCmdlet.WriteError($ErrorRecord)

				}

				[void]$_EnclosureGroupCollection.Add($enclosuregroup)

			}

		}
		
	}

	End
	{

		"[{0}] Processing $($_EnclosureGroupCollection.count) Enclosure Group resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Process Enclosure Resources
		ForEach ($_enclosuregroup in $_EnclosureGroupCollection)
		{

			if ($PSCmdlet.ShouldProcess($_enclosuregroup.name,"Remove Enclosure Group from appliance '$($_enclosuregroup.ApplianceConnection.Name)'?")) 
			{

				"[{0}] Removing Enclosure Group '$($_enclosuregroup.name)' from appliance '$($_enclosuregroup.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					
					if ($PSBoundParameters['Force'])
					{

						$_enclosuregroup.uri += "?force=true"

					}

					$_resp = Send-HPOVRequest $_enclosuregroup.Uri DELETE -Hostname $_enclosuregroup.ApplianceConnection.Name

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
