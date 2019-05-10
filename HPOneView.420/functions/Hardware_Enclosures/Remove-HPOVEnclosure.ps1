function Remove-HPOVEnclosure 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default",SupportsShouldProcess,ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("uri", "name", "Enclosure",'Resource')]
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

		$_TaskCollection      = New-Object System.Collections.ArrayList
		$_EnclosureCollection = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		if ($PipelineInput) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Enclosure Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

			If ($InputObject.category -eq 'enclosures')
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType PSObject -Message "The Network resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_EnclosureCollection.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType PSObject -Message "The Enclosure resource is not an expected category type [$($InputObject.category)].  Allowed resource category type is 'enclosures'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			foreach ($enclosure in $InputObject) 
			{

				# Enclosure passed is a URI
				if (($enclosure -is [String]) -and [System.Uri]::IsWellFormedUriString($enclosure,'Relative')) 
				{

					"[{0}] Received URI: $($enclosures)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting Enclosure Object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# // NEED APPLIANCE NAME HERE with If Condition
					Try
					{

						$enclosure = Send-HPOVRequest $enclosure -ApplianceConnection $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
				
				}

				# Enclosure passed is the Name
				elseif (($enclosure -is [string]) -and (-not($enclosure.startsWith("/rest")))) 
				{

					"[{0}] Received Enclosure Name $($enclosure)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Getting Enclosure object from Get-HPOVEnclosure" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					# // NEED APPLIANCE NAME HERE with If Condition
					Try
					{

						$enclosure = Get-HPOVEnclosure $enclosure -ApplianceConnection $ApplianceConnection

					}
					

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				# Enclosure passed is an object
				elseif ($enclosure -is [PSCustomObject] -and ($enclosure.category -ieq 'enclosures')) 
				{
					
					"[{0}] Enclosure Object provided: $($enclosure )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				}

				else 
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Resource' -TargetType 'PSObject' -Message "Invalid Resource Parameter: $($enclosure )"
					$PSCmdlet.WriteError($ErrorRecord)

				}

				[void]$_EnclosureCollection.Add($enclosure)

			}

		}
		
	}

	End
	{

		"[{0}] Processing $($_EnclosureCollection.count) Enclosure resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Process Enclosure Resources
		ForEach ($_enclosure in $_EnclosureCollection)
		{

			if ($PSCmdlet.ShouldProcess($_enclosure.name,"Remove Enclosure from appliance '$($_enclosure.ApplianceConnection.Name)'")) 
			{

				"[{0}] Removing Enclosure '$($_enclosure.name)' from appliance '$($_enclosure.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					
					if ($PSBoundParameters['Force'])
					{

						$_enclosure.uri += "?force=true"

					}

					$_resp = Send-HPOVRequest $_enclosure.Uri DELETE -Hostname $_enclosure.ApplianceConnection.Name

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
