function Download-File 
{

	<#
		.DESCRIPTION
		Helper function to download files from appliance.  
					
		.Parameter uri
		The location where the Support Dump or backup will be downloaded from
			
		.Parameter SaveLocation
		The full path to where the Support Dump or backup will be saved to.  This path will not be validated in this helper function

		.Parameter ApplianceConnection
		The Appliance Connection Object, Name or ConnectionID

		.INPUTS
		None.  You cannot pipe objects to this cmdlet.
					
		.OUTPUTS
		Downloads the requested file using net.WebRequest

		.EXAMPLE
		PS C:\> Download-File /rest/appliance/support-dumps/ci5401AB76-CI-2013_09_04-04_52_00.014786.sdmp -ApplianceConnection MyAppliance.domain.com c:\temp
			
	#>

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$uri,
		
		[Parameter (Mandatory)]
		[ValidateNotNullorEmpty()]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory)]
		[Alias ("save")]
		[ValidateNotNullOrEmpty()]
		[string]$SaveLocation

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection -is [HPOneView.Appliance.Connection]) -and (-not($ApplianceConnection -is [System.String])))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException InvalidApplianceConnectionDataType InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter is not type [HPOneView.Appliance.Connection] or [System.String].  Please correct this value and try again.'
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif  ($ApplianceConnection.Count -gt 1)
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException MultipleApplianceConnections InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter contains multiple Appliance Connections.  This CMDLET only supports 1 Appliance Connection in the ApplianceConnect Parameter value.  Please correct this and try again.'
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		else
		{

			Try 
			{
	
				$ApplianceConnection = Test-HPOVAuth $ApplianceConnection

			}

			Catch [HPOneview.Appliance.AuthSessionException] 
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError 'ApplianceConnection' -TargetType $ApplianceConnection.GetType().Name -Message $_.Exception.Message -InnerException $_.Exception
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

	}

	Process 
	{

		$_downloadfilestatus = NewObject -DownloadFileStatus
	
		$fsCreate = [System.IO.FileAccess]::Create
		$fsWrite = [System.IO.FileAccess]::Write

		"[{0}] Download URI: $uri" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		[System.Net.ServicePointManager]::UseNagleAlgorithm = $false
		[System.Net.httpWebRequest]$_fileDownload           = RestClient GET $uri $ApplianceConnection.Name
		$_fileDownload.Headers.Item('Accept-Encoding')      = 'gzip, deflate'
		$_fileDownload.accept                               = "application/zip,application/octet-stream,*/*"
		$_fileDownload.Headers.Item("auth")                 = $ApplianceConnection.SessionID

		$i = 0

		ForEach ($_h in $_fileDownload.Headers) 
		{
			
			"[{0}] Request Header $($i): $($_h) = $($_fileDownload.Headers[$i])" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			$i++
		
		}
			
		"[{0}] Request: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_fileDownload | Write-Verbose
		
		Try
		{

			# Get response
			"[{0}] Getting response" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			[Net.httpWebResponse]$_rs = $_fileDownload.GetResponse()

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		Finally
		{

			if ($rs)
			{

				$_rs.Close()

			}

		}        

		# Display the response status if verbose output is requested
		"[{0}] Response Status: $([int]$_rs.StatusCode) $($_rs.StatusDescription)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		$i = 0

		ForEach ($_h in $_rs.Headers) 
		{ 
			
			"[{0}] Response Header $($i): $($_h) = $($_rs.Headers[$i])" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			$i++ 
		
		}

		# Request is a redirect to download file contained in the response headers
		if (($_rs.headers["Content-Disposition"]) -and ($_rs.headers["Content-Disposition"].StartsWith("attachment; filename="))) 
		{
		
			$_fileName = ($_rs.headers["Content-Disposition"].SubString(21)) -replace "`"",""
		
		}
						
		# Detect if the download is a Support Dump or Appliance Backup
		elseif ($uri.Contains("/rest/backups/archive"))
		{

			# Need to get the Appliance file name
			$_fileName = $uri.split("/")
			
			$_fileName = $_fileName[-1] + ".bkp"
		
		}

		else 
		{
			# Need to get the Support Dump file name
			$_fileName = $uri.split("/")

			$_fileName = $ApplianceConnection.Name + "_" + $_fileName[-1]

		}

		if ($_rs.headers['Content-Length']) 
		{ 
			
			[int64]$_fileSize = $_rs.headers['Content-Length'] 
			Write-Verbose ('*****Filesize from Header: {0}' -f $_fileSize)
		
		}

		elseif ($_rs.ContentLength) 
		{ 
			
			[int64]$_fileSize = $_rs.ContentLength 
			Write-Verbose ('*****Filesize from ContentLength: {0}' -f $_fileSize)
		
		}

		"[{0}] Filename: $($_fileName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		"[{0}] Filesize: $($_fileSize)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		if($_rs.StatusCode -eq 200) 
		{

			Try
			{

				# Read from response and write to file
				$_stream = $_rs.GetResponseStream() 
				
				# Define buffer and buffer size
				Write-Verbose ('Creating Buffer of size: {0}MB' -f ((1024 * 8192) / 1MB))
				[byte[]]$_buffer   = New-Object byte[] (1024 * 8192)
				[int] $_bytesRead  = 0

				Write-Verbose ('Buffer size: {0}' -f $_buffer.length)

				# This is used to keep track of the file upload progress.
				$_numBytesRead     = 0
				$_numBytesWrote    = 0
	 
				"[{0}] Saving to $($saveLocation)\$($_fileName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_fs = New-Object IO.FileStream ($saveLocation + "\" + $_fileName),'Create' #,'Write','Read'

				# Throughput Stopwatch
				$_sw = New-Object System.Diagnostics.StopWatch
				$_progresssw = New-Object System.Diagnostics.StopWatch
				$_sw.Start()
				$_progresssw.Start()

				while (($_bytesRead = $_stream.Read($_buffer, 0, $_buffer.Length)) -gt 0)
				{

					# Write from buffer to file
					$_fs.Write($_buffer, 0, $_bytesRead)
				
					# Keep track of bytes written for progress meter
					$_total += $_bytesRead

					# Elapsed time to calculate throughput
					$_transferrate = ($_total / $_sw.Elapsed.TotalSeconds) / 1MB

					# Use the Write-Progress cmd-let to show the progress of uploading the file.
					[int]$_percent = (($_total / $_fileSize)  * 100)

					$_status = '{0:0}MB of {1:0}MB @ {2:N2}MB/s' -f ($_total / 1MB), ($_fileSize / 1MB), $_transferrate

					# Handle the call from -Verbose so Write-Progress does not get borked on display.
					if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
					{ 
				
						if ($_progresssw.Elapsed.TotalMilliseconds -ge 500)
						{
							
							"[{0}] Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							"[{0}] Downloading file: $_fileName, status: $_status, Percent: $_percent" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$_progresssw.Restart()

						}
					
					}
				  
					else 
					{ 
					
						if ($_progresssw.Elapsed.TotalMilliseconds -ge 500)
						{

							Write-Progress -id 0 -Activity "Downloading file $_fileName" -Status $_status -percentComplete $_percent 

							$_progresssw.Restart()

						}						
				
					}

				} # While ($_bytesRead -gt 0)

				Write-Progress -id 0 -Activity "Downloading file $_fileName" -Completed

				"[{0}] File saved to $($saveLocation)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_downloadfilestatus.status              = 'Completed'
				$_downloadfilestatus.file                = "$saveLocation\$_fileName"
				$_downloadfilestatus.ApplianceConnection = $ApplianceConnection.Name

				Return $_downloadfilestatus

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			finally
			{

				# Clean up our work
				if ($_stream) { $_stream.Close() }
				if ($_rs) { $_rs.Close() }
				if ($_fs) { $_fs.Close() }

			}

		}

		else
		{

			# Clean up
			if ($_rs) { $_rs.Close() }
			if ($_fs) { $_fs.Close() }

			Throw 'Unhandled download exception'

		}	
		
	}

}
