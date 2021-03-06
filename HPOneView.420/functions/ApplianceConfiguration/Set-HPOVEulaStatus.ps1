﻿function Set-HPOVEulaStatus 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param
	(

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[Object]$Appliance,

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet ('Yes', 'No')]
		[string]$SupportAccess

	)

	Begin 
	{ 

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		# Check to see if a connection to the appliance exists
		if ($Appliance -is [String])
		{

			if (-not(${Global:ConnectedSessions}.Name -contains $Appliance) -and (-not(${Global:ConnectedSessions} | Where-Object Name -eq $Appliance).SessionID))
			{

				"[{0}] Appliance Session not found. Running FTS sequence?" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

				"[{0}] Creating temporary Session object" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

				$_ApplianceName = $Appliance

				[HPOneView.Appliance.Connection]$Appliance = New-TemporaryConnection $Appliance

				"[{0}] {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Appliance.Name | Write-Verbose
			
			}

			else # If (${Global:ConnectedSessions}.Name -contains $Appliance)
			{

				"[{0}] Appliance is a string value, lookup connection in global tracker." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[HPOneView.Appliance.Connection]$Appliance = ${Global:ConnectedSessions} | Where-Object Name -eq $Appliance

				"[{0}] Found connection in global tracker: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($Appliance | Out-String) | Write-Verbose

			}

		}        

		elseif ($Appliance -is [HPOneView.Appliance.Connection])
		{

			"[{0}] Appliance is a Connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($Appliance | Out-String) | Write-Verbose

		}

		else
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException UnknownCondition InvalidOperation "Appliance" -Message "An unknown condition has ocurred."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}
	
	}

	Process 
	{

		$body = [PSCustomObject]@{
			
			supportAccess = $supportAccess
		
		}

		Try
		{

			$_eulastatus = Send-HPOVRequest -Uri $ApplianceEulaSaveUri -Method POST -BOdy $body -Hostname $Appliance

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		Finally
		{

			if ((${Global:ConnectedSessions} | Where-Object Name -eq $Appliance.Name).SessionID -eq 'TemporaryConnection')
			{

				"[{0}] Removing temporary Session object" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

				$ConnectedSessions.RemoveConnection($Appliance)

			}

		}
		
	}

	End 
	{ 
	
		Return $_eulastatus
	
	}

}
