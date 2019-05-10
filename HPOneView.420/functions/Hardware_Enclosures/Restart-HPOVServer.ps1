function Restart-HPOVServer
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Default')]
	Param 
	(
	
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'ColdBoot')]
		[ValidateNotNullOrEmpty()]
		[object]$Server,
		
		[Parameter (Mandatory, ParameterSetName = 'ColdBoot')]
		[switch]$ColdBoot,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'ColdBoot')]
		[switch]$Async,
		
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'ColdBoot')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['Server']))
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

		$_PowerControl = if ($PSBoundParameters['ColdBoot'])
		{

			 'ColdBoot'

		}

		else
		{

			'Reset'

		}
		
		$_PowerState   = 'On'

		$_ServerPowerControlCol = New-Object System.Collections.ArrayList

	}
	
	Process 
	{

		# Checking if the input is PSCustomObject, and the category type is server-profiles, which could be passed via pipeline input
		if (($server -is [System.Management.Automation.PSCustomObject]) -and ($server.category -ieq "server-hardware")) 
		{

			"[{0}] Server is a Server Device object: $($server.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_uri = $server.uri
		
		}

		# Checking if the input is PSCustomObject, and the category type is server-hardware, which would be passed via pipeline input
		elseif (($server -is [System.Management.Automation.PSCustomObject]) -and ($server.category -ieq $ResourceCategoryEnum.ServerProfile) -and ($server.serverHardwareUri)) 
		{
			
			"[{0}] Server is a Server Profile object: $($server.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Getting server hardware device assigned to Server Profile." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_uri = $server.serverHardwareUri
		
		}

		else 
		{

			if (-not($server.serverHardwareUri))
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException ServerProfileUnassigned InvalidArgument 'Server' -TargetType $Server.GetType().Name -Message "The Server Profile '$($Server.name)' is unassigned.  This cmdlet only supports Server Profiles that are assigned to Server Hardware resources. Please check the input object and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Server' -TargetType $Server.GetType().Name -Message "The Parameter 'Server' value is invalid.  Please validate the 'Server' Parameter value you passed and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}            

		}

		# Validate the server power state and lock
		Try
		{

			$_serverObj = Send-HPOVRequest $_uri -appliance $ApplianceConnection.Name

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}
		
		# Need to add confirm prompt here.
		if (($_serverObj.powerState -ine 'Off' -and (-not($_serverObj.powerLock)))) 
		{
		
			if ($PSCmdlet.ShouldProcess($_serverObj.name,'Restart server resource'))
			{

				"[{0}] Set Server '{1}' to desired Power State '{2}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_serverObj.name, $_PowerState | Write-Verbose
	   
				$_uri = $_serverObj.uri + "/powerState"
				
				$body = [pscustomobject]@{
			
					powerState   = $_PowerState;
					powerControl = $_PowerControl
			
				}
		
				Try
				{

					$_resp = Send-HPOVRequest $_uri PUT $body -Hostname $_serverObj.ApplianceConnection.Name
					
					if (-not($PSBoundParameters['Async']))
					{

						$_resp = Wait-HPOVTaskComplete $_resp

					}

				}
		
				Catch
				{
		
					$PSCmdlet.ThrowTerminatingError($_)
		
				}

				[void]$_ServerPowerControlCol.Add($_resp)

			}

			elseif ($PSBoundParameters['WhatIf'])
			{

				"[{0}] -WhatIf scenario." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			else
			{

				"[{0}] User cancelled oepration by choosing No." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}
						
		}
	
		else 
		{ 
		
			$_Message = $null

			if ($serverPowerState.powerState -ieq $_PowerState) 
			{
				
				 $_Message = "Requested Power State '{0}' is the same value as the current Server Power State '{0}'.  "  -f $_PowerState
			
			}

			if ($serverPowerState.powerLock) 
			{ 
				
				$_Message += "Server is currently under Power Lock."  
			
			}

			if ($errorMessage) 
			{ 
			
				$_ErrorRecord = New-ErrorRecord HPOneView.InvalidServerPowerControlException InvalidServerPowerControlOpertion InvalidOperation 'Server' -TargetType 'PSObject' $_Message
				$PSCmdlet.WriteError($_ErrorRecord)
			
			}
		
		}
	
	}

	End
	{

		Return $_ServerPowerControlCol

	}

}
