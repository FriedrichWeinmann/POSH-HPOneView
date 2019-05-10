function Remove-HPOVServer 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(
	
		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ("uri","name","Server")]
		[object]$InputObject,

		[Parameter (Mandatory = $false)] 
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
		
		$_ServersToRemoveCol = New-Object System.Collections.ArrayList
		$_TaskCollection     = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput -or $InputObject -is [PSCustomObject])
		{

			"[{0}] Processing pipeline input objects." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# "[{0}] Received object: $($InputObject )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($InputObject.category -ne 'server-hardware')
			{

				$ErrorRecord = New-ErrorRecord HPOneView.ServerHardwareResourceException UnsupportedResourceCategory InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "The provided Server object {$($InputObject.name)} is an unsupported object category, '$($InputObject.category)'.  Only 'server-hardware' category objects are supported. please check the Parameter value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			# Throw error that you cannot remove a BL server
			if ($null -ne $InputObject.locationUri -and [RegEx]::Match($InputObject.model,'BL|WS|SY').Success)
			{

				$ErrorRecord = New-ErrorRecord HPOneView.ServerHardwareResourceException CannotRemoveBLServerTypes InvalidOperation 'InputObject' -TargetType 'PSObject' -Message "The provided Server object {$($InputObject.name)} cannot be removed from the appliance, as it is a WS/BL server class.  If you wish to remove a WS/BL server from the appliance, you either physically remove the server from the enclosure or remove the enclosure from the appliance.  Please check the Parameter value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			[void]$_ServersToRemoveCol.Add($InputObject)

		}

		Else
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing {1} appliance connection (of {2})." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

				Try
				{

					"[{0}] Getting '{1}' server from Get-HPOVServer." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject | Write-Verbose

					$_InputObject = Get-HPOVServer -Name $InputObject -ApplianceConnection $_appliance -ErrorAction SilentlyContinue

					[void]$_ServersToRemoveCol.Add($_InputObject)

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

		"[{0}] Processing {1} Server object resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ServersToRemoveCol.count | Write-Verbose

		# Process Storage Resources
		ForEach ($_server in $_ServersToRemoveCol)
		{

			if ($PSCmdlet.ShouldProcess($_server.ApplianceConnection,"Remove Server resource '$($_server.name)' from appliance")) 
			{

				"[{0}] Removing Server resource '{1}' from appliance '{2}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_server.name, $_server.ApplianceConnection | Write-Verbose

				if ($PSboundParameters['force'])
				{

					$_server.uri += "?force=true"

				}

				Try
				{

					Send-HPOVRequest -Uri $_server.Uri -Method DELETE -Hostname $_server.ApplianceConnection

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

	}

}
