function Upload-File 
{

    <#

		.SYNOPSIS
		Upload a file to the appliance.

		.DESCRIPTION
		This cmdlet will upload a file to the appliance that can accepts file uploads (SPP firmware bundle, Appliance Restore, and Appliance Updates.)

		.Parameter URI
		Location where to upload file to.

		.Parameter File
		Full path to the file to be uploaded.

		.Parameter AddHeader
		Provide a Hashtable of additional HTTP headers to include
		
		.Parameter ApplianceConnection
		Appliance Connection

		.INPUTS
		None.  You cannot pipe objects to this cmdlet.

		.OUTPUTS
		Write-Progress
		The progress of uploading the file to the appliance.

		.LINK
		Add-HPOVBaseline

		.LINK
		New-HPOVRestore

		.EXAMPLE
		PS C:\> Upload-File "/rest/firmware-bundles" "C:\Users\me\Documents\SPP2012060B.2012_0525.1.iso"

		Upload a new SPP into the appliance.

		.EXAMPLE
		PS C:\> Upload-File "/rest/restores" "C:\Users\me\Documents\appliance.bak"

		Upload a backup file to restore in the appliance.

	#>

    [CmdletBinding ()]

    Param 
    (

        [Parameter (Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias ('u')]
        [string]$uri,

        [Parameter (Mandatory)]
        [Alias ('f')]
        [ValidateScript( {Test-Path $_})]
        [System.IO.FileInfo]$File,

        [Parameter (Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [Object]$AddHeader,

        [Parameter (Mandatory = $false)]
        [ValidateSet ('PUT', 'POST')]
        [String]$Method = 'POST',
		
        [Parameter (Mandatory = $false)]
        [Alias ('Hostname')]
        [ValidateNotNullorEmpty()]
        [object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

    )

    Begin 
    {

        "[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

        $Caller = (Get-PSCallStack)[1].Command

        "[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

        "[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

        if (-not($ApplianceConnection -is [HPOneView.Appliance.Connection]) -and (-not($ApplianceConnection -is [System.String])))
        {

            $ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException InvalidApplianceConnectionDataType InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter is not type [HPOneView.Appliance.Connection] or [System.String].  Please correct this value and try again.'
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)

        }

        elseif ($ApplianceConnection.Count -gt 1)
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

        # $_fileObj = Get-Item -path $File
		
        $fs = New-Object IO.FileStream ($File.FullName, $FSOpenMode, $FSRead)

        # [string]$filename = $_fileObj.name

        "[{0}] Uploading {1} file to appliance, this may take a few minutes..." -f $MyInvocation.InvocationName.ToString().ToUpper(), $File.FullName | Write-Verbose

        try 
        {

			$uri = "{0}?uploadfilename={1}" -f $uri, $File.Name
			
			# $_encoding = $null
			$_DispositionContentType = "application/octet-stream"
			
			if ($File.Extension -eq '.crl')
			{

				# $_encoding = [System.Text.Encoding]::GetEncoding("iso-8859-1")

				$_DispositionContentType = "application/pkix-crl"

				"[{0}] Setting HttpWebRequest body encoding to 'ISO-8859-1': {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [Bool]$_encoding | Write-Verbose
				
			}

			"[{0}] Setting Disposition Content-Type to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_DispositionContentType | Write-Verbose			

            [System.Net.httpWebRequest]$uploadRequest = RestClient $Method $uri -Appliance $ApplianceConnection.Name

            $boundary = "---------------------------" + [DateTime]::Now.Ticks.ToString("x")
            [byte[]]$BoundaryBytes = [System.Text.Encoding]::UTF8.GetBytes("`r`n--" + $boundary + "`r`n");
            $disposition = "Content-Disposition: form-data; name=`"file`"; filename=`"{0}`";`r`nContent-Type: {1}`r`n`r`n" -f $File.Name, $_DispositionContentType
            [byte[]]$ContentDispBytes = [System.Text.Encoding]::UTF8.GetBytes($disposition);
            [byte[]]$EndBoundaryBytes = [System.Text.Encoding]::UTF8.GetBytes("`r`n--" + $boundary + "--`r`n")

            $uploadRequest.Timeout = 1200000
            $uploadRequest.ContentType = "multipart/form-data; boundary={0}" -f $boundary
            $uploadRequest.Headers.Item("auth") = $ApplianceConnection.SessionID
            $uploadRequest.Headers.Item("uploadfilename") = $File.Name
            $uploadRequest.AllowWriteStreamBuffering = $false
            $uploadRequest.SendChunked = $false
            $uploadRequest.ContentLength = $BoundaryBytes.length + $ContentDispBytes.length + $File.Length + $EndBoundaryBytes.Length
			$uploadRequest.Headers.Item("ContentLength") = $BoundaryBytes.length + $ContentDispBytes.length + $File.Length + $EndBoundaryBytes.Length

            ForEach ($_Header in $AddHeader)
            {

                $uploadRequest.Headers.($_Header.Name) = $_Header.Value

            }

            "[{0}] Request: POST {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $uri | Write-Verbose

            $i = 0

            foreach ($h in $uploadRequest.Headers) 
            {
				
                "[{0}] Request Header ({1}) {2} : {3}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $i, $h, $uploadRequest.Headers[$i] | Write-Verbose
				
                $i++
			
            }

            $rs = $uploadRequest.GetRequestStream()

            [byte[]]$readbuffer = New-Object byte[] (4096 * 1024)		
            $rs.write($BoundaryBytes, 0, $BoundaryBytes.Length);
            $rs.write($ContentDispBytes, 0, $ContentDispBytes.Length);

            # This is used to keep track of the file upload progress.
            $numBytesToRead = $fs.Length    
            [int64]$numBytesRead = 0

            if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
            { 
			
                "[{0}] Skipping Write-Progress display." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
            }

            $_sw = [System.Diagnostics.Stopwatch]::StartNew()
            $_progresssw = [System.Diagnostics.Stopwatch]::StartNew()

            while ($byteCount = $fs.Read($readbuffer, 0, $readbuffer.length))
            {

				$rs.write($readbuffer, 0, $byteCount)
                
                $rs.flush()
			
                # Keep track of where we are at clearduring the read operation
                $_numBytesRead += $bytecount

                # Use the Write-Progress cmd-let to show the progress of uploading the file.
                [int]$_percent = [math]::floor(($_numBytesRead / $fs.Length) * 100)

                # Elapsed time to calculat throughput
                [int]$_elapsed = $_sw.ElapsedMilliseconds / 1000
				
                if ($_elapsed -ne 0 ) 
                {

                    [single]$_transferrate = [Math]::Round(($_numBytesRead / $_elapsed) / 1mb)
				
                } 
				
                else 
                {

                    [single]$_transferrate = 0.0
				
                }

                $status = "({0:0}MB of {1:0}MB transferred @ {2}MB/s) Completed {3}%" -f ($_numBytesRead / 1MB), ($numBytesToRead / 1MB), $_transferrate, $_percent

                # Handle the call from -Verbose so Write-Progress does not get borked on display.
                if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
                { 

                    "[{0}] Uploading file {1}, status: {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $File.Name, $status | Write-Verbose
					
                }
				  
                else 
                { 

                    if ($_progresssw.Elapsed.TotalMilliseconds -ge 500)
                    {

                        if ($_numBytesRead % 1mb -eq 0) 
                        { 
							
                            Write-Progress -activity "Upload File" -status ("Uploading '{0}'" -f $File.Name) -CurrentOperation $status -PercentComplete $_percent 
						
                        }

                    }

                }

            }

            "[{0}] Finalizing upload." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

            $fs.close()

            $rs.write($EndBoundaryBytes, 0, $EndBoundaryBytes.Length)

            $rs.close()

            $_sw.stop()
            $_sw.Reset()

            Write-Progress -activity "Upload File" -status ("Uploading '{0}'" -f $File.Name)  -Complete

        }

        catch [System.Exception] 
        {

			Write-Verbose "Exception caught while uploading file."

			Write-Verbose ("Exception: {0}" -f $_.Exception.Message)
			Write-Verbose ("InnerException: {0}" -f $_.Exception.InnerException.Message)

			if ($fs)
            {

				$fs.close() 
				
            }

            if ($_sw.IsRunning) 
            { 
				
                $_sw.Stop() 
                $_sw.Reset()
			
            }

            # Dispose if still exist
            if ($rs)
            {

				$rs.close() 
				
			}

            $PSCmdlet.ThrowTerminatingError($_)

        }

        try 
        {

            "[{0}] Upload Request completed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
            if ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue') 
            {

                "[{0}] Waiting for completion response from appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

            }

            else 
            { 

                Write-Progress -activity "Upload File" -status ("Uploading '{0}'" -f $File.Name)  -CurrentOperation "Waiting for completion response from appliance." -percentComplete $_percent 
			
            }

            [Net.httpWebResponse]$WebResponse = $uploadRequest.getResponse()
			
            "[{0}] Response Status: ({1}) {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [int]$WebResponse.StatusCode, $WebResponse.StatusDescription | Write-Verbose
			
            $uploadResponseStream = $WebResponse.GetResponseStream()

            # Read the response & convert to JSON
            $reader = New-Object System.IO.StreamReader($uploadResponseStream)
            $responseJson = $reader.ReadToEnd()

            $uploadResponse = ConvertFrom-Json $responseJson

            $uploadResponseStream.Close()

            # need to parse the output to know when the upload is truly complete
			"[{0}] Response: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($uploadResponse | out-string) | Write-Verbose
			
			$i = 0

			foreach ($h in $WebResponse.Headers) 
			{ 
				
				"[{0}] Response Header {1}: {2} = {3}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $i, $h, $WebResponse.Headers[$i] | Write-Verbose
				
				$i++ 
			
			}

            $uploadRequest = $Null

            Write-Progress -activity "Upload File" -CurrentOperation "Uploading $Filename " -Completed

        }

        catch [Net.WebException] 
        {

            "[{0}] WebException caught. Getting exception response from API." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
 
            Try
            {

                $sr = New-Object IO.StreamReader ($_.Exception.Response.GetResponseStream())

            }
			
            Catch
            {

                $PSCmdlet.ThrowTerminatingError($_)

            }
			
            $errorObject = $sr.readtoEnd() | ConvertFrom-Json
			
            "[{0}] Error Response from API: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($errorObject | Out-String) | Write-Verbose

            # dispose if still exist
            if ($rs)
            {

				$rs.close() 
				
			}
			
            if ($fs)
            {

				$fs.close() 
				
            }

            $sr.close()

            $ErrorRecord = New-ErrorRecord HPOneview.Appliance.UploadFileException $errorObject.ErrorCode InvalidResult 'Upload-File' -Message $errorObject.Message -InnerException $_.Exception

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
        }

    }

    End 
    {

		if ($uploadResponseStream)
        {
			
            $uploadResponseStream.Close()

        }

        # Handle file uploads that generate task resource (i.e. Upload SPP Baseline)
        if ($uploadResponse.category -eq "tasks") 
        {
			
            "[{0}] Response is a task resource" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose	

            $uploadResponse | ForEach-Object { $_.PSObject.TypeNames.Insert(0, "HPOneView.Appliance.TaskResource") }

			Add-Member -InputObject $uploadResponse -NotePropertyName ApplianceConnection -NotePropertyValue (New-Object HPOneView.Library.ApplianceConnection($ApplianceConnection.Name, $ApplianceConnection.ConnectionId)) -Force 
			
			return $uploadResponse

        }

        elseif ($null -ne $WebResponse.Headers)
        {

            if ($WebResponse.Headers['Location'])
            {

                try
                {

					"[{0}] Response is a task resource provided by HTTP Location header." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					$uri = $WebResponse.Headers['Location']

					$taskResource = Send-HPOVRequest -Uri $uri -Hostname $ApplianceConnection.Name
					
					Return $taskResource

                }

                catch
                {

                    $PSCmdlet.ThrowTerminatingError($_)

                }			

            }

            else
            {

                "[{0}] Response does not contain any HTTP headers or task location." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

            }			

        }		
		
    }

}
