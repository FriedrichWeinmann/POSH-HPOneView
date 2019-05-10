function New-HPOVApplianceSelfSignedCertificate 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default', SupportsShouldProcess, ConfirmImpact = 'High')]

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
			
		$_SelfSignedCertObject = NewObject -SelfSignedCert

		$_SelfSignedCertObject.country            =  $Country.ToUpper()
		$_SelfSignedCertObject.state              =  $State
		$_SelfSignedCertObject.locality           =  $City
		$_SelfSignedCertObject.organization       =  $Organization
		$_SelfSignedCertObject.commonName         =  $CommonName
		$_SelfSignedCertObject.organizationalUnit =  $OrganizationalUnit
		$_SelfSignedCertObject.alternativeName    =  $AlternativeName
		$_SelfSignedCertObject.contactPerson      =  $ContactName
		$_SelfSignedCertObject.email              =  $Email
		$_SelfSignedCertObject.surname            =  $Surname
		$_SelfSignedCertObject.givenName          =  $GivenName
		$_SelfSignedCertObject.initials           =  $Initials
		$_SelfSignedCertObject.dnQualifier        =  $DNQualifier

		Try
		{

			Write-Warning 'Updates to the certificate will require the appliance internal web server to be restarted. There will be a temporary service interruption estimated to last 30 seconds.'

			if ($PSCmdlet.ShouldProcess($ApplianceConnection.Name,"generate new self-signed certificate"))
			{    

				"[{0}] Generating new self-signed certificate." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_resp = Send-HPOVRequest -Uri $applianceSslCert -Method POST -Body $_SelfSignedCertObject -HostName $ApplianceConnection
		
			}

			else 
			{

				if ($PSBoundParameters['whatif'].ispresent) 
				{ 

					write-warning "-WhatIf was passed, would have proceeded 'New Self-Signed Certificate for Appliance $($ApplianceConnection.Name)'."

					$_resp = $null

				}

				else 
				{

					# If here, user chose "No", End Processing
					$_resp = $Null

				}

			}

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
