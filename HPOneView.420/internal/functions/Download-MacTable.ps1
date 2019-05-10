function Download-MacTable 
{
	
	<#
		.SYNOPSIS
		Download Logical Interconnect MAC Table CSV.

		.DESCRIPTION
		This internal helper function will download the MAC Table CSV from a provided Logical Interconnect, parse it and return an array of MAC Table entries.

		.Parameter Uri
		[System.String] URI of Logical Interconnect.

		.Parameter Hostname
		[System.String] Hostname of Appliance

		.INPUTS
		None.

		.OUTPUTS
		System.Array
		Array of MAC Table entries.

		.LINK
		Get-HPOVLogicalInterconnect

		.EXAMPLE
		PS C:\> $encl1li = Get-HPOVLogicalInterconnect Encl1-LI
		PS C:\> Download-MACTable $encl1li

		Get the Logical Interconnect 'Encl1-LI' and 
				
	#>

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({if ($_.type -eq 'interconnect-fib-data-info') { $true } else {throw "-URI must being with a '/rest/logical-interconnects/' in its value. Please correct the value and try again."}})]
		[Object]$InputObject

	) 

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		$enc = [System.Text.Encoding]::UTF8

	}
 
	Process
	{	

		"[{0}] Download URI: $($InputObject.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		[System.Net.httpWebRequest]$fileDownload = RestClient GET $InputObject.uri $InputObject.ApplianceConnection.Name

		$fileDownload.accept               = "application/zip,application/octet-stream,*/*"
		$fileDownload.Headers.Item("auth") = ($ConnectedSessions | Where-Object Name -eq $InputObject.ApplianceConnection.Name).SessionID

		$i = 0
		foreach ($h in $fileDownload.Headers) 
		{ 
			
			"[{0}] Request Header $($i): $($h) = $($fileDownload.Headers[$i])" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			$i++
		
		}
		
		Try
		{

			"[{0}] Request: GET {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $fileDownload.RequestUri.AbsolutePath | Write-Verbose
			
			# Get response
			"[{0}] Getting response" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			[Net.httpWebResponse]$rs = $fileDownload.GetResponse()

			# Display the response status if verbose output is requested
			"[{0}] Response Status: $([int]$rs.StatusCode) $($rs.StatusDescription)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$i = 0
			foreach ($h in $rs.Headers) 
			{ 
				
				"[{0}] Response Header $($i): $($h) = $($rs.Headers[$i])" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				$i++ 
			
			}

			# Request is a redirect to download file contained in the response headers
			$fileName = ($rs.headers["Content-Disposition"].SubString(21)) -replace "`"",""

			"[{0}] Filename: $($fileName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
												
			"[{0}] Filesize:  $($rs.ContentLength)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$responseStream = $rs.GetResponseStream()

			# Define buffer and buffer size
			[int] $bufferSize = ($rs.ContentLength*1024)
			[byte[]]$Buffer   = New-Object byte[] ($rs.ContentLength*1024)
			[int] $bytesRead  = 0

			# This is used to keep track of the file upload progress.
			$totalBytesToRead = $rs.ContentLength
			$numBytesRead     = 0
			$numBytesWrote    = 0

			# Read from stream
			"[{0}] Reading HttpWebRequest file stream." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			$responseStream.Read($Buffer, 0, $bufferSize) | out-Null
			
			# Write to output stream
			$outStream = New-Object System.IO.MemoryStream (,$Buffer)	

			$source = $outStream.ToArray()
		
			"[{0}] Decompressing HttpWebRequest file." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			$sr = New-Object System.IO.Compression.GZipStream($outStream,[System.IO.Compression.CompressionMode]::Decompress)
			
			# Reset variable to collect uncompressed result
			$byteArray = New-Object byte[]($source.Length+1024)
			
			# Decompress
			[int]$rByte = $sr.Read($byteArray, 0, $source.Length)

			# Transform byte[] unzip data to string
			"[{0}] Converting Byte array to String Characters." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			$sB = New-Object System.Text.StringBuilder($rByte)
			
			# Read the number of bytes GZipStream read and do not a for each bytes in resultByteArray
			for ([int] $i = 0; $i -lt $rByte; $i++) 
			{

				$sB.AppEnd([char]$byteArray[$i]) | Out-Null

			}
			
		}
		
		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		Finally
		{

			# Clean up our work
			if ($responseStream) { $responseStream.Close() }
			if ($rs) { $rs.Close() }
			if ($sr) { $sr.Close();$sr.Dispose() }

		}

	}

	End 
	{

		"[{0}] Building string array in CSV format" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		$macTableArray = $sb.ToString() -split "`n"
		$header        = "enclosure","interconnect","interface","address","type","network","extVLAN","intVLAN","serverProfile","uplinkSet","LAGPort1","LAGPort2","LAGPort3","LAGPort4","LAG Port5","LAG Port6","LAG Port7","LAG Port8"
		$macTableArray = $macTableArray[1..($macTableArray.count)]

		$e = @{Expression={
			 
				 $lagport = $_
				 1..8 | ForEach-Object { if ($lagport."LAGPort$($_)") { $lagport."LAGPort$($_)" } } 
						   
			 };name="LAGPorts"}

		$macTable = $macTableArray | ConvertFrom-Csv -Header $header | Select-Object "enclosure","interconnect","interface","address","type","network","extVLAN","intVLAN","serverProfile","uplinkSet",$e

		"[{0}] Returning results." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Return $macTable

	}

}
