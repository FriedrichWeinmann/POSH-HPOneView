function New-HPOVLdapDirectory 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName='AD')]
	Param
	(

		[Parameter (Mandatory, ParameterSetName = "AD")]
		[Parameter (Mandatory, ParameterSetName = "LDAP")]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

		[Parameter (Mandatory, ParameterSetName = "AD")]
		[Switch]$AD,

		[Parameter (Mandatory, ParameterSetName = "LDAP")]
		[Alias ('LDAP')]
		[Switch]$OpenLDAP,

		[Parameter (Mandatory, ParameterSetName = "AD")]
		[Parameter (Mandatory, ParameterSetName = "LDAP")]
		[ValidateNotNullOrEmpty()]
		[Alias ('root','rootdn')]
		[String]$BaseDN,

		[Parameter (Mandatory = $false, ParameterSetName = "LDAP")]
		[ValidateSet('CN', 'UID', IgnoreCase = $False)]
		[String]$UserNamingAttribute = 'CN',

		[Parameter (Mandatory, ParameterSetName = "LDAP")]
		[ValidateNotNullOrEmpty()]
		[Array]$OrganizationalUnits,

		[Parameter (Mandatory, ParameterSetName = "AD")]
		[Parameter (Mandatory, ParameterSetName = "LDAP")]
		[ValidateNotNullOrEmpty()]
		[Array]$Servers,

		[Parameter (Mandatory = $false, ParameterSetName = "AD")]
		[Parameter (Mandatory = $false, ParameterSetName = "LDAP")]
		[ValidateNotNullOrEmpty()]
		[Alias ('u','user')]
		[String]$Username,

		[Parameter (Mandatory = $false, ParameterSetName = "AD")]
		[Parameter (Mandatory = $false, ParameterSetName = "LDAP")]
		[ValidateNotNullOrEmpty()]
		[Alias ('p','pass')]
		[Object]$Password,

		[Parameter (ValueFromPipeline, Mandatory = $false, ParameterSetName = "AD")]
		[Parameter (ValueFromPipeline, Mandatory = $false, ParameterSetName = "LDAP")]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential,

		[Parameter (Mandatory = $false, ParameterSetName = "AD")]
		[Parameter (Mandatory = $false, ParameterSetName = "LDAP")]
		[Switch]$ServiceAccount,

		[Parameter (Mandatory = $false, ParameterSetName = 'AD')]
		[Parameter (Mandatory = $false, ParameterSetName = 'LDAP')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		if ($PSBoundParameters['Username'])
		{

			Write-Warning "The -Username parameter will be deprecated in a future release. Please transition to using the -Credental Parameter."
			
		}

		if ($PSBoundParameters['Password'])
		{

			Write-Warning "The -Username parameter will be deprecated in a future release. Please transition to using the -Credental Parameter."

		}

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

		if (-not($PSBoundParameters['Password']) -and $PSBoundParameters['Username'])
		{

			do 
			{
				
				$securepass   = Read-Host 'Password' -AsSecureString
				$securepass2  = Read-Host 'Confirm Password' -AsSecureString
				$_DecryptPassword  = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepass))
				$_DecryptPassword2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepass2))

				if ($_DecryptPassword -ne $_DecryptPassword2)
				{

					Write-Host "Passwords do not match!" -BackgroundColor Red

				}

			} until ($_DecryptPassword -eq $_DecryptPassword2)
			
		}

		elseif ($Password -is [SecureString])
		{

			$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

		}

		elseif ($PSBoundParameters['Password'])
		{

			$_DecryptPassword = $Password

		}

		elseif ($PSBoundParameters['Credential'])
		{

			$Username = $Credential.Username
			$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

		}

		else
		{

			$ExceptionMessage = 'Please provide valid credentials using either -Username/-Password or -Credential parameters.'
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.LdapAuthenticationException NoValidCredentialParameters AuthenticationError "ApplianceConnection" -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_AuthDirectorySettings = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{
		
			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			$_NewAuthDirectoryObj = NewObject -AuthDirectory
		
			$_NewAuthDirectoryObj.name                = $Name
			$_NewAuthDirectoryObj.baseDN              = $BaseDN
			$_NewAuthDirectoryObj.credential.userName = $Username
			$_NewAuthDirectoryObj.credential.password = $_DecryptPassword

			if ($ServiceAccount)
			{

				"[{0}] Setting provided user credential as Service Account." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_NewAuthDirectoryObj.directoryBindingType = $LdapDirectoryAccountBindTypeEnum['SERVICEACCOUNT']

			}
		
			"[{0}] Validating Server object values" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			ForEach ($_Server in $Servers)
			{

				if ($_Server -is [PSCustomObject] -and $_Server.type -eq 'LoginDomainDirectoryServerInfoDto')
				{

					$__Server = $_Server.PSObject.Copy()

					# Process the certificate if included, which means TrustLeafCertificate was used with New-HPOVLdapServer
					if (-not [System.String]::IsNullOrWhiteSpace($_DirectoryServer.directoryServerCertificateBase64Data))
					{

						"[{0}] Adding directory server certificate to appliance trust store" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						# Add the SSL certificate to the appliance
						$_CertObject = NewObject -ApplianceTrustedSslCertificate
						$_CertObject.aliasName  = '{0}_{1}' -f $Name, $__Server.directoryServerIpAddress
						$_CertObject.base64Data = $__Server.directoryServerCertificateBase64Data

						$_CertToImportCollection = [PSCustomObject]@{

							type = 'CertificateInfoV2';
							certificateDetails = New-Object System.Collections.ArrayList

						}

						[void]$_CertToImportCollection.certificateDetails.Add($_CertObject)

						Try
						{

							$Null = Send-HPOVRequest -Uri $ApplianceTrustedSslHostStoreUri -Method POST -Body $_CertToImportCollection -AddHeader @{Forcesaveleaf = $true} -Hostname $_appliance | Wait-HPOVTaskComplete

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingErro($_)

						}

						$__Server.directoryServerCertificateBase64Data = $null

					}

					[void]$_NewAuthDirectoryObj.directoryServers.Add($__Server)

				}

				else
				{

					$ExceptionMessage = "The Servers Parameter contains an invalid Server object: {0}.  Please correct this value and try again." -f $_Server.name
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.LdapDirectoryException InvalidDirectoryServer InvalidArgument 'Servers' -TargetType ($_Server.GetType().Name) -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			if ($PSBoundParameters['OpenLDAP'])
			{

				$_NewAuthDirectoryObj.authProtocol        = 'LDAP'
				$_NewAuthDirectoryObj.userNamingAttribute = $UserNamingAttribute

				ForEach ($_ou in $OrganizationalUnits)
				{

					if ($_ou.type -match $OrganizationalUnitPattern)
					{

						[void]$_NewAuthDirectoryObj.orgUnits.Add($_ou)

					}

					else
					{

						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.LdapDirectoryException InvalidDirectoryServer InvalidArgument 'OrganizationalUnits' -Message "The OrganizationalUnits Parameter contains an invalid OU value: '$_ou'.  Please correct this value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

			}

			Try
			{

				# API is broken
				# "[{0}] Validating authentication directory setting is valid" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# $_validateresp = Send-HPOVRequest -Uri $authnProviderValidatorUri -Method POST  -Body $_NewAuthDirectoryObj -Hostname $_appliance

				"[{0}] Submitting request to create new authentication directory" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_resp = Send-HPOVRequest -Uri $authnProvidersUri -Method POST -Body $_NewAuthDirectoryObj -Hostname $_appliance

				$_resp.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AuthDirectory")

				[void]$_AuthDirectorySettings.Add($_resp)

			}

			Catch
			{

				foreach ($NestedError in (${Global:ResponseErrorObject} | Where-Object Name -eq $_appliance.Name).ErrorResponse.nestedErrors) 
				{

					if ($NestedError.errorCode -eq "AUTHN_LOGINDOMAIN_SERVER_AUTHENTICATION_ERROR" ) 
					{ 
						
						$ErrorCategory = 'AuthenticationError' 

					}

					elseif ($NestedError.errorCode -eq "AUTHN_LOGINDOMAIN_DUPLICATE_NAME" ) 
					{ 
						
						$ErrorCategory = 'ResourceExists' 

					}

					else 
					{ 
						
						$ErrorCategory = 'InvalidOperation' 
					
					}

					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.LdapDirectoryException $NestedError.errorCode $ErrorCategory "New-HPOVLdapDirectory" -Message "$($NestedError.message) $($NestedError.details)"
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.LdapDirectoryException InvalidResult InvalidOperation 'New-HPOVLdapDirectory' -Message "$((${Global:ResponseErrorObject} | ? Name -eq $_appliance.Name).ErrorResponse.message) $((${Global:ResponseErrorObject} | ? Name -eq $_appliance.Name).ErrorResponse.details)"
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

	}

	End 
	{

		Return $_AuthDirectorySettings
	   
	}

}
