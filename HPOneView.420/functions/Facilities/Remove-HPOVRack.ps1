function Remove-HPOVRack
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

   	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
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

			$PipelineInput = $true

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

		$_RackCol        = New-Object System.Collections.ArrayList
		$_TaskCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{
		
		if ($InputObject -is [PSCustomObject]) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Rack Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

			If ('racks' -contains $InputObject.category)
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord HPOneView.RackResourceException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message "The InputObject object resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_RackCol.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord HPOneView.RackResourceException InvalidArgumentValue InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message "The InputObject object resource is not an expected type.  The allowed resource category type is 'racks'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			For ($c = 0; $c -lt $ApplianceConnection.Count; $c++)
			{

				"[{0}] Processing Appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ApplianceConnection[$c].Name, $ApplianceConnection.Count | Write-Verbose

				"[{0}] Processing DataCenter Name {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject | Write-Verbose

				Try
				{

					$_Racks = Get-HPOVRack -Name $InputObject -ApplianceConnection $ApplianceConnection[$c]

					$_Racks | ForEach-Object {

						[void]$_RackCol.Add($_)

					}

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

		foreach ($_rack in $_RackCol) 
		{

			$RemoveMessage = "Remove Rack '{0}'" -f $_rack.Name

			if ($PSCmdlet.ShouldProcess($_rack.ApplianceConnection.Name,$RemoveMessage))
			{   
							
				Try
				{
				
					Send-HPOVRequest -Uri $_rack.uri -Method DELETE -Hostname $_rack.ApplianceConnection.Name -addHeader @{'If-Match' = $_rack.eTag}

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

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
