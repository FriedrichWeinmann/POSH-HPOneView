function Remove-HPOVSnmpV3User
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

   	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[HPOneView.Appliance.SnmpV3User]$InputObject,

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

		$_ResourceCol = New-Object System.Collections.ArrayList

	}

	Process 
	{
		
		if ($InputObject -is [PSCustomObject]) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		}

		"[{0}] SNMPv3 User object provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.Username | Write-Verbose

		$RemoveMessage = "Remove SNMPv3 user '{0}'" -f $InputObject.Username

		if ($PSCmdlet.ShouldProcess($_contact.ApplianceConnection.Name, $RemoveMessage))
		{   
						
			Try
			{
			
				Send-HPOVRequest -Uri $InputObject.uri -Method DELETE -Hostname $InputObject.ApplianceConnection

			}

			Catch
			{

				if ($_.Exception.Message -match "Supplied SNMPv3 user id is invalid. Please provide a valid SNMPv3 User id and retry.")
				{

					$ExceptionMessage = "The SNMPv3 user you are trying to remove is associated with an existing SNMPv3 Trap Destination. Please remove the trap destination prior to attempting to remove the user."
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.SnmpV3UserResourceException InvalidOperation InvalidOperation "InputObject" -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				else
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}				

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
