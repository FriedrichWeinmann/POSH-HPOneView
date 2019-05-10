function Add-HPOVLdapServer
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param
	(
		
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'default')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'PSCredential')]
		[ValidateNotNullorEmpty()]
		[PSCustomObject]$InputObject,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[Parameter (Mandatory, ParameterSetName = "PSCredential")]
		[ValidateNotNullorEmpty()]
		[Alias ("Name")]
		[String]$Hostname,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "PSCredential")]
		[Alias ('port')]
		[ValidateRange (1,65535)]
		[Int32]$SSLPort = 636,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "PSCredential")]
		[Alias ('cert')]
		[Object]$Certificate,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('u','user')]
		[String]$Username,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('p','pass')]
		[Object]$Password,
		
		[Parameter (Mandatory, ParameterSetName = "PSCredential")]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "PSCredential")]
		[Switch]$TrustLeafCertificate,

		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = 'PSCredential')]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection

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

		if (-not $InputObject) 
		{

			$PipelineINput = $true

		}

		else
		{

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

	}

	Process 
	{

		Try
		{

			$Parameters = @{

				Hostname = $Hostname;

			}

			if ($SSLPort)
			{

				$Parameters.Add("SSLPort", $SSLPort)
				
			}
			
			if ($Certificate)
			{

				$Parameters.Add("Certificate", $Certificate)

			}
			
			if ($TrustLeafCertificate)
			{

				$Parameters.Add("TrustLeafCertificate", $TrustLeafCertificate.IsPresent)

			}

			$_LdapServer = BuildLdapServer @Parameters

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		# "[{0}] New Auth Directory Server Object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $($_ldapServer | Format-List * ) | Write-Verbose

		"[{0}] Processing Auth Directory value" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if ($InputObject.category -ne 'users')
		{

			$ExceptionMessage = "The Directory resource is not an expected category type [{0}].  Allowed resource category type is 'users'.  Please check the object provided and try again." -f $InputObject.category
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument $InputObject.Name -TargetType PSObject -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Add credentials to object
		if ($InputObject.directoryBindingType -eq $LdapDirectoryAccountBindTypeEnum['USERACCOUNT'])
		{

			$InputObject.credential = @{ userName = $Username; password = $_DecryptPassword }

		}

		else
		{

			$InputObject.credential.userName = $Username
			$InputObject.credential.password = $_DecryptPassword

		}		

		# Rebuild directoryServers property
		$_DirectoryServers = $InputObject.directoryServers.Clone()

		$InputObject.directoryServers = New-Object System.Collections.ArrayList

		[Void]$InputObject.directoryServers.Add($_ldapServer)

		ForEach ($_Server in $_DirectoryServers)
		{

			[Void]$InputObject.directoryServers.Add($_Server)

		}

		Try
		{

			$_resp = Send-HPOVRequest -Uri $InputObject.Uri -Method PUT -Body $InputObject -Hostname $InputObject.ApplianceConnection.Name

			$_resp.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AuthDirectory")

			$_resp

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}	

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
