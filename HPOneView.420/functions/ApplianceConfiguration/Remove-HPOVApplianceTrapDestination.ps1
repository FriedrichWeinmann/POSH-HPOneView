function Remove-HPOVApplianceTrapDestination
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

		$_ResourceCol = New-Object System.Collections.ArrayList

	}

	Process 
	{
		
		if ($InputObject -is [PSCustomObject]) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		}

		if ($InputObject -isnot [HPOneView.Appliance.SnmpV3TrapDestination] -and $InputObject -isnot [HPOneView.Appliance.SnmpV1TrapDestination])
		{

			$ExceptionMessage = "The InputObject is not a supported object type.  Only HPOneView.Appliance.SnmpV1TrapDestination and HPOneView.Appliance.SnmpV1TrapDestination objects are supported."
			$ErrorRecord = New-ErrorRecord HPOneView.Appliance.SnmpResourceException InvalidObjectType InvalidOperation "InputObject" -Message $ExceptionMessage
			$PSCmdlet.WriteError($ErrorRecord)

		}

		$RemoveMessage = "Remove {0} trap destination '{1}'"

		switch ($InputObject.Gettype().FullName)
		{

			'HPOneView.Appliance.SnmpV3TrapDestination'
			{

				"[{0}] SNMPv3 Trap Destination object provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.DestinationAddress | Write-Verbose
				
				$RemoveMessage = $RemoveMessage -f 'SNMPv3', $InputObject.DestinationAddress

			}

			'HPOneView.Appliance.SnmpV1TrapDestination'
			{

				"[{0}] SNMPv1 Trap Destination object provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.DestinationAddress | Write-Verbose
				
				$RemoveMessage = $RemoveMessage -f 'SNMPv1', $InputObject.DestinationAddress

			}

		}

		"[{0}] Object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.Uri | Write-Verbose
		
		if ($PSCmdlet.ShouldProcess($InputObject.ApplianceConnection, $RemoveMessage))
		{   
						
			Try
			{
			
				Send-HPOVRequest -Uri $InputObject.uri -Method DELETE -Hostname $InputObject.ApplianceConnection

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
