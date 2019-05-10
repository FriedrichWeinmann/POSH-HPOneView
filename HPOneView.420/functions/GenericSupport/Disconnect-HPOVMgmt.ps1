function Disconnect-HPOVMgmt 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding ()]
	Param
	(
	
		[Parameter (Mandatory = $false, ValueFromPipeline, Position = 0)]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance', 'ApplianceSession', 'Hostname')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose
		
		if (-not ($ApplianceConnection))
		{ 
		
			$ExceptionMessage = "No valid logon session available.  Please use Connect-HPOVMgmt to connecto to an appliance, and then use Disconnect-HPOVmgmt to terminate your session."
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoAuthSession ResourceUnavailable 'ApplianceConnection' -Message $ExceptionMessage
			$PSCmdlet.WriteError($ErrorRecord)
			
		}

		$_ConnectionsToProcess = New-Object System.Collections.ArrayList

	}

	Process 
	{	

		ForEach ($_ApplianceConnection in $ApplianceConnection)
		{

			# Check first if the Hostname value is a ConnectionID Integer
			[int]$_tmpValue = 0

			if ([Int]::TryParse($_ApplianceConnection, [ref]$_tmpValue))
			{

				"[{0}] Hostname is ConnectionID {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_tmpValue | Write-Verbose

				[void]$_ConnectionsToProcess.Add((${Global:ConnectedSessions} | Where-Object ConnectionID -eq $_tmpValue))

				"[{0}] Found: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), (${Global:ConnectedSessions} | Where-Object ConnectionID -eq $_tmpValue) | Write-Verbose

			}

			elseif ($_ApplianceConnection -is [String])
			{

				"[{0}] Hostname provide, looking in global connection tracker for connection." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[void]$_ConnectionsToProcess.Add((${Global:ConnectedSessions} | Where-Object Name -eq $_ApplianceConnection))

				"[{0}] Found: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), (${Global:ConnectedSessions} | Where-Object Name -eq $_ApplianceConnection) | Write-Verbose

			}

			elseif ($Null -eq $_ApplianceConnection.SessionID)
			{

				'[{0}] User Session not found in $Global:ConnectedSessions' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ExceptionMessage = "User session for '{0}' not found in library connection tracker (`$Global:ConnectedSessions). Did you accidentially remove it, or have you not created a session to an appliance?" -f $_ApplianceConnection.ToString()
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException UnableToLogoff ObjectNotFound 'ApplianceConnection' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}
		
			else
			{

				"[{0}] Adding Connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ApplianceConnection | Write-Verbose

				[void]$_ConnectionsToProcess.Add($_ApplianceConnection)

			}

		}
		
	}

	End
	{

		For ($c = $_ConnectionsToProcess.Count - 1; $c -ge 0; $c--)
		{

			"[{0}] Processing Connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ConnectionsToProcess[$c].Name | Write-Verbose

			"[{0}] Attempting to logoff user '{1}' from '{2}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ConnectionsToProcess[$c].Username, $_ConnectionsToProcess[$c] | Write-Verbose

			"[{0}] Sending Delete Session ID request" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			try 
			{
			
				$Resp = Send-HPOVRequest -Uri $ApplianceLoginSessionsUri -Method DELETE -Body $_ConnectionsToProcess[$c].SessionId -Hostname $_ConnectionsToProcess[$c]

				"[{0}] Removing connection from global connection tracker" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ConnectedSessions.RemoveConnection($_ConnectionsToProcess[$c])
				
			}
			
			catch
			{
			
				"[{0}]  Unable to complete logoff. Displaying error" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$PSCmdlet.ThrowTerminatingError($_)
			
			}

		}


		if ($ConnectedSessions.Count -eq 1 -and (-not($ConnectedSessions | Where-Object Default)) -and $null -ne $ConnectedSessions[0])
		{

			$ConnectedSessions[0].SetDefault($true)

		}
		
		Return $ConnectedSessions
	
	}

}
