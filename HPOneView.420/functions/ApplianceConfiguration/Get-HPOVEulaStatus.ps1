function Get-HPOVEulaStatus 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param
	(

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[Object]$Appliance

	)

	Begin 
	{ 

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		# Need to create temporary Global:ConnectedSessions after validating it doesn't exist for appliance connection being created.
		# otherwise, cmdlet will fail when making call to REstClient and it performs the SSL validation and flag value in SSLChecked property
		# need to do the same with Set-HPOVEulaStatus
		# Check to see if a connection to the appliance exists

		if ($Appliance -is [String])
		{

			if (-not(${Global:ConnectedSessions}.Name -contains $Appliance) -and (-not(${Global:ConnectedSessions} | Where-Object Name -eq $Appliance).SessionID))
			{

				"[{0}] Appliance Session not found. Running FTS sequence?" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Creating temporary Session object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

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
	   
	}

	Process 
	{

		"[{0}] Getting EULA Status from '$($Appliance.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Try
		{

			$_ApplianceEulaStatus = Send-HPOVRequest $ApplianceEulaStatusUri -Hostname $Appliance.Name

			$_EulaStatus = New-Object HPOneView.Appliance.EulaStatus($Appliance.Name, !$_ApplianceEulaStatus)

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		finally
		{

			# Remove Temporary appliance connection
			if ((${Global:ConnectedSessions} | Where-Object Name -eq $Appliance.Name).SessionID -eq 'TemporaryConnection')
			{

				"[{0}] Removing temporary Session object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ConnectedSessions.RemoveConnection($Appliance)

			}

		}
		
	}

	End 
	{ 

		Return $_EulaStatus
	
	}

}
