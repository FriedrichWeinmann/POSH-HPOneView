function ConvertTo-Pfx
{

	# Modified from Script provided by Vadims Padans (https://www.sysadmins.lv/blog-en/how-to-convert-pem-to-x509certificate2-in-powershell-revisited.aspx)

	[CmdletBinding ()]
	Param
	( 

		[Parameter (Mandatory)]
		[System.IO.FileSystemInfo]$PrivateKeyFile,

		[Parameter (Mandatory)]
		[System.IO.FileSystemInfo]$PublicKeyFile,
	
		[Parameter (Mandatory)]
		[SecureString]$Password
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

	}

	Process
	{

		function __normalizeAsnInteger ($array) 
		{

			$padding = $array.Length % 8

			if ($padding) 
			{

				$array = $array[$padding..($array.Length - 1)]
				
			}

			[array]::Reverse($array)

			[Byte[]]$array

		}

		function __extractCert([string]$Text) 
		{

			$keyFlags = [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable

			$Text -match "(?msx).*-{5}BEGIN\sCERTIFICATE-{5}(.+)-{5}End\sCERTIFICATE-{5}" | Out-Null

			$RawData = [Convert]::FromBase64String($matches[1])

			try 
			{

				New-Object Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $RawData, "", $keyFlags

			}
			
			catch 
			{
				
				throw "The data is not valid security certificate."
			
			}

			Write-Debug "X.509 certificate is correct."

		}

		# returns [byte[]]
		function __composePRIVATEKEYBLOB($modulus, $PublicExponent, $PrivateExponent, $Prime1, $Prime2, $Exponent1, $Exponent2, $Coefficient) {

			Write-Debug "Calculating key length."

			$bitLen = "{0:X4}" -f $($modulus.Length * 8)

			Write-Debug "Key length is $($modulus.Length * 8) bits."

			# Change from Invoke-Expression due to security "issues" and guidance from MS
			# [byte[]]$bitLen1 = Invoke-Expression 0x$([int]$bitLen.Substring(0,2))
			[byte[]]$bitLen1 = '0x{0}' -f [int]$bitLen.Substring(0,2)
			# [byte[]]$bitLen2 = Invoke-Expression 0x$([int]$bitLen.Substring(2,2))
			[byte[]]$bitLen2 = '0x{0}' -f [int]$bitLen.Substring(2,2)
			[Byte[]]$PrivateKey = 0x07,0x02,0x00,0x00,0x00,0x24,0x00,0x00,0x52,0x53,0x41,0x32,0x00
			[Byte[]]$PrivateKey = $PrivateKey + $bitLen1 + $bitLen2 + $PublicExponent + ,0x00 + $modulus + $Prime1 + $Prime2 + $Exponent1 + $Exponent2 + $Coefficient + $PrivateExponent

			Return $PrivateKey

		}

		# returns RSACryptoServiceProvider for dispose purposes
		function __attachPrivateKey($Cert, [Byte[]]$PrivateKey) {

			$cspParams = New-Object Security.Cryptography.CspParameters -Property @{
				ProviderName = $ProviderName
				KeyContainerName = "pspki-" + [Guid]::NewGuid().ToString()
				KeyNumber = 1 # AT_KEYEXCHANGE
			}

			$rsa = New-Object Security.Cryptography.RSACryptoServiceProvider $cspParams
			$rsa.ImportCspBlob($PrivateKey)
			$Cert.PrivateKey = $rsa
			Return $rsa

		}

		# returns Asn1Reader
		function __decodePkcs1($base64) 
		{

			Write-Debug "Processing PKCS#1 RSA KEY module."

			$asn = New-Object SysadminsLV.Asn1Parser.Asn1Reader @(,[Convert]::FromBase64String($base64))

			if ($asn.Tag -ne 48) {throw "The data is invalid."}

			Return $asn

		}

		# returns Asn1Reader
		function __decodePkcs8($base64) 
		{

			Write-Debug "Processing PKCS#8 Private Key module."

			$asn = New-Object SysadminsLV.Asn1Parser.Asn1Reader @(,[Convert]::FromBase64String($base64))

			if ($asn.Tag -ne 48) {throw "The data is invalid."}

			# version
			if (!$asn.MoveNext()) {throw "The data is invalid."}

			# algorithm identifier
			if (!$asn.MoveNext()) {throw "The data is invalid."}

			# octet string
			if (!$asn.MoveNextCurrentLevel()) {throw "The data is invalid."}
			if ($asn.Tag -ne 4) {throw "The data is invalid."}
			if (!$asn.MoveNext()) {throw "The data is invalid."}

			Return $asn

		}

		$PfxFileName = $PrivateKeyFile.FullName.Replace(".key",".pfx")

		# Merge Public and Private Key file contents together
		[String]$PrivateKeyFileContents = [System.IO.File]::ReadAllLines($PrivateKeyFile.FullName)
		[String]$CertFileContents       = [System.IO.File]::ReadAllLines($PublicKeyFile.FullName)

		Write-Debug "Extracting certificate information..."

		$Cert = __extractCert $CertFileContents # Validate PEM certificate

		$PrivateKeyFileContents -match "(?msx).*-{5}BEGIN\sRSA\sPRIVATE\sKEY-{5}(.+)-{5}End\sRSA\sPRIVATE\sKEY-{5}" | Out-Null
		$asn = __decodePkcs1 $matches[1]

		# private key version
		if (!$asn.MoveNext()) {throw "The data is invalid."}

		# modulus n
		if (!$asn.MoveNext()) {throw "The data is invalid."}

		$modulus = __normalizeAsnInteger $asn.GetPayload()
		Write-Debug "Modulus length: $($modulus.Length)"

		# public exponent e
		if (!$asn.MoveNext()) {throw "The data is invalid."}

		# public exponent must be 4 bytes exactly.
		$PublicExponent = if ($asn.GetPayload().Length -eq 3) 
		{
			,0 + $asn.GetPayload()

		} 
		
		else 
		{

			$asn.GetPayload()

		}

		Write-Debug "PublicExponent length: $($PublicExponent.Length)"

		# private exponent d
		if (!$asn.MoveNext()) {throw "The data is invalid."}
		$PrivateExponent = __normalizeAsnInteger $asn.GetPayload()
		Write-Debug "PrivateExponent length: $($PrivateExponent.Length)"

		# prime1 p
		if (!$asn.MoveNext()) {throw "The data is invalid."}
		$Prime1 = __normalizeAsnInteger $asn.GetPayload()
		Write-Debug "Prime1 length: $($Prime1.Length)"

		# prime2 q
		if (!$asn.MoveNext()) {throw "The data is invalid."}
		$Prime2 = __normalizeAsnInteger $asn.GetPayload()
		Write-Debug "Prime2 length: $($Prime2.Length)"

		# exponent1 d mod (p-1)
		if (!$asn.MoveNext()) {throw "The data is invalid."}
		$Exponent1 = __normalizeAsnInteger $asn.GetPayload()
		Write-Debug "Exponent1 length: $($Exponent1.Length)"

		# exponent2 d mod (q-1)
		if (!$asn.MoveNext()) {throw "The data is invalid."}
		$Exponent2 = __normalizeAsnInteger $asn.GetPayload()
		Write-Debug "Exponent2 length: $($Exponent2.Length)"

		# coefficient (inverse of q) mod p
		if (!$asn.MoveNext()) {throw "The data is invalid."}
		$Coefficient = __normalizeAsnInteger $asn.GetPayload()
		Write-Debug "Coefficient length: $($Coefficient.Length)"

		# creating Private Key BLOB structure
		$PrivateKey = __composePRIVATEKEYBLOB $modulus $PublicExponent $PrivateExponent $Prime1 $Prime2 $Exponent1 $Exponent2 $Coefficient

		# Region key attach and export routine
		$rsaKey = __attachPrivateKey $Cert $PrivateKey

		$pfxBytes = $Cert.Export("pfx", $Password)

		[System.IO.File]::WriteAllBytes($PfxFileName, $pfxBytes)

		$rsaKey.Dispose()
		[System.IO.FileInfo]$PfxFileName

		"[{0}] Created PFX certificate: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PfxFileName | Write-Verbose

	}

	End	
	{


	}

}
