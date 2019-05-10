function New-HPOVApplianceCsr 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]

	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Alias ('C')]
		[ValidateNotNullOrEmpty()]
		[string]$Country,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Alias ('ST','Province')]
		[ValidateNotNullOrEmpty()]	
		[string]$State,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Alias ('L','Locality')]	
		[ValidateNotNullOrEmpty()]
		[string]$City,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Alias ('O')]
		[ValidateNotNullOrEmpty()]
		[string]$Organization,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Alias ('CN')]
		[ValidateNotNullOrEmpty()]
		[string]$CommonName,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Alias ('OU')]	
		[ValidateNotNullOrEmpty()]
		[string]$OrganizationalUnit,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Alias ('SAN')]	
		[ValidateNotNullOrEmpty()]
		[string]$AlternativeName,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Alias ('Contact')]	
		[ValidateNotNullOrEmpty()]
		[string]$ContactName,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[string]$Email,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Alias ('Sur')]	
		[ValidateNotNullOrEmpty()]
		[string]$Surname,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Alias ('Giv')]	
		[ValidateNotNullOrEmpty()]
		[string]$GivenName,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[string]$Initials,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[string]$DNQualifier,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[string]$ChallengePassword,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Alias ('UN')]	
		[ValidateNotNullOrEmpty()]
		[string]$UnstructuredName,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Bool]$CnsaCompliantRequest = $false,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
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

		$_TaskStatus = New-Object System.Collections.ArrayList

		# Handle runtime, none-script use
		if ($PSBoundParameters['ChallengePassword'] -and $ChallengePassword -eq '*'  ) 
		{

			Do 
			{

				[SecureString]$ChallengePassword        = Read-Host "Challenge Password:" -AsSecureString

				[SecureString]$ChallengePasswordConfirm = Read-Host "Confirm Challenge Password:" -AsSecureString

				$pwd1_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ChallengePassword))

				$pwd2_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ChallengePasswordConfirm))

				if (-not($pwd1_text -ceq $pwd2_text)) 
				{

					Write-Error "Passwords to not match. Please try again." -ea Continue

					$PasswordsMatch = $False

				}

				else { $PasswordsMatch = $True }

			} Until ($PasswordsMatch)

		}

		if ($Country.length -gt 2)
		{

			$TempCountry = $Country.Clone()

			$Country = GetTwoLetterCountry -Name $Country

			if (-not($Country))
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException CountryNameNotFound ObjectNotFound 'Country' -Message ('{0} is not a valid Country Name, or unable to find mapping to RegionInfo ISO3166-2 compliant 2-Character name.' -f $Country )
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

	}

	Process 
	{

		$_CsrObject = NewObject -ApplianceCSR

		$_CsrObject.country            =  $Country.ToUpper()
		$_CsrObject.state              =  $State
		$_CsrObject.locality           =  $City
		$_CsrObject.organization       =  $Organization
		$_CsrObject.commonName         =  $CommonName
		$_CsrObject.organizationalUnit =  $OrganizationalUnit
		$_CsrObject.alternativeName    =  $AlternativeName.Replace(" ", $null) # Remove spaces?
		$_CsrObject.contactPerson      =  $ContactName
		$_CsrObject.email              =  $Email
		$_CsrObject.surname            =  $Surname
		$_CsrObject.givenName          =  $GivenName
		$_CsrObject.initials           =  $Initials
		$_CsrObject.dnQualifier        =  $DNQualifier
		$_CsrObject.unstructuredName   =  $UnstructuredName
		$_CsrObject.challengePassword  =  $ChallengePassword

		Try
		{

			"[{0}] Sending CSR request" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_resp = Send-HPOVRequest -Uri $applianceCsr -Method POST -Body $_CsrObject -HostName $ApplianceConnection
				
			[void]$_TaskStatus.Add($_resp)

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}


	}

	End 
	{

		Return $_TaskStatus

	}

}
