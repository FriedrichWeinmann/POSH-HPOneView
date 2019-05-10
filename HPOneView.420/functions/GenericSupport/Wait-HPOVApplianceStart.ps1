function Wait-HPOVApplianceStart 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory)]
		[Alias ('Appliance')] 
		[ValidateNotNullOrEmpty()]
		[string]$Hostname = $null
	
	)

	Begin 
	{
		
		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose 

		if ($Hostname -is [String])
		{

			if (-not(${Global:ConnectedSessions}.Name -contains $Hostname) -and (-not(${Global:ConnectedSessions} | Where-Object Name -eq $Hostname).SessionID))
			{

				"[{0}] Appliance Session not found. Running FTS sequence?" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose 

				"[{0}] Creating temporary Session object" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose 

				$_ApplianceName = $Hostname

				[HPOneView.Appliance.Connection]$Hostname = New-TemporaryConnection $Hostname

                "[{0}] {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Hostname.Name | Write-Verbose 
			
			}

			else # If (${Global:ConnectedSessions}.Name -contains $Appliance)
			{

				"[{0}] Appliance is a string value, lookup connection in global tracker." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[HPOneView.Appliance.Connection]$Hostname = ${Global:ConnectedSessions} | Where-Object Name -eq $Hostname

				"[{0}] Found connection in global tracker: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($Hostname | Out-String) | Write-Verbose

			}
			
		}

		elseif ($Hostname -is [HPOneView.Appliance.Connection])
		{

			"[{0}] Appliance is a Connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($Hostname | Out-String) | Write-Verbose

		}
	
	}

	Process 
	{

		$_SW = New-Object System.Diagnostics.Stopwatch

		$_SW.Start()

		do 
		{
			
			"[{0}] Services not started. Monitoring startup progress" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			$waitRequest  = $Null
			$waitResponse = $Null

			[System.Net.httpWebRequest]$waitRequest = RestClient -uri $ApplianceStartProgressUri -appliance $Hostname.Name
			$waitRequest.Timeout = 10000

			"[{0}] REQUEST: {1} {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $waitRequest.Method, $waitRequest.RequestUri | Write-Verbose

			$i = 0

			foreach ($h in $waitRequest.Headers) 
			{ 
				
				"[{0}] Request Header {1}: {2} = {3}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($i+1), $h, $waitRequest.Headers[$i] | Write-Verbose
				
				$i++ 
			
			}

			try 
			{

				# Get response from appliance
				"[{0}] Getting response..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$waitResponse = $waitRequest.GetResponse()
				[int]$HttpStatusCode = $waitResponse.StatusCode

				"[{0}] Received HTTP\{1} status." -f $MyInvocation.InvocationName.ToString().ToUpper(), [int]$waitResponse.StatusCode | Write-Verbose

				# This will trigger when the GetResponse() does not generate an HTTP Error Code and get trapped by the Catch statement below
				If ($_displayflag) 
				{

					write-host "]"

					# Reset flag so we don't display the Ending brace
					$_displayflag = $False

				}

				# Read the response
				$reader = New-Object System.IO.StreamReader($waitResponse.GetResponseStream())
				$responseJson = $reader.ReadToEnd()
				$reader.Close()

				$resp = ConvertFrom-json $responseJson

				$_ActualPercentComplete = ($resp.completeComponents / $resp.totalComponents) * 100

				$StatusMessage = 'Step2: Resource managers {0} of {1}, {2:##}%' -f $resp.completeComponents, $resp.totalComponents, $_ActualPercentComplete
				
				# Handle the call from -Verbose so Write-Progress does not get borked on display.
				if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
				{ 
					
					"[{0}] Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $StatusMessage | Write-Verbose

				}
				
				else 
				{

					# Display progress-bar
					Write-Progress -activity "Appliance services starting" -Status $StatusMessage -percentComplete ('{0:##}' -f $resp.percentComplete)

				}

				# Not sure this is needed any longer
				# start-sleep -s 2

			}

			# Catch if we haven't received HTTP 200, as we should display a nice message stating services are still beginning to start
			catch [Net.WebException] 
			{

				if ($_.Exception.Message -match 'The remote name could not be resolved')
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($waitResponse) 
				{

					$reader = New-Object System.IO.StreamReader($waitResponse.GetResponseStream())

					$responseJson = $reader.ReadToEnd()

					"[{0}] ERROR RESPONSE: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($responseJson | ConvertFrom-Json | out-string) | Write-Verbose

					"[{0}] Response Status: HTTP\{1} {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [int]$waitResponse.StatusCode, $waitResponse.StatusDescription | Write-Verbose

					foreach ($h in $waitResponse.Headers) 
					{ 
						
						"[{0}] Response Header: {1} = {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $h, $waitResponse.Headers[$i] | Write-Verbose
						
						$i++ 
					
					}

				}

				"[{0}] EXCEPTION CAUGHT! HTTP Status Code: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [int]$waitResponse.StatusCode | Write-Verbose

				# Handle WebExcpetion errors that are not HTTP Status Code 503 or 0, and throw error
				if ([int]$waitResponse.StatusCode -ne 503 -and [int]$waitResponse.StatusCode -ne 0)
				{

					Throw $_.Exception.Message

				}

				Write-Verbose "$($waitResponse| Out-string)"

				# Only want to display this message once.
				if (-not($_displayflag)) 
				{

					Write-host "Waiting for services to Begin starting [" -nonewline

				}

				if (-not ([int]$waitResponse.StatusCode -eq 200)) 
				{

					Write-host "*" -nonewline -ForegroundColor Green

					$_displayflag = $true

					start-sleep -s 5

				}

			}

			finally
			{

				if ($waitResponse -is [System.IDisposable])
				{
					
					$waitResponse.Dispose()

				}

			}
 
			# Timeout after 10 minutes
			if ($_SW.Elapsed.TotalSeconds -ge $ApplianceStartupTimeout)
			{

				$_SW.Stop()

				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.NetworkConnectionException ConnectionWaitTimeoutExceeded OperationTimeout -TargetObject 'Hostname' -Message "Timeout waiting for appliance to respond after restart event.  Verify the appliance is operational and reconnect to the appliance."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			'[{0}] Ending Do Loop: {1}; Percent Complete: {2}; HTTP Status Code: {3}' -f $MyInvocation.InvocationName.ToString().ToUpper(), [Bool]([int]$_ActualPercentComplete -eq 100 -and $HttpStatusCode -eq 200), $resp.percentComplete, $HttpStatusCode | Write-Verbose

		} until ([int]$_ActualPercentComplete -eq 100 -and $HttpStatusCode -eq 200)

		# Remove Temporary appliance connection
		if ((${Global:ConnectedSessions} | Where-Object Name -eq $ApplianceConnection.Name).SessionID -eq 'TemporaryConnection')
		{

			"[{0}] Removing temporary Session object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$ConnectedSessions.RemoveConnection($ApplianceConnection)

		}

	}

	End 
	{

		"[{0}] Web Services have started successfully" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		"[{0}] Pausing 10 seconds to let web services finish their final startup" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		start-sleep -s 10

	}

}
