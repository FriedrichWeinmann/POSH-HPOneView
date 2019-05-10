function Import-HPOVSslCertificate 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]

	Param 
	(
	
		[Parameter (ValueFromPipeline, Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['ApplianceConnection'])) 
		{ 
			
			$PipelineInput = $True 
		
		}

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			if ($_appliance -is [HPOneView.Appliance.Connection])
			{

				$_appliance = $_appliance.Name

			}

			"[{0}] Processing Appliance '{1}' (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance, $ApplianceConnection.Count | Write-Verbose

			try 
			{

				"[{0}] Getting response" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[System.Net.HttpWebRequest]$WebRequest = [System.Net.HttpWebRequest]::Create("https://$_appliance")

				$WebRequest.ServerCertificateValidationCallback = { $True }
				
				$Response = $WebRequest.GetResponse()
			
			}
			
			catch [Net.WebException] 
			{ 

				if (-not($WebRequest.Connection) -and ([int]$Response.StatusCode -eq 0)) 
				{

					Write-Error $_.Exception.Message -Category ObjectNotFound -ErrorAction Stop

				} 

			}

			finally
			{

				# Close the response connection, as it is no longer needed, and will cause problems if left open.
				if ($Response) 
				{
					
					"[{0}] Closing response connection" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					$Response.Close() 
				
				}

				$Response.Dispose()

			}		

			if ($null -ne $WebRequest.ServicePoint.Certificate) 
			{

				# Get certificate
				$Cert = [Security.Cryptography.X509Certificates.X509Certificate2]$WebRequest.ServicePoint.Certificate

				$StoreScope = "CurrentUser"
				$StoreName  = "Root" 

				# Save to users Trusted Root Authentication Hosts store
				$store = New-Object System.Security.Cryptography.X509Certificates.X509Store $StoreName, $StoreScope

				$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)

				try 
				{

					"[{0}] Attempting to add cert to store" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$store.Add($cert)
					$store.Close()

					"[{0}] Cert added successfully" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

				catch 
				{

					$store.Close()
					# Write-Error $_.Exception.Message -Category InvalidResult -ErrorAction Stop
					$PSCmdlet.ThrowTerminatingError($_.Exception)

				}

			}

		}

	}
	
	End	
	{ 
		
		Write-Warning "Please note that the Subject Alternate Name (SAN) must match that of the Appliance hostname you use to connect to your appliance.  If it does not, an SSL connection failure will occur.  When creating a CSR on the appliance, make sure to include the additional FQDN and IP address(es) in the Alternative Name field." 
	
	}

}
