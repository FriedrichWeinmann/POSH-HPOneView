function Send-HPOVRequest 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Position = 0, Mandatory)]
		[ValidateScript ({if ($_.startswith('/')) {$true} else {throw "-URI must being with a '/' (eg. /rest/server-hardware) in its value. Please correct the value and try again."}})]
		[string]$uri,

		[Parameter (Position = 1, Mandatory = $false)]
		[ValidateScript ({if ("GET","POST","DELETE","PATCH","PUT" -match $_) {$true} else { Throw "'$_' is not a valid Method.  Only GET, POST, DELETE, PATCH, or PUT are allowed." }})]
		[string]$method = "GET",
		
		[Parameter (Position = 2, Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[object]$body,

		[Parameter (Position = 3, Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[int]$start = 0,

		[Parameter (Position = 4, Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[int]$count = 0,

		[Parameter (Position = 5, Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[hashtable]$AddHeader,

		[Parameter (Position = 6, Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]$OverrideContentType,

		[Parameter (Position = 7, Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[int]$OverrideTimeout,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance','ApplianceConnection')]
		[Object]$Hostname = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{ 

		"[{0}] BEGIN" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($uri -eq $ApplianceLoginSessionsUri -and $Method -eq 'POST')
		{

			# RedactPassword -BoundParameters $PSBoundParameters

		}

		else
		{

			"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		}

		# Support getting the Appliance Connection Name from the object being passed within the body Param
		if ($PSBoundParameters['body'] -and $body.ApplianceConnection -and (-not($Hostname)) -and ($body -isnot [System.Collections.IEnumerable]))
		{

			"[{0}] Getting the Appliance Connection Name from the object being passed within the body Param" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$Hostname = $body.ApplianceConnection.Name

		}

		# Collection to return all responses from all specified appliance connections
		$AllResponses = New-Object System.Collections.ArrayList

	}

	Process 
	{

		$c = 1

		if (-not($PSboundParameters['Hostname']) -and (-not([bool]($Hostname | Measure-Object).count)))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoAuthSession ObjectNotFound 'Hostname' -Message "No appliance Hostname Parameter provided and no valid appliance session(s) found."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		ForEach ($ApplianceHost in $Hostname) 
		{

			"[{0}] Process" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Hostname value: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($ApplianceHost | Out-String) | Write-Verbose

			# Clear last error response for the connection we are going to make.
			if (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name)
			{

				"[{0}] Prior Global Response Error Object for '{1}' found. Clearing." -f $MyInvocation.InvocationName.ToString().ToUpper(), $ApplianceHost.Name | Write-Verbose

				$_ResponseObject = (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name)

				[void]${Global:ResponseErrorObject}.Remove($_ResponseObject)

			}
			
			# If the value is String, we assume this is the Appliance Hostname, so look up the Connection details in ${Global:ConnectedSessions}
			if ($ApplianceHost -is [String] -and (${Global:ConnectedSessions} | Where-Object Name -eq $ApplianceHost )) 
			{

				"[{0}] Filtering for Connection Object via String: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ApplianceHost | Write-Verbose

				$ApplianceHost = ${Global:ConnectedSessions} | Where-Object Name -eq $ApplianceHost

			}

			elseif ($ApplianceHost -isnot [HPOneView.Appliance.Connection] -and $ApplianceHost.Name)
			{

				"[{0}] Filtering for Connection Object via PSObject: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($ApplianceHost | Out-String) | Write-Verbose

				$ApplianceHost = ${Global:ConnectedSessions} | Where-Object Name -eq $ApplianceHost.Name

			}

			"[{0}] Processing '{1}' appliance connection request. {2} of {3}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ApplianceHost.Name,$c,$Hostname.count | Write-Verbose 

			# Need to check for authenticated session when the URI passed is not value of $WhiteListedURIs
			"[{0}] Requested URI '{1}' to '{2}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $uri, ($ApplianceHost.Name -join ',') | Write-Verbose 

			if ($WhiteListedURIs -contains $uri) 
			{

				"[{0}] We have reached the URI Whitelist condition block. Unauth request allowed for '{1}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $uri | Write-Verbose

			}
				
			# Else, require authentication
			elseif (-not($ApplianceHost.SessionID)) 
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoAuthSession AuthenticationError 'Send-HPOVRequest' -Message "No valid session ID found for '$($ApplianceHost.Name)'.  The call to '$uri' requires authentication.  Please use Connect-HPOVMgmt to connect and authenticate to an appliance."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}
	
			# Pagination handling:
			$AllMembers = New-Object System.Collections.ArrayList

			# See if the caller specified a count, either in the URI or as a Param
			# (if so, we will let them handle pagination manually)
			[bool]$manualPaging = $false

			if ($uri.ToLower().Contains("count=") -or $uri.ToLower().Contains("count =")) 
			{

				$manualPaging = $true

			}

			elseif ($count -gt 0) 
			{

				$manualPaging = $true

				# Add start & count params to the URI
				if (-not ($uri -contains "?")) 
				{

					$uri += "?"    

				}

				$uri += ("start=" + $start + "&")

				$uri += ("count=" + $count)

			}

			elseif ($start -gt 0) 
			{

				# Start specified, but no count -- just set the start Param & auto-page from there on:
				$manualPaging = $false

				if (-not ($uri -contains "?")) 
				{

					$uri += "?"   
				 
				}

				$uri += ("start=" + $start)

			}

			do 
			{

				$_TelemetryStopWatch = [system.diagnostics.stopwatch]::startNew()

				# Used to keep track of async task response
				$taskReceived = $False

				[System.Net.WebRequest]$req = RestClient $method $uri $ApplianceHost.Name

				if ($PSBoundParameters['OverrideContentType'])
				{

					$req.ContentType = $PSBoundParameters['OverrideContentType']

				}

				if ($PSBoundParameters['OverrideTimeout'])
				{

					$req.Timeout = $OverrideTimeout
					
				}

				# Add Auth Session token if it exists                
				if ($ApplianceHost.SessionID -and $ApplianceHost.SessionID -ne 'TemporaryConnection') 
				{ 
					
					$req.Headers.Item("auth") = $ApplianceHost.SessionID 
				
				}

				# Handle additional headers being passed in for updated API (storage volume removal)
				# Variable defined as a hashtable in case other API pass more than one additional header
				if($PSBoundParameters['AddHeader'])
				{

					$AddHeader.GetEnumerator() | ForEach-Object { $req.Headers.Item($_.key) = $_.value }

					if ($AddHeader.GetEnumerator() | Where-Object Key -eq 'X-API-Version')
					{

						"[{0}] Overloading 'X-API-Version' in HttpWebRequest object to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $AddHeader.'X-API-Version' | Write-Verbose
						$req.Headers['X-API-Version'] = $AddHeader.'X-API-Version'

					}

				}

				# Adding due to X-API-Version 500 requirement to pass If-Match header for DELETE requests.
				if ($Method -eq 'DELETE' -and -not $req.Headers.Item('If-Match'))
				{
					
					"[{0}] Adding If-Match HTTP Header." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					[void]$req.Headers.Add("If-Match: *")

				}

				# $Body will contain the certificate object
				if ($Uri -contains $ApplianceLoginSessionsSmartCardAuthUri -and $Method -eq 'POST')
				{

					"[{0}] Initiating SmartCard auth.  Adding client certificate to request object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					[void]$req.ClientCertificates.Add($Body[0])
					$req.UseDefaultCredentials = $true
					
				}

				# Send the request with a messege
				elseif ($body) 
				{

					"[{0}] Body object found. Converting to JSON." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
					if (('PUT','PATCH' -contains $method) -and ($null -ne $body.etag)) 
					{

						"[{0}] HTTP Method is $method and eTag value found $($body.etag).  Setting 'If-Match' HTTP Header." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						# Handle eTags from connection manager
						$req.Headers.Item("If-match") = $body.etag

					}

					# Remove any found ApplianceConnection property(ies) to not generate REST API Error
					if ('PUT', 'PATCH', 'POST' -contains $method -and $body -isnot [System.String])
					{

						"[{0}] HTTP Method is $method. Removing 'ApplianceConnection' NoteProperty from object(s)." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$body = Remove-ApplianceConnection $body

					}

					if ($method -eq "PATCH" -and ($body -isnot [Array]))
					{

						"[{0}] Patch Request and body is not an Array." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						[Array]$body = @($body)

					}
					
					# Create a new stream writer to write the json to the request stream.
					if ($body -isnot [String])
					{

						$js = ConvertTo-Json $body -Depth 99 -Compress

					}

					else
					{

						$js = $body

					}

					# Needed to remove \r character that ConvertTo-JSON adds which /rest/logindirectories does not support for the directory server SSL certificate
					if ($body.type -eq "LoginDomainConfigVersion2Dto") 
					{ 
						
						$js = $js -replace "\\r",$null 
					
					}

					if ($uri -eq $LoginSessionsUri -and $Method -eq 'POST')
					{

						'[{0}] Request Body: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), (ConvertTo-Json -InputObject $_Params.body -Depth 99 -Compress) | Write-Verbose 
					
					}

					else
					{

						"[{0}] Request Body: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $js | Write-Verbose 

					}

					# Send the messege
					try 
					{

						$stream = New-Object IO.StreamWriter($req.GetRequestStream())

						$stream.AutoFlush = $True
						$stream.WriteLine($js)
						$stream.Flush()
						
					}

					catch 
					{                        

						$PSCmdlet.ThrowTerminatingError($_)
						
					}

					finally
					{

						$stream.Close()

						if ($stream -is [System.IDisposable])
						{

							$stream.Dispose()

						}

					}	            

				}				

				"[{0}] Request: {1} https://{2}{3}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $req.Method, $ApplianceHost.Name, $Uri | Write-Verbose
   
				# Write Verbose the headers if needed
				$i = 0

				foreach ($h in $req.Headers) 
				{ 

					# Remove Auth Token info from Headers
					if ($h -eq 'auth')
					{

						"[{0}] Request Header {1}: {2} = [*****REDACTED******]" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($i+1), $h | Write-Verbose

					}

					else
					{

						"[{0}] Request Header {1}: {2} = {3}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($i+1), $h, $req.Headers[$i] | Write-Verbose

					}

					$i++ 

				}

				try 
				{

					# Get response from appliance
					[System.Net.WebResponse]$LastWebResponse = $req.GetResponse()

					$_TelemetryStopWatch.Stop()

					"[{0}] Response time: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_TelemetryStopWatch.Elapsed.ToString() | Write-Verbose

					# Display the response status if verbose output is requested
					"[{0}] Response Status: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), [int]$LastWebResponse.StatusCode, [String]$LastWebResponse.StatusDescription | Write-Verbose

					$i = 0

					foreach ($h in $LastWebResponse.Headers) 
					{ 
						
						"[{0}] Response Header {1}: {2} = {3}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($i+1), $h, $LastWebResponse.Headers[$i] | Write-Verbose
						
						$i++ 
					
					}

					# Read the response
					$reader = New-Object IO.StreamReader($LastWebResponse.GetResponseStream())

					$FinalResponse = $reader.ReadToEnd()

					$reader.close()

					"[{0}] FinalResponse: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $FinalResponse | Write-Verbose

					# $DuplicateiLOPattern = '\"[I|i]LO\"\:\[\"\d\.\d+\"\],'
					$DuplicateiLOPattern = '\"[I|i]LO\"\:\[[null\,]*\"\d\.\d+\"\][,]?'

					if ([RegEx]::Matches($FinalResponse, $DuplicateiLOPattern, 'IgnoreCase'))
					{

						$FinalResponse = [Regex]::Replace($FinalResponse, $DuplicateiLOPattern, "")

					}

					$resp = ConvertFrom-JSON -InputObject $FinalResponse

					if ($resp -is [String])
					{

						"[{0}] Response: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $resp | Write-Verbose 

					}

					elseif ($resp -is [Boolean])
					{

						"[{0}] Bool Response: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [bool]$resp | Write-Verbose 

					}

					else
					{

						if ($resp -is [PSCustomObject])
						{

							if ($resp.PSobject.Properties.name -match "sessionId")
							{

								$_resp = $resp.PSObject.Copy()

								$_resp.sessionId = '[*****REDACTED******]'

								"[{0}] Response: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_resp | Format-List * -force | out-string) | Write-Verbose 

							}

						}

						else
						{

							"[{0}] Response: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($resp | Format-List * -force | out-string) | Write-Verbose 

						}

					}
					
					"[{0}] Manual Pagination: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ManualPaging | Write-Verbose

					# If Asyncronous (HTTP status=202), make sure we return a Task object:
					if ([int]$LastWebResponse.StatusCode -eq 202 -and ($LastWebResponse.Headers.Item('X-Task-URI') -or $LastWebResponse.Headers.Item('Location')))
					{

						"[{0}] Async Task (HTTP 202) received"-f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						# AsynchronOut operation -- in some cases we get the Task object returned in the body.
						# In other cases, we only get the Task URI in the Location header.
						# In either case, return a Task object with as much information as we know
						if ($LastWebResponse.Headers.Item('X-Task-URI')) 
						{

							[string]$TaskUri = $LastWebResponse.Headers.Item('X-Task-URI')

						}

						elseif ($LastWebResponse.Headers.Item('Location'))
						{

							[string]$TaskUri = $LastWebResponse.Headers.Item('Location')

						}

						if ($TaskUri)
						{

							"[{0}] Async Task URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $TaskUri | Write-Verbose

							# First, make sure the task URI is relative:
							$pos = $TaskUri.IndexOf($TasksUri)

							if ($pos -gt 0) 
							{

								$TaskUri = $taskUri.SubString($pos)

							}

							Try
							{

								$resp = Send-HPOVRequest -uri $TaskUri -method GET -appliance $ApplianceHost.Name

								"[{0}] Adding 'HPOneView.Appliance.TaskResource' to PSObject TypeNames for task object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

								$resp | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.TaskResource') }

							}
							
							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)
								
							}

						}

					}

					elseif ([int]$LastWebResponse.StatusCode -eq 202)
					{

						"[{0}] Return is not an Async task, but HTTP 202 was returned. Labels?" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						if ($Method -eq 'DELETE' -and $null -eq $resp)
						{

							"[{0}] Returning custom delete successful message." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$resp = [PSCustomObject]@{StatusCode = [int]$LastWebResponse.StatusCode; Message = "Resource deleted successfully." }

						}						

					}

					# Handle Task Objects that have been directly accessed via task URI and not created async tasks (HTTP 202)
					if (([int]$LastWebResponse.StatusCode -eq 200 -or [int]$LastWebResponse.StatusCode -eq 202) -and ($resp.category -eq "tasks") -and (-not($resp.PSObject.TypeNames -match "HPOneView.Appliance.TaskResource"))) 
					{
						
						$resp | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.TaskResource') }

					}

					# User Logoff success message
					if (([int]$LastWebResponse.StatusCode -eq 204) -and ($uri -eq $ApplianceLoginSessionsUri))
					{

						$resp = [PSCustomObject]@{ Message = "User logoff successful." }

					}

					elseif (([int]$LastWebResponse.StatusCode -eq 204 -or [int]$LastWebResponse.StatusCode -eq 200) -and $method -eq "DELETE")
					{
						
						$resp = [PSCustomObject]@{StatusCode = [int]$LastWebResponse.StatusCode; Message = "Resource deleted successfully." }
						
					}

					# Handle multi-page result sets
					if ([bool]($resp | Get-Member -Name members -ErrorAction SilentlyContinue) -and (-not($manualPaging))) 
					{

						 "[{0}] Response members and automatic pagination" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$resp.members | ForEach-Object { 
							
							Add-Member -InputObject $_ -NotePropertyName ApplianceConnection -NotePropertyValue (New-Object HPOneView.Library.ApplianceConnection($ApplianceHost.Name, $ApplianceHost.ConnectionId)) -Force 

							[void]$AllMembers.Add($_) 
						
						}

						"[{0}] total stored '$($AllMembers.count)'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						"[{0}] nextPageURI: '$($AllMembers.nextPageUri)'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						if ($resp.nextPageUri) 
						{ 

							"[{0}] Pagination has occurred. Received $($resp.count) resources of $($resp.total)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$uri = $resp.nextPageUri

						}

						else 
						{ 

							"[{0}] Reached End of pagination. Building AllResults" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$_AllResults = [PsCustomObject]@{
								
								members     = $AllMembers; 
								count       = $AllMembers.Count;
								total       = $AllMembers.Count;
								category    = $resp.category; 
								eTag        = $resp.eTag;
								nextPageUri = $resp.nextPageUri;
								start		= $resp.start;
								prevPageUri	= $resp.prevPageUri;
								created		= $resp.created;
								modified	= $resp.modified;
								uri			= $resp.uri
							
							}

							[void]$AllResponses.Add($_AllResults)
							
						}

					}
					
					elseif ($resp.members -and $manualPaging )
					{

						"[{0}] Response members and manual paging" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$resp.members | ForEach-Object { 

							Add-Member -InputObject $_ -NotePropertyName ApplianceConnection -NotePropertyValue (New-Object HPOneView.Library.ApplianceConnection($ApplianceHost.Name, $ApplianceHost.ConnectionId)) -Force 

						}

						[void]$AllResponses.Add($resp)

					}

					elseif ($resp)
					{

						"[{0}] Response object, no paging needed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Add-Member -InputObject $resp -NotePropertyName ApplianceConnection -NotePropertyValue (New-Object HPOneView.Library.ApplianceConnection($ApplianceHost.Name, $ApplianceHost.ConnectionId)) -Force 

						[void]$AllResponses.Add($resp)

					}

				}

				catch [System.Net.WebException] 
				{ 

					"[{0}] Net.WebException Error caught" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] Exception Object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_ | Format-List * -force | Out-String) | Write-Verbose

					"[{0}] Exception Message: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_.Exception.Message | Write-Verbose

					"[{0}] InnerException FullyQualifiedErrorId: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_.Exception.InnerException.FullyQualifiedErrorId | Write-Verbose
					
					"[{0}] InnerException Message: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_.Exception.InnerException.Message | Write-Verbose

					if ($_.Exception.InnerException.FullyQualifiedErrorId -eq "ApplianceTransportException")
					{

						$ExceptionMessage = "Unable to connect to '{0}' appliance.  {1}" -f $ApplianceHost.Name, $_.Exception.InnerException.Message
                        $ErrorRecord = New-ErrorRecord HPOneView.Library.ApplianceTransportException HostnameAndCertDoNotMatch ResourceUnavailable 'Hostname' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					elseif ($_.Exception.InnerException -match "System.Net.WebException: Unable to connect to the remote server") 
					{ 
					
						$ExceptionMessage = "Unable to connect to '{0}' due to timeout." -f $ApplianceHost.Name
						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.NetworkConnectionException ApplianceNotResponding ResourceUnavailable 'Hostname' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}
					
					elseif ($_.Exception.Message -match 'The remote name could not be resolved')
					{

						$ExceptionMessage = "Unable to connect to the appliance.  {0}" -f $_.Exception.Message
						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.NetworkConnectionException RemoteNameLookupFailure ObjectNotFound 'Hostname' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if ($_.Exception.InnerException) 
					{

						if ($_.Exception.InnerException.Response) 
						{

							"[{0}] InnerException" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$LastWebResponse = $_.Exception.InnerException.Response

						}

						else 
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					} 
				
					else 
					{

						if ($_.Exception.Response) 
						{

							"[{0}] Exception" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$LastWebResponse = $_.Exception.Response

						}

						else 
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

					if ($LastWebResponse) 
					{

						Try
						{

							"[{0}] Getting Error Response" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						
							$reader = New-Object IO.StreamReader($LastWebResponse.GetResponseStream())

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						$_JsonErrorResponse = $reader.ReadToEnd() 
						$ErrorResponse = ConvertFrom-JSON -InputObject $_JsonErrorResponse

						$reader.Close()		

						"[{0}] ERROR RESPONSE: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_JsonErrorResponse | Write-Verbose

						# Set Global Response Error Object
						if (-not(${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name))
						{
						
							$_NewResponseErrorObject = [PSCustomObject]@{

								Name            = $ApplianceHost.Name
								LastWebResponse = $LastWebResponse
								ErrorResponse   = $ErrorResponse

							}

							[void]${Global:ResponseErrorObject}.Add($_NewResponseErrorObject)
						
						}

						else
						{

							(${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).LastWebResponse = $LastWebResponse
							(${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse   = $ErrorResponse

						}                       
						
						"[{0}] Response Status: HTTP $([int](${Global:ResponseErrorObject} | ? Name -eq $ApplianceHost.Name).LastWebResponse.StatusCode) [$((${Global:ResponseErrorObject} | ? Name -eq $ApplianceHost.Name).LastWebResponse.StatusDescription)]" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						foreach ($h in (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).LastWebResponse.Headers) 
						{ 
							
							"[{0}] Response Header: $($h) = $((${Global:ResponseErrorObject} | ? Name -eq $ApplianceHost.Name).LastWebResponse.Headers[$i])" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							
							$i++ 
						
						}

						switch ([int](${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).LastWebResponse.StatusCode) 
						{

							# HTTP 400 errors
							400 
							{
								
								"[{0}] HTTP 400 error caught." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								if ([System.String]::IsNullOrWhiteSpace(($Global:ResponseErrorObject | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.details))
								{

									$_Message = "{0} {1} " -f ($Global:ResponseErrorObject | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.message, ([String]::Join(' ',($global:ResponseErrorObject | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.recommEndedActions)).trim()

								}

								else
								{

									$_Message = "{0} {1} " -f ($Global:ResponseErrorObject | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.details, ([String]::Join(' ',($global:ResponseErrorObject | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.recommEndedActions)).trim()

								}

								switch ((${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorCode)
								{

									'DEVICE_NOT_ELIGIBLE'
									{

										$ExceptionMessage = "The device is not eligible."
										$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportResourceException DeviceNotEligible InvalidOperation "Server" -Message $ExceptionMessage
										$PSCmdlet.ThrowTerminatingError($ErrorRecord)

									}

									# Hande initial authentication errors
									{"AUTHN_AUTH_DIR_FAIL","AUTHN_AUTH_FAIL" -contains $_}
									{
									
										"[{0}] Authentication Directory failure.  Likely basd username and/or password from auth dir." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

										$ConnectedSessions.RemoveConnection($ApplianceHost)
										
										$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AuthSessionException InvalidUsernameOrPassword AuthenticationError "Appliance:$($ApplianceHost.Name)" -Message $_Message
										$PSCmdlet.ThrowTerminatingError($ErrorRecord)

									}

									# Handle invalid user session
									"AUTHN_LOGOUT_FAILED"
									{

										"[{0}] User session no longer valid, likely due to session timeout. Clearing library runtime global and script variables." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

										$ConnectedSessions.RemoveConnection($ApplianceHost)

										$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AuthSessionException InvalidUserSession AuthenticationError "Appliance:$($ApplianceHost.Name)" -Message $_Message
										Throw $ErrorRecord

									}

									# Handle user not acknowledging login message
									"AUTHN_LOGIN_MESSAGE_ACKNOWLEDGMENT_REQUIRED"
									{

										"[{0}] User needed to accept the Login Message." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

										$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AuthSessionException LoginMessageAcknowledgementRequired AuthenticationError "Appliance:$($ApplianceHost.Name)" -Message $_Message
										Throw $ErrorRecord

									}

									# Valid user, but does not belong to a group that has an assigned role
									'AUTHN_AUTH_FAIL_NO_ROLES'
									{

										$ConnectedSessions.RemoveConnection($ApplianceHost)

										$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AuthSessionException NoDirectoryRoleMapping AuthenticationError "Appliance:$($ApplianceHost.Name)" -Message $_Message 
										$PSCmdlet.ThrowTerminatingError($ErrorRecord)

									}

									# Valid User, but no directory group have been added
									'AUTHN_LOGINDOMAIN_NO_MEMBER_GROUPS_FOUND'
									{

										$ConnectedSessions.RemoveConnection($ApplianceHost)

										$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AuthSessionException NoDirectoryRoleMapping AuthenticationError "Appliance:$($ApplianceHost.Name)" -Message $_Message 
										$PSCmdlet.ThrowTerminatingError($ErrorRecord)

									}

									default
									{

										if ((${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorSource) 
										{ 
										
											$source = (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorSource 
									
										}

										else 
										{ 
										
											$source = 'Send-HPOVRequest' 
									
										}

										$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidOperation InvalidOperation $source -Message $_Message
										$PSCmdlet.ThrowTerminatingError($ErrorRecord)

									}

								}

							}

							# User is unauthorized
							401 
							{

								"[{0}] HTTP 401 error caught." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
								
								if ((${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.details -cmatch "User not authorized for this operation" -or (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.message -cmatch "insufficient privilege for operation") 
								{

									"[{0}] $((${Global:ResponseErrorObject} | ? Name -eq $ApplianceHost.Name).ErrorResponse.message) Request was '$method' at '$uri'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

									$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthPrivilegeException InsufficientPrivilege AuthenticationError 'Send-HPOVRequest' -Message ("[Send-HPOVRequest]: {0}.  Request was '{1}' at '{2}'. " -f (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.message, $method, $uri )
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								elseif ((${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorCode -eq "INSUFFICIENT_PRIVILEGES") 
								{

									"[{0}] $((${Global:ResponseErrorObject} | ? Name -eq $ApplianceHost.Name).ErrorResponse.message) Request was '$method' at '$uri'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

									$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthPrivilegeException InsufficientPrivilege AuthenticationError 'Send-HPOVRequest' -Message ("[Send-HPOVRequest]: {0}.  Request was '{1}' at '{2}'. " -f (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.message, $method, $uri )
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								elseif ((${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorCode -eq "INVALID_REPOSITORY_CREDENTIALS") 
								{

									"[{0}] $((${Global:ResponseErrorObject} | ? Name -eq $ApplianceHost.Name).ErrorResponse.message) Request was '$method' at '$uri'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

									$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthPrivilegeException ExternalRepositoryCredentials AuthenticationError $Caller -Message ("{0}" -f (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.message)
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								elseif ((${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorCode -eq "AlertAuthorizationException") 
								{

									"[{0}] $((${Global:ResponseErrorObject} | ? Name -eq $ApplianceHost.Name).ErrorResponse.message) Request was '$method' at '$uri'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

									$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthPrivilegeException AlertAuthorizationException AuthenticationError 'Send-HPOVRequest' -Message ("[Send-HPOVRequest]: {0}.  Request was '{1}' at '{2}'. " -f (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.message, $method, $uri )
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								else 
								{

									$ConnectedSessions.RemoveConnection($ApplianceHost)

									$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException InvalidOrTimedoutSession AuthenticationError 'Send-HPOVRequest' -Message "[Send-HPOVRequest]: Your session has timed out or is not valid. Please use Connect-HPOVMgmt to authenticate to your appliance."
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

							}

							403 
							{
								
								$resp = $Null

								if ((${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorCode -eq "PASSWORD_CHANGE_REQUIRED") 
								{ 
									
									$ErrorRecord = New-ErrorRecord HPOneview.Appliance.PasswordChangeRequired PasswordExpired PermissionDenied "URI" -Message ((${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.message + " " + (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.recommEndedActions) 
								
								}
								
								else 
								{ 
									
									$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ResourcePrivledgeException ResourcePrivledge PermissionDenied "URI" -Message ((${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.message + " " + (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.recommEndedActions) 
								
								}

								Throw $ErrorRecord

							}

							404 
							{
								
								if ((${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorCode -eq 'CHANNEL_PARTNER_VALIDATION_FAILED')
								{

									$_ExceptionMessage = (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.message
									$ErrorRecord = New-ErrorRecord HPOneview.ResourceNotFoundException ChannelPartnerNotFound ObjectNotFound 'ID' -Message $_ExceptionMessage

								} 
								
								else
								{

									$ErrorRecord = New-ErrorRecord HPOneview.ResourceNotFoundException ResourceNotFound ObjectNotFound "URI" -Message ("The requested resource '$uri' could not be found. " + (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.recommendedActions)

								}

								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}
						
							405 
							{
						
								$ErrorRecord = New-ErrorRecord InvalidOperationException (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorCode InvalidOperation "$($Method):$($uri)" -Message ("[Send-HPOVRequest]: The requested HTTP method is not valid/supported.  " + (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.details + " URI: $uri")
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

							{ @(409, 412) -contains $_ } 
							{
						
								$ErrorRecord = New-ErrorRecord InvalidOperationException $(${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorCode InvalidOperation 'Send-HPOVRequest' -Message ("[Send-HPOVRequest]: $((${Global:ResponseErrorObject} | ? Name -eq $ApplianceHost.Name).ErrorResponse.message) $((${Global:ResponseErrorObject} | ? Name -eq $ApplianceHost.Name).ErrorResponse.recommEndedActions)")
								Throw $ErrorRecord

							}

							500 
							{

								if ((${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.details) 
								{ 
									
									$message = (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.details 
								
								}

								else 
								{ 
									
									$message = (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.message 
								
								}
								
								if (-not($message.SubString($message.length - 1) -eq ".")) { $message += "." }
								
								$ErrorRecord = New-ErrorRecord InvalidOperationException $(${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorCode InvalidOperation 'Send-HPOVRequest' -Message ("[Send-HPOVRequest]: $message $((${Global:ResponseErrorObject} | ? Name -eq $ApplianceHost.Name).ErrorResponse.recommEndedActions)") #-InnerException $global:ResponseErrorObject
								Throw $ErrorRecord

							}

							# Wait for appliance startup here by calling Wait-HPOVApplianceStart
							{ @(503, 0) -contains $_ } 
							{
								
								"[{0}] HTTP $([int]$LastWebResponse.StatusCode) error caught." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								"[{0}] Calling Wait-HPOVApplianceStart" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								Try
								{

									Wait-HPOVApplianceStart -Appliance $ApplianceHost.Name

								}

								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}
								

								# Appliance startup should have finished.
								"[{0}] Returning caller back to: $($method.ToUpper()) $uri" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								if ($addHeader) 
								{ 
									
									return (Send-HPOVRequest -uri $uri -method $method -body $body -addHeader $addHeader -Hostname $ApplianceHost.Name) 
								
								}

								elseif ($body)
								{

									return (Send-HPOVRequest -uri $uri -method $method -body $body -Hostname $ApplianceHost.Name) 

								}

								else 
								{ 
									
									return (Send-HPOVRequest -uri $uri -method $method -Hostname $ApplianceHost.Name) 

								}

							}

							501 
							{

								$ErrorRecord = New-ErrorRecord InvalidOperationException (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.errorCode SyntaxError 'Send-HPOVRequest' -Message ("[Send-HPOVRequest]: " + (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.message + " " + (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.recommEndedActions) -InnerException (${Global:ResponseErrorObject} | Where-Object Name -eq $ApplianceHost.Name).ErrorResponse.details
								Throw $ErrorRecord

							}
							
						} 

					}

					else 
					{

						"[{0}] No Exception Response Object to return." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						return $null

					}

				}

				finally
				{

					"[{0}] Cleaning up HttpWebRequest" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					if ($reader) { $reader.Close() }

					if ($LastWebResponse)
					{
						
						$LastWebResponse.Close()

						if ($LastWebResponse -is [System.IDisposable])
						{

							$LastWebResponse.Dispose()

						}

					}

					if ($req) 
					{ 

						if ($req -is [System.IDisposable])
						{

							$req.Dispose()

						}

					}

					$req = $null

				}

				"[{0}] Does nextPageUri member exist: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [bool]($resp | Get-Member -Name nextPageUri -ErrorAction SilentlyContinue) | Write-Verbose
				"[{0}] Is nextPageUri Null or Empty: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [string]::IsNullOrEmpty($resp.nextPageUri) | Write-Verbose

				$_Stop = $False

				# Always stop if manual paging
				if ($ManualPaging)
				{

					'[{0}] Stopping Do/Until loop because of manual paging' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_Stop = $True

				}

				# If not manual paging and nextPageUri doesn't exist, stop
				elseif (-not($ManualPaging) -and -not([bool]($resp | Get-Member -Name nextPageUri -ErrorAction SilentlyContinue)))
				{

					"[{0}] Stopping Do/Until loop because nextPageUri doesn't exist and have received all objects." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_Stop = $True

				}

				# If not manual paging, nextPageUri exists and it is null or empty
				elseif (-not($ManualPaging) -and ([bool]($resp | Get-Member -Name nextPageUri -ErrorAction SilentlyContinue)) -and [string]::IsNullOrEmpty($resp.nextPageUri))
				{
				
					"[{0}] Stopping Do/Until loop because nextPageUri is null/empty and have received all objects." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_Stop = $True
				
				}

			} until ($_Stop)

			$c++

		} # Continue with next appliance

	}

	End 
	{

		"[{0}] End" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Return $AllResponses

	}

}
