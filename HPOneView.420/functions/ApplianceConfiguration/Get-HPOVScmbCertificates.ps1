function Get-HPOVScmbCertificates 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'default')]
	Param
	(

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "convert")]
		[ValidateNotNullOrEmpty()]
		[Alias ("save")]
		[string]$Location = ($pwd).path,

		[Parameter (Mandatory = $false, ParameterSetName = "convert")]
		[ValidateNotNullOrEmpty()]
		[Alias ("pfx")]
		[switch]$ConvertToPFx,
		
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "convert")]
		[ValidateNotNullOrEmpty()]
		[SecureString]$Password,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "convert")]
		[switch]$InstallApplianceRootCA,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "convert")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
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

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command again."
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
		
		$TaskCollection = New-Object System.Collections.ArrayList
		
		# Validate the path exists.  If not, create it.
		if (-not(Test-Path $Location))
		{ 

			"[{0}] Directory does not exist.  Creating directory..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			New-Item -path $Location -ItemType Directory

		}

	}

	Process
	{
		
		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' appliance connection (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.count | Write-Verbose

			# Appliance CA
			$caFile = '{0}\{1}_ca.cer' -f $Location, $_appliance.Name
		
			# Appliance Public Key
			$publicKeyFile = '{0}\{1}_cert.cer' -f $Location, $_appliance.Name
		
			# Rabbit Client Private Key
			$privateKeyFile = '{0}\{1}_privateKey.key' -f $Location, $_appliance.Name

			# Check to see if the Rabbit client cert was already created
			Try
			{

				$_keys = Send-HPOVRequest -Uri $ApplianceRabbitMQKeyPairUri -Hostname $_appliance.Name

			}

			Catch [HPOneView.ResourceNotFoundException]
			{

				"[{0}] RabbitMQ SSL cert key pair does not exist." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_rabbitbody = NewObject -RabbitmqCertReq

					# Generate the client private key request
					# "[{0}] Body: $($_rabbitbody | Format-List * )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Send-HPOVRequest -Uri $ApplianceScmbRabbitmqUri -Method POST -Body $_rabbitbody -Hostname $_appliance.Name | Wait-HPOVTaskComplete | Out-Null

					# Retrieve generated keys
					$_keys = Send-HPOVRequest -Uri $ApplianceRabbitMQKeyPairUri -Hostname $_appliance.Name

				}

				Catch
				{
			
					$PSCmdlet.ThrowTerminatingError($_)
			
				}

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
		
			try 
			{

				New-Item $PrivateKeyFile -type file -force -value $_keys.base64SSLKeyData

				$PrivateKeyFile = [System.IO.FileInfo]$PrivateKeyFile

				"[{0}] Created rabbitmq_readonly user Private Key: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PrivateKeyFile.Name | Write-Verbose 

			}

			catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)
		
			}

			try 
			{

				New-Item $PublicKeyFile -type file -force -value $_keys.base64SSLCertData

				$PublicKeyFile = [System.IO.FileInfo]$PublicKeyFile

				"[{0}] Created rabbitmq_readonly user Public Key: {0}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PublicKeyFile.FullName | Write-Verbose 

			}

			catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			If ($PSBoundParameters['ConvertToPFx'])
			{
			
				Try
				{

					ConvertTo-Pfx -PrivateKeyFile $PrivateKeyFile -PublicKeyFile $PublicKeyFile -Password $Password

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}				
			
			}

			try 
			{

				$_Resp = Send-HPOVRequest -Uri $ApplianceInternalCertificateAuthority -Hostname $_appliance.Name

				$_ca = $_Resp.members[0].certificateDetails.base64Data

				New-Item $caFile -type file -force -value $_ca

				"[{0}] Created {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $caFile | Write-Verbose
		
			}

			catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($PSBoundParameters['InstallApplianceRootCA'])
			{

				# Get certificate
				[Security.Cryptography.X509Certificates.X509Certificate2]$Cert = [System.Convert]::FromBase64String($_ca.Replace('-----BEGIN CERTIFICATE-----',$null).Replace('-----End CERTIFICATE-----',$null)) 

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

					$PSCmdlet.ThrowTerminatingError($_.Exception)

				}

			}

		}

	}

}
