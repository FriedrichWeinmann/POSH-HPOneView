function Add-HPOVApplianceTrustedCertificate
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[System.IO.FileInfo]$Path,

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Object]$CertObject,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$ComputerName,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Int]$Port,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$AliasName,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Switch]$Force,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Switch]$Async,
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
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
		
	}
	
	Process 
	{

		if (-not $Path -and $ComputerName)
		{

			"[{0}] Attempting to retreive SSL certificate from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ComputerName | Write-Verbose

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

				# Attempt to get the server cert using GET /rest/certificates/https/remote/$ComputerName
				Try
				{

					$_Uri = '{0}{1}' -f $RetrieveHttpsCertRemoteUri, $ComputerName

					if ($PSBoundParameters['Port'])
					{

						$_Uri += ':{0}' -f $Port
					}

					$_RemoteHttpsServerCert = Send-HPOVRequest -Uri $_Uri -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				# Add the SSL certificate to the appliance
				$_CertObject = NewObject -ApplianceTrustedSslCertificate
				$_CertObject.aliasName  = $PSBoundParameters['AliasName']
				$_CertObject.base64Data = $_RemoteHttpsServerCert.certificateDetails.base64Data

				$_CertToImportCollection = [PSCustomObject]@{

					type = 'CertificateInfoV2';
					certificateDetails = New-Object System.Collections.ArrayList
					
				}

				[void]$_CertToImportCollection.certificateDetails.Add($_CertObject)

				$Params = @{
					Uri      = $ApplianceTrustedSslHostStoreUri;
					Method   = 'POST';
					Body     = $_CertToImportCollection;
					Hostname = $_appliance.Name
				}

				if ($PSBoundParameters['Force'])
				{

					$Params.Add('AddHeader', @{Forcesaveleaf = $true})

				}

				Try
				{

					$_Resp = Send-HPOVRequest @Params
					

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if (-not $PSBoundParameters['Async'])
				{

					$_Resp | Wait-HPOVTaskComplete

				}

				else
				{

					$_Resp

				}

			}

		}

		elseif ($Path -or $CertObject)
		{

			if ($Path)
			{

				"[{0}] Processing path: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Path.Name | Write-Verbose

				# Validate cert is valid X509 object
				Try
				{

					$_x509CertObject = New-Object Security.Cryptography.X509Certificates.X509Certificate2($Path)
					$sb = New-Object System.Text.StringBuilder
					[void]$sb.Append("-----BEGIN CERTIFICATE-----`n")
					[void]$sb.Append([System.Convert]::ToBase64String($_x509CertObject.RawData, "InsertLineBreaks"))
					[void]$sb.Append("`n-----END CERTIFICATE-----`n")
					
					$_CertObject = $sb.ToString().Clone()

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($CertObject -is [System.Security.Cryptography.X509Certificates.X509Certificate2])
			{
	
				"[{0}] Processing certificate object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $CertObject.ToString() | Write-Verbose

				# Validate cert is valid X509 object
				Try
				{

					$_x509CertObject = $CertObject

					$sb = New-Object System.Text.StringBuilder
					[void]$sb.Append("-----BEGIN CERTIFICATE-----`n")
					[void]$sb.Append([System.Convert]::ToBase64String($CertObject.RawData, "InsertLineBreaks"))
					[void]$sb.Append("`n-----END CERTIFICATE-----`n")
					
					$_CertObject = $sb.ToString().Clone()

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			else
			{

				"[{0}] Base64 Cert object provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$base64string = $CertObject.Replace("-----BEGIN CERTIFICATE-----`n",$null).Replace("`n-----END CERTIFICATE-----",$null)
				$_CertObject  = $CertObject.Clone()
				$_x509CertObject = New-Object Security.Cryptography.X509Certificates.X509Certificate2(([System.Convert]::FromBase64String($base64string)), $null)

			}			

			# Look at .Extensions | ? { $_.KeyUsages -match 'KeyCertSign' } or EnhancedKeyUsage
			# This is a CA or Issuing Cert Authority
			if ($_x509CertObject.Extensions | Where-Object { $_.KeyUsages -match 'KeyCertSign' })
			{

				"[{0}] Cert is Issuing authority" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_Cert = NewObject -ApplianceTrustedCertAuthority

				if (-not $PSBoundParameters['AliasName'])
				{

					$AliasName = $_x509CertObject.GetNameInfo([System.Security.Cryptography.X509Certificates.X509NameType]::SimpleName,$false)

				}

				$_Cert.certificateDetails.aliasName  = $AliasName
				$_Cert.certificateDetails.base64Data = $_CertObject #-join "`n"

				$_CertToImportCollection = [PSCustomObject]@{

					type    = 'CertificateAuthorityInfoCollection';
					members = New-Object System.Collections.ArrayList
					
				}

				[void]$_CertToImportCollection.members.Add($_Cert)

				$_Uri = $ApplianceCertificateAuthorityUri.Clone()

			}

			else
			{

				"[{0}] Cert is Server Authentication host" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Add the SSL certificate to the appliance
				$_Cert = NewObject -ApplianceTrustedSslCertificate
				$_Cert.aliasName  = $PSBoundParameters['AliasName']
				$_Cert.base64Data = $_CertObject -join "`n"

				$_CertToImportCollection = [PSCustomObject]@{

					type = 'CertificateInfoV2';
					certificateDetails = New-Object System.Collections.ArrayList
					
				}

				[void]$_CertToImportCollection.certificateDetails.Add($_Cert)

				# Throw error that cert does not have the right EnchancedKeyUsage bit set
				if (-not($_x509CertObject.EnhancedKeyUsageList | Where-Object FriendlyName -notmatch "Server Authentication"))
				{
					
					# THrow exception

				}

				$_Uri = $ApplianceTrustedSslHostStoreUri.Clone()

			}

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

				$Params = @{
					Uri      = $_Uri;
					Method   = 'POST';
					Body     = $_CertToImportCollection;
					Hostname = $_appliance.Name
				}

				if ($PSBoundParameters['Force'])
				{

					$Params.Add('AddHeader', @{Forcesaveleaf = $true})

				}

				Try
				{

					$_Resp = Send-HPOVRequest @Params
					
				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if (-not $PSBoundParameters['Async'])
				{

					$_Resp | Wait-HPOVTaskComplete

				}

				else
				{

					$_Resp

				}

			}

		}
		
	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
