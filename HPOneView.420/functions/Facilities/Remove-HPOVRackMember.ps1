function Remove-HPOVRackMember
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

   	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[HPOneView.Facilities.RackMember]$InputObject,

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
		
		"[{0}] Begin resource removal process." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		$RemoveMessage = "Remove Rack member '{0}'" -f $InputObject.Name

		if ($PSCmdlet.ShouldProcess($InputObject.RackName, $RemoveMessage))
		{   
						
			Try
			{
				
				# Get Rack resource object, which is what needs to be modified.			
				$Rack = Send-HPOVRequest -Uri $InputObject.RackUri -Hostname $InputObject.ApplianceConnection

				[Array]$Rack.rackMounts = $Rack.rackMounts | Where-Object mountUri -ne $InputObject.Uri
				
				Send-HPOVRequest -Uri $Rack.uri -Method PUT -Body $Rack -Hostname $Rack.ApplianceConnection -addHeader @{'If-Match' = $Rack.eTag}

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

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
