function BuildLdapServer
{

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param
	(
		
		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ("Name")]
		[String]$Hostname,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Alias ('port')]
		[ValidateRange (1,65535)]
		[Int32]$SSLPort = 636,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Alias ('cert')]
		[Object]$Certificate,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Bool]$TrustLeafCertificate

	)

	Process
	{

		$Base64Certificate = ""

		if ($Certificate)
		{

			if (Test-Path $Certificate) 
			{ 

				"[{0}] Certificate file found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$readfile = [System.IO.File]::OpenText($Certificate)
					$certificate = $readfile.ReadToEnd()
					$readfile.Close()
					$Base64Certificate = ($Certificate | Out-String) -join "`n"

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}				

			}

			else 
			{

				$ErrorRecord = New-ErrorRecord System.IO.FileNotFoundException CertificateNotFound ObjectNotFound 'Certificate' -TargetType 'PSObject' -Message "Autehntication Directory Server SSL certiciate not found.  Please check the path of the public key, and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		elseif ($TrustLeafCertificate)
		{

			"[{0}] Attempting to retrieve Directory Server Secure LDAP Certificate" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# // Support Getting LDAP Server Certificate    
			$uri = $Hostname + ":" + $Sslport

			"[{0}] URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $uri | Write-Verbose

			try 
			{
				
				$WebRequest = [Net.WebRequest]::Create("https://$uri")

				$Response = $WebRequest.GetResponse()
			
			}
			
			catch [Net.WebException] 
			{ 

				'[{0}] Caught handled [System.Net.WebException] exception' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ErrorRecord = $_
				$EvaluateMessage = $_.Exception.Message

				$ErrorRecordSplat = @{ Exception = $null; ErrorID = $null; ErrorCategory = $null; TargetObject = $null; TargetType = $null; Message = $null }

				switch ($EvaluateMessage)
				{

					{$_ -match "The remote name could not be resolved"}
					{

						$ErrorRecordSplat.Message = $ErrorRecord.Exception.Message + " Please check the spelling of the hostname or FQDN."
						$ErrorRecordSplat.ErrorCategory = 'ObjectNotFound'
						$ErrorRecordSplat.ErrorID = 'UnknownHost'
						$ErrorRecordSplat.TargetObject = 'Name'
						$ErrorRecordSplat.TargetType = 'String'
						$ErrorRecordSplat.Exception = 'System.Net.WebException'

					}

					{$_ -match "Unable to connect to the remote server"}
					{

						$ErrorRecordSplat.Message = $ErrorRecord.Exception.Message + ". Valid Ssl Port or firewall blocking port?"
						$ErrorRecordSplat.ErrorCategory = 'ConnectionError'
						$ErrorRecordSplat.ErrorID = 'InvalidSslPort'
						$ErrorRecordSplat.TargetObject = 'Name'
						$ErrorRecordSplat.TargetType = 'String'
						$ErrorRecordSplat.Exception = 'System.Net.WebException'

					}

					default
					{

						$ErrorRecordSplat.Message = $ErrorRecord.Exception.Message
						$ErrorRecordSplat.ErrorCategory = 'ConnectionError'
						$ErrorRecordSplat.ErrorID = 'UnhandledException'
						$ErrorRecordSplat.TargetObject = 'Name'
						$ErrorRecordSplat.TargetType = 'String'
						$ErrorRecordSplat.Exception = 'System.Net.WebException'

					}
					
				}

				if (-not($WebRequest.Connection) -and ([int]$Response.StatusCode -eq 0)) 
				{

					$ErrorRecord = New-ErrorRecord @ErrorRecordSplat

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				} 

			}

			catch
			{

				'[{0}] Caught unhandled exception' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$PSCmdlet.ThrowTerminatingError($_)

			}

			Finally 
			{

				if ($response)
				{

					"[{0}] Closing response connection" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
					$Response.Close()

				}

				$Response   = $null

			}

			if ($null -ne $WebRequest.ServicePoint.Certificate) 
			{
				
				# Get certificate
				$Cert = New-Object Security.Cryptography.X509Certificates.X509Certificate2($WebRequest.ServicePoint.Certificate)

				$out = New-Object String[] -ArgumentList 3
						 
				$out[0] = "-----BEGIN CERTIFICATE-----"
				$out[1] = [System.Convert]::ToBase64String($Cert.RawData, "InsertLineBreaks")
				$out[2] = "-----END CERTIFICATE-----"

				$Base64Certificate = $out -join "`n"

			}

			# Error we couldn't get the certificate
			else
			{

				$ErrorRecord = New-ErrorRecord System.IO.FileNotFoundException CertificateNotFound ObjectNotFound 'Certificate' -Message "The response did not contain an SSL Certificate.  Unknown reason."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}
		
		$_LdapServer = NewObject -AuthDirectoryServer

		$_LdapServer.directoryServerIpAddress             = $Hostname
		$_LdapServer.directoryServerCertificateBase64Data = $Base64Certificate

		if ($PSBoundParameters['Sslport'])
		{

			$_LdapServer.directoryServerSSLPortNumber = $Sslport.ToString()

		}
		
		$_LdapServer.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.AuthDirectoryServer')

		return $_LdapServer

	}

}
