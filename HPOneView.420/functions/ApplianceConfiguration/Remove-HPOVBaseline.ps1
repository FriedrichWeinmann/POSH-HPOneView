function Remove-HPOVBaseline
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ("b",'Baseline')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ValueFromPipeline)]
		[switch]$Force,
	
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
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

		$_TaskCollection     = New-Object System.Collections.ArrayList
		$_BaselineCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput -or $InputObject -is [PSCustomObject]) 
		{ 

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Baseline provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.FileName, $InputObject.uri | Write-Verbose

			If ($InputObject.category -eq 'firmware-drivers')
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "Baseline:$($InputObject.Name)" -TargetType PSObject -Message "The Baseline resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_BaselineCollection.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "Baseline:$($Baseline.Name)" -TargetType PSObject -Message "The Baseline resource is not an expected category type [$($Baseline.category)].  Allowed resource category type is 'firmware-drivers'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}
		
		}

		else 
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing Appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

				"[{0}] Processing Baseline Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject | Write-Verbose 

				if ($InputObject -is [String])
				{

					Try
					{

						$BaselineName = $InputObject.Clone()
						$InputObject = Get-HPOVBaseline  -File $_HotFix -ApplianceConnection $_appliance -ErrorAction SilentlyContinue

						If (-not $_HotFix)
						{

							$ExceptionMessage = "The provided Baseline '{0}' was not found." -f $BaselineName
							$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'Baseline' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)					

					}

				}
				
				$InputObject | ForEach-Object {

					[void]$_BaselineCollection.Add($_)

				}

			}

		}
		
	}

	End
	{

		"[{0}] Processing $($_BaselineCollection.count) Baseline resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Process Directory Resources
		ForEach ($_Baseline in $_BaselineCollection)
		{

			if ($PSCmdlet.ShouldProcess($_Baseline.ApplianceConnection.Name,"remove baseline '$($_Baseline.name)'")) 
			{

				"[{0}] Removing Baseline '$($_Baseline.name)' from appliance '$($_Baseline.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_Uri = $_Baseline.Uri

				if ($Force)
				{

					$_Uri += '?force=true'

				}

				Try
				{
					
					Send-HPOVRequest -Uri $_Uri -Method DELETE -Hostname $_Baseline.ApplianceConnection.Name

					# [void]$_TaskCollection.Add($_resp)

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

		# Return $_TaskCollection

	}

}
