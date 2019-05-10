function New-HPOVLdapServer 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Name')]
		[String]$Hostname,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Alias ('port')]
		[ValidateRange (1,65535)]
		[Int32]$SSLPort = 636,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Alias ('cert')]
		[Object]$Certificate,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Switch]$TrustLeafCertificate

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose
		
		$_AuthDirectoryServer = New-Object System.Collections.ArrayList

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


		# Add the directory server to the provided Auth Directory
		if ($InputObject)
		{

			"[{0}] Processing Auth Directory value" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($InputObject.category -ne 'users')
			{

				$ExceptionMessage = "The Directory resource is not an expected category type [{0}].  Allowed resource category type is 'users'.  Please check the object provided and try again." -f $InputObject.category
				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument $InputObject.Name -TargetType PSObject -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if (-not($PSBoundParameters['Password']))
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

			else 
			{

				$_DecryptPassword = $Password

			}

			# Add credentials to object
			$InputObject.credential = @{ userName = $Username; password = $_DecryptPassword }

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

		else
		{

			"[{0}] Return directory server object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_ldapServer

		}		

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
