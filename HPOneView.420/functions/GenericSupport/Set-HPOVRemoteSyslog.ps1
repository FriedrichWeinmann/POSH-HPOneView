function Set-HPOVRemoteSyslog 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param
	(
	
		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Net.IPAddress]$Destination,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[ValidateRange(1,65535)]
		[Int]$Port = 514,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[switch]$SendTestMessage,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('Appliance')]
		[ValidateNotNullOrEmpty()]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection) -and -not(${Global:ConnectedSessions}))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command agian."
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

		$_ColStatus = New-Object System.Collections.ArrayList

	}
	 
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing {1} appliance connection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			$_RemoteSyslogConfig = NewObject -RemoteSyslog
			$_RemoteSyslogConfig.enabled = $true

			switch ($PSBoundParameters.Keys)
			{

				'Destination'
				{
				
					 "[{0}] Setting RemoteSyslog destination to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PSBoundParameters['Destination'] | Write-Verbose

					$_RemoteSyslogConfig.remoteSyslogDestination = $Destination.ToString()
				
				}

				'Port'
				{
				
					"[{0}] Setting RemoteSyslog destination TCP Port to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PSBoundParameters['Port'] | Write-Verbose
				
					$_RemoteSyslogConfig.remoteSyslogPort = $Port.ToString()

				}

				'SendTestMessage'
				{
				
					"[{0}] Will generate a test SysLog entry." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_RemoteSyslogConfig.sendTestLog = $true
				
				}

			}

			Try
			{

				"[{0}] Sending API POST request." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_results = Send-HPOVRequest $RemoteSyslogUri PUT $_RemoteSyslogConfig -Hostname $_appliance.Name
				
			}

			Catch
			{
				
				$_ColStatus

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($PSBoundParameters['Async'])
			{

				$_results

			}

			else
			{

				$_results | Wait-HPOVTaskComplete

			}

		}

	}
	
	End 
	{
	
		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
	}

}
