function Invoke-HPOVVcmMigration 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = "High")]
	Param
	(

		[Parameter (Mandatory, ParameterSetName = "Report")]	
		[Parameter (Mandatory, ParameterSetName = "VCEMMigration")]
		[Parameter (Mandatory, ParameterSetName = "Default")]
		[Alias ('oip')]
		[ValidateNotNullOrEmpty()]
		[System.String]$OAIPAddress,

		[Parameter (Mandatory = $false, ParameterSetName = "Report")]
		[Parameter (Mandatory = $false, ParameterSetName = "VCEMMigration")]
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('ou')]
		[ValidateNotNullOrEmpty()]
		[System.String]$OAUserName,

		[Parameter (Mandatory = $false, ParameterSetName = "Report")]
		[Parameter (Mandatory = $false, ParameterSetName = "VCEMMigration")]
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('op')]
		[ValidateNotNullOrEmpty()]
		[System.Object]$OAPassword,

		[Parameter (Mandatory = $false, ParameterSetName = "Report")]
		[Parameter (Mandatory = $false, ParameterSetName = "VCEMMigration")]
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[PSCredential]$OACredential,

		[Parameter (Mandatory = $false, ParameterSetName = "Report")]
		[Parameter (Mandatory = $false, ParameterSetName = "VCEMMigration")]
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('vu')]
		[ValidateNotNullOrEmpty()]
		[System.String]$VCMUserName,

		[Parameter (Mandatory = $false, ParameterSetName = "Report")]
		[Parameter (Mandatory = $false, ParameterSetName = "VCEMMigration")]
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('vp')]
		[ValidateNotNullOrEmpty()]
		[System.Object]$VCMPassword,

		[Parameter (Mandatory = $false, ParameterSetName = "Report")]
		[Parameter (Mandatory = $false, ParameterSetName = "VCEMMigration")]
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[PSCredential]$VCMCredential,

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "Report")]
		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "VCEMMigration")]
		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "Default")]
		[Alias ('eg')]
		[ValidateScript({
			if (($_ -is [String]) -and ($_.StartsWith('/rest/')) -and (-not ($_.StartsWith('/rest/enclosure-groups')))) { Throw "'$_' is not an allowed resource URI.  Enclosure Group Resource URI must start with '/rest/enclosure-groups'. Please check the value and try again." } 
			elseif ($_ -is [String] -and ($_.StartsWith('/rest/'))) { $True }
			elseif ($_ -is [String]) { $True }
			
			elseif (($_ -is [PSCustomObject]) -and (-not ($_.category -eq "enclosure-groups"))) { 
			
				if ($_.category) { Throw "'$_.category' is not an allowed resource category.  The resource object category must be 'enclosure-groups'. Please check the value and try again." }
				else { Throw "The object provided does not contain an the allowed resource category 'enclosure-groups'. Please check the value and try again." }
			}
			else { $True } })]
		[Object]$EnclosureGroup,

		[Parameter (Mandatory = $false, ParameterSetName = "Report")]
		[Parameter (Mandatory = $false, ParameterSetName = "VCEMMigration")]
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('lig')]
		[ValidateScript({
			if (($_ -is [String]) -and ($_.StartsWith('/rest/')) -and (-not ($_.StartsWith('/rest/logical-interconnect-groups')))) { Throw "'$_' is not an allowed resource URI.  Logical Interconnect Group Resource URI must start with '/rest/logical-interconnect-groups'. Please check the value and try again." } 
			elseif ($_ -is [String] -and ($_.StartsWith('/rest/'))) { $True }
			elseif ($_ -is [String]) { $True }
			
			elseif (($_ -is [PSCustomObject]) -and (-not ($_.category -eq "logical-interconnect-groups"))) { 
			
				if ($_.category) { Throw "'$_.category' is not an allowed resource category.  The resource object category must be 'logical-interconnect-groups'. Please check the value and try again." }
				else { Throw "The object provided does not contain an the allowed resource category 'logical-interconnect-groups'. Please check the value and try again." }
			}
			else { $True } })]
		[Object]$LogicalInterconnectGroup,

		[Parameter (Mandatory, ParameterSetName = "Report")]
		[Parameter (Mandatory, ParameterSetName = "VCEMMigration")]
		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateSet ("OneView", "OneViewNoiLO", IgnoreCase = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ("license", "l")]
		[System.String]$LicensingIntent,

		[Parameter (Mandatory, ParameterSetName = "VCEMMigration")]
		[String]$VCEMCMS,

		[Parameter (Mandatory = $false, ParameterSetName = "VCEMMigration")]
		[String]$VCEMUser,

		[Parameter (Mandatory = $false, ParameterSetName = "VCEMMigration")]
		[System.Object]$VCEMPassword,

		[Parameter (Mandatory = $false, ParameterSetName = "VCEMMigration")]
		[PSCredential]$VCEMCredential,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('NoWait')]
		[Switch]$Async,

		[Parameter (Mandatory, ParameterSetName = "Report")]
		[Switch]$Report,

		[Parameter (Mandatory = $false, ParameterSetName = "Report")]
		[Alias ("Export")]
		[ValidateScript({
			if ({split-path $_ | Test-Path}) { $True } 
			else { Throw "'$(Split-Path $_)' is not a valid directory.  Please verify $(Split-Path $_) exists and try again." } 
			})]
		[System.IO.FileInfo]$Path,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "VCEMMigration")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Report")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
		
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

		Switch ($PSBoundParameters.Keys)
		{

			'OAUsername'
			{

				Write-Warning "OAUsername paramter is being deprecated.  Please upsate and use the -OACredential parameter."

			}

			'OAPassword'
			{

				Write-Warning "OAPassword paramter is being deprecated.  Please upsate and use the -OACredential parameter."

			}

			'VCMUsername'
			{

				Write-Warning "VCMUsername paramter is being deprecated.  Please upsate and use the -VCMCredential parameter."

			}

			'VCMPassword'
			{

				Write-Warning "VCMPassword paramter is being deprecated.  Please upsate and use the -VCMCredential parameter."

			}

			'VCEMUsername'
			{

				Write-Warning "VCEMUsername paramter is being deprecated.  Please upsate and use the -VCEMCredential parameter."

			}

			'VCEMPassword'
			{

				Write-Warning "VCEMPassword paramter is being deprecated.  Please upsate and use the -VCEMCredential parameter."

			}

		}

		if ($OACredential)
		{

			$OAUsername  = $OACredential.Username
			$_OAPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OACredential.Password))

		}

		else
		{

			if ($OAPassword -is [SecureString])
			{

				$_OAPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OAPassword))
				
			}

			else
			{

				$_OAPassword = $OAPassword.clone()

			}

		}

		if ($VCMCredential)
		{

			$VCMUserName  = $VCMCredential.Username
			$_VCMPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($VCMCredential.Password))

		}

		else
		{

			if ($VCMPassword -is [SecureString])
			{

				$_VCMPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($VCMPassword))

			}

			else
			{

				$_VCMPassword = $VCMPassword.clone()

			}

		}

		if ($VCEMCredential)
		{

			$VCEMUsername  = $VCEMCredential.Username
			$_VCEMPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($VCEMCredential.Password))

		}

		elseif ($VCEMUser)
		{

			if ($VCEMPassword -is [SecureString])
			{

				$_VCEMPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($VCEMPassword))

			}

			else
			{

				$_VCEMPassword = $VCEMPassword.clone()

			}

		}

	}
	
	Process 
	{

		$VcMigrationObject = NewObject -vcMigration
		
		$VcMigrationObject.iloLicenseType          = $LicensingIntent
		$VcMigrationObject.credentials.oaIpAddress = $OAIPAddress
		$VcMigrationObject.credentials.oaUsername  = $OAUserName
		$VcMigrationObject.credentials.oaPassword  = $_OAPassword
		$VcMigrationObject.credentials.vcmUsername = $VCMUserName
		$VcMigrationObject.credentials.vcmPassword = $_VCMPassword

		# Check to see if EnclosureGroup was provided
		if ($PSBoundParameters['EnclosureGroup']) 
		{
		
			switch ($EnclosureGroup.Gettype().Name) 
			{

				# Validate the String value
				"String" 
				{ 
				
					# The value is an Enclosure Group URI
					if ($EnclosureGroup.startswith('/rest/enclosure-groups')) 
					{

						"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Enclosure Group URI provided: $EnclosureGroup" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					   
						$VcMigrationObject.enclosureGroupUri = $EnclosureGroup

					}

					# The value is an enclosure group name
					else 
					{
						
						# Enclosure group name provided.  Check if this is for a custom EG and LIG (LIG name also provided), or existing EG
						"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Enclosure Group Name provided: $EnclosureGroup" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						try 
						{ 
							
							$eg = (Get-HPOVEnclosureGroup -Name $EnclosureGroup -ErrorAction Stop -appliance $ApplianceConnection).uri 
								
							# Add the URI property to the migration object
							$VcMigrationObject.enclosureGroupUri = $eg
								
						}

						catch 
						{

							"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Enclosure Group '$EnclosureGroup' not found. Specifying custom Enclosure Group Name." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							$VcMigrationObject | Add-Member -NotePropertyName "enclosureGroupName" -NotePropertyValue $EnclosureGroup -force

						}

					}
					
				}

				"PSCustomObject" 
				{
			
					"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Enclosure Group resource object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnclosureGroup.name, $EnclosureGroup.uri | Write-Verbose
					$VcMigrationObject.enclosureGroupUri = $EnclosureGroup.uri
			
				}

			}# SWITCH

		}# If EG provided

		# Check to see if LogicalInterconnectGroup was provided
		if ($PSBoundParameters['LogicalInterconnectGroup']) 
		{
		
			switch ($LogicalInterconnectGroup.Gettype().Name) 
			{

				# Validate the String value
				"String" 
				{ 
				
					# The value is an Enclosure Group URI
					if ($LogicalInterconnectGroup.startswith('/rest/logical-interconnect-groups')) 
					{

						"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Logical Interconnect Group URI provided: $LogicalInterconnectGroup" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						$VcMigrationObject.logicalInterconnectGroupUri = $LogicalInterconnectGroup

					}

					# The value is an Logical Interconnect group name
					else 
					{
						
						# Enclosure group name provided.  Check if this is for a custom EG and LIG (LIG name also provided), or existing EG
						"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Logical Interconnect Group Name provided: $LogicalInterconnectGroup" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						try 
						{ 
							
							$lig = (Get-HPOVLogicalInterconnectGroup -Name $LogicalInterconnectGroup -ErrorAction Stop -appliance $ApplianceConnection).uri 
								
							# Add the URI property to the migration object
							$VcMigrationObject.logicalInterconnectGroupUri = $lig
								
						}

						catch 
						{

							"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Logical Interconnect Group '$LogicalInterconnectGroup' not found. Specifying custom Logical Interconnect Group Name." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							$VcMigrationObject | Add-Member -NotePropertyName logicalInterconnectGroupName -NotePropertyValue $LogicalInterconnectGroup -force

						}

					}
					
				}

				"PSCustomObject" 
				{
			
					"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Logical Interconnect Group resource object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnectGroup.name, $LogicalInterconnectGroup.uri | Write-Verbose
					$VcMigrationObject.logicalInterconnectGroupUri  = $LogicalInterconnectGroup.uri
			
				}

			}# SWITCH

		}# If EG provided

		# Send the POST and retrieve the Uri for the MigratableVcDomain resource

		Try
		{

			$thisTask = Send-HPOVRequest -method POST -uri $VCMigratorUri -body $VcMigrationObject -appliance $ApplianceConnection | Wait-HPOVTaskComplete

		}
		
		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}
		
		if ($thisTask.taskState -ieq "Error") 
		{

			$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException $thisTask.taskErrors.errorCode InvalidArgument 'Invoke-HPOVVcMigration' -Message "$($thisTask.taskErrors.message)"
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# If we get here, task was successful. Get the migration resource
		$vcMigrationReport = MigrationReport $thisTask

		$EnclosureName = $vcMigrationReport.apiVcMigrationReport.enclosureName

		if ($Path) 
		{

			[Array]$Output = @()

			$Output += $vcMigrationReport.apiVcMigrationReport | Format-Table $a -AutoSize -wrap
			$Output += $vcMigrationReport.apiVcMigrationReport| Format-Table $b -AutoSize -wrap
			$Output += $vcMigrationReport.outReport | Sort-Object severity | Format-List $i

			$outFile = "$Path\$($vcMigrationReport.apiVcMigrationReport.enclosureName)_$(get-date -uformat %Y%m%d).report"

			$vcMigrationReport.outReport += "Generated on $(get-date -uformat %c)"

			Out-File -InputObject $Output -FilePath $outFile -Encoding utf8 -force -confirm:$false

			write-host "Report saved to: " -nonewline -ForegroundColor Green
			write-host "$outFile" -ForegroundColor Yellow

		}

		else 
		{

			# Generate and return the report
			""
			"Migration Compatibility Report"
			"------------------------------"
			""
			$vcMigrationReport.apiVcMigrationReport | Format-Table $a -AutoSize -wrap
			$vcMigrationReport.apiVcMigrationReport| Format-Table $b -AutoSize -wrap
			$vcMigrationReport.outReport | Sort-Object severity | Format-List $i

		}

		# Generate terminating error if caller didn't include VCEMCMS Parameter and $vcMigrationReport.VcemManaged is True
		if (-not ($PSBoundParameters["vcemcms"]) -and $vcMigrationReport.VcemManaged) 
		{

			$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException VCEMCMSParameterMissing InvalidArgument 'VCEMCMS' -Message "The Enclosure is currently managed by a Virtual Connect Enterprise Manager (VCEM) CMS, and the -VCEMCMS Parameter was not provided.  Please provide the required Parameter and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
		}
		
		# $_ServicePointManagerOriginalState = [System.Net.ServicePointManager]::ServerCertificateValidationCallback # Workaround self-signed certificates on OA and VCEM CMS
		# [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

		if ($VCEMCMS -and $vcMigrationReport.VcemManaged -and ($vcMigrationReport.apiVcMigrationReport.criticalCount -le 1) -and (-not ($Report.IsPresent))) 
		{

			"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Entering Eject VCM from VCEM DG Process" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	   
			$oaUrl = "https://{0}/xmldata?item=all" -f $OAIPAddress

			'[{0}] {1} - Building SOAP Request to OA: {2}' -f $MyInvocation.InvocationName.ToString().ToUpper(), (Get-Date -UFormat "%Y-%m-%d %T"), $oaUrl | Write-Verbose

			try 
			{

				$soapWebRequest        = [System.Net.WebRequest]::Create($oaUrl) 
				$soapWebRequest.Accept = "text/xml" 
				$soapWebRequest.Method = "GET" 
				$resp                  = $soapWebRequest.GetResponse() 
				$responseStream        = $resp.GetResponseStream() 
				$soapReader            = [System.IO.StreamReader]($responseStream) 
				$ReturnXml             = [Xml] $soapReader.ReadToEnd() 

				$responseStream.Close() 
				$resp.Close()

				$soapWebRequest = $Null
				
				"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Response received: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $returnXML.OuterXml | Write-Verbose
	
			}

			catch [Net.WebException]
			{

				if ($_.exception.InnerException -match "The remote name could not be resolved") 
				{

					$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException OnboardAdministratorUnavailable ResourceUnavailable 'OAIP' -Message "$($_.exception.InnerException)"
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				else 
				{

					$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException $_.FullyQualifiedErrorId ResourceUnavailable 'OAIP' -Message "$($_.exception.message)"
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				}

			}

			catch 
			{

				$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException $_.FullyQualifiedErrorId ResourceUnavailable 'OAIP' -Message "$($_.exception.message)"
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			# Received valid OA XML reply
			if ($ReturnXml.RIMP.INFRA2) 
			{ 
	
				if ($ReturnXml.RIMP.INFRA2.VCM.vcmMode -eq "true") 
				{
			
					$vcDomainName = $ReturnXml.RIMP.INFRA2.VCM.vcmDomainName
					"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Found VC Domain from OA:  '$vcDomainName'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							
				}

				else 
				{

					$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException NoVCDomainFound ResourceUnavailable 'OAIP' -Message "Enclosure is not managed by VCM or no valid VC Domain Found."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}
	
			}
	
			# Reply will not have any returned data beyond the RIMP XML node, so generate error
			else 
			{

				$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException NoVCDomainFound ResourceUnavailable 'OAIP' -Message "No data provided from XML Interface. Is it disabled?"
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			# VCEM CodeBlock
			# Use the mvcd7_3 API Endpoint
			$XmlAuth = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v7="http://v7_3.api.mvcd.hp.com">
							<soapenv:Header/>
							<soapenv:Body>
								<v7:login>
									<String_1>{0}</String_1>
									<String_2>{1}</String_2>
								</v7:login>
							</soapenv:Body>
						</soapenv:Envelope>' -f $VCEMUser, $_VCEMPassword
			
			"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") $(get-date -UFormat `"%Y-%m-%d %T`") Authenticating to VCEM CMS host: $VCEMCMS." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			try 
			{

				$Uri = "https://$($VCEMCMS):50000/mvcd7_3/SoapApi"
				$reply = Invoke-WebRequest -uri $Uri -Method POST -ContentType "text/xml" -Body $XmlAuth

			}

			catch [System.Net.WebException] 
			{

				if ($_.exception -match "The remote name could not be resolved") 
				{
				
					$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException VcemHostUnavailable ResourceUnavailable 'VCEMCMS' -Message "The VCEM host '$VCEMCMS' remote name could not be resolved. Please check the name and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)	

				}
				
				else 
				{ 

					"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") [System.Net.WebException] Error Caught: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_.Exception.Response | Write-Verbose

					$ResponseCode = [int]$_.Exception.response.statuscode
					$ResponseMessage = $_.Exception.Message

					# Get exception response from Web Service API.
					if ($_.Exception.InnerException) { $HttpWebResponse = $_.Exception.InnerException.Response }
					else { $HttpWebResponse = $_.Exception.Response }

					$rs = $HttpWebResponse.GetResponseStream()
					$reader = New-Object System.IO.StreamReader($rs)
					
					if ($HttpWebResponse.ContentType.Contains("text/xml")) { [XML]$ErrorBodyResponse = $reader.ReadToEnd() }
					else { $ErrorBodyResponse = $reader.ReadToEnd() }

					switch ([int]$ResponseCode) 
					{
					
						404 
						{  

							"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") [System.Net.WebException] SOAP API Endpoint not found" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
							$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException VCEMSoapAPIEndPointNotFound ResourceUnavailable 'VCEMCMS' -Message "The provided VCEM CMS host '$VCEMCMS' does not have the VCEM role of HP Insight Software installed.  Please verify the VCEMCMS Parameter value and try again."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
						}

						default 
						{

							"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") [System.Net.WebException] Internal Server Error or auth exception" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							
							if ($ErrorBodyResponse -is [XML]) 
							{

								$ResponseMessage = $ErrorBodyResponse.Envelope.body.Fault.faultstring

								"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Received XML Response FaultString:  $ResponseMessage" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							
							}              
							
							$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException VCEMSoapApiInternalError InvalidResult 'VCEMCMS' -Message "HTTP '$ResponseCode' Error. $ResponseMessage"
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

				}

			}

			[XML]$ContentResponse = $reply.content
			$AuthToken = $ContentResponse.Envelope.Body.loginResponse.result

			# Check for new VCEM API Endpoint
			$getVcemApiVersion = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v7="http://v7_3.api.mvcd.hp.com">
									<soapenv:Header/>
									<soapenv:Body>
										<v7:getProductVersion>
											<String_1>{0}</String_1>
										</v7:getProductVersion>
									</soapenv:Body>
								  </soapenv:Envelope>'-f $AuthToken

			$Uri = "https://$($VCEMCMS):50000/mvcd7_3/SoapApi"

			Try
			{

				$reply = Invoke-WebRequest -uri $Uri -Method POST -ContentType "text/xml" -Body $getVcemApiVersion

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
			[XML]$ContentResponse = $reply.content
			
			[version]$apiVersion = ($ContentResponse.Envelope.Body.getProductVersionResponse.result) -replace ("Virtual Connect Enterprise Manager v","")
			$apiVersionString = ($ContentResponse.Envelope.Body.getProductVersionResponse.result) -replace ("Virtual Connect Enterprise Manager v","") -replace ("\.","_")

			"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") VCEM API Version found: $apiVersion" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose


			if ($apiVersion -lt 7.3) 
			{

				# Generate error that VCEM version is too old to support patch and instruct caller to upgrade to either 7.3+Patch or 7.4.1
				$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException VcemVersionTooOld ResourceUnavailable 'VCEMCMS' -Message "The VCEM host '$VCEMCMS' version '$($apiVersion.ToString())' is not supported. Please upgrade your VCEM CMS to at least 7.3 and obtain the VCEM 7.3/7.4 Patch (ftp://ftp.hp.com/pub/softlib2/software1/pubsw-generic/p270829882/v106568) and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			# Locate VCM Domain within VCEM
			$FindVCDomainByNameRequest = '<s11:Envelope xmlns:s11="http://schemas.xmlsoap.org/soap/envelope/">
											<s11:Body>
												<ns1:findVCDomainByName xmlns:ns1="http://v7_3.api.mvcd.hp.com">
												<String_1>{0}</String_1>
												<String_2>{1}</String_2>
												</ns1:findVCDomainByName>
											</s11:Body>
										  </s11:Envelope>' -f $AuthToken, $VCDomainName

			"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Looking for '$vcDomainName' VC Domain on VCEM host." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$reply = Invoke-WebRequest -uri $Uri -Method POST -ContentType "text/xml" -Body $FindVCDomainByNameRequest

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			[xml]$findVCDomainByNameResponse = $reply.content

			if ($findVCDomainByNameResponse.Envelope.body.findVCDomainByNameResponse.result.nil) 
			{

				$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException NoVCDomainFound ResourceUnavailable 'OAIP' -Message "No data provided from XML Interface. Is it disabled?"
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Found VC Domain: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $findVCDomainByNameResponse.Envelope.body.findVCDomainByNameResponse.result | Write-Verbose

			if ($findVCDomainByNameResponse.Envelope.body.findVCDomainByNameResponse.result.status -eq "LICENSED_UNMANAGED") 
			{

				Write-Warning "'$vcDomainName' is not currently managed by the VCEM CMS host."
				Return

			}

			$vcemDomainId = $findVCDomainByNameResponse.Envelope.body.findVCDomainByNameResponse.result.vcDomainId

			"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Attempting to remove VC Domain from VCEM Domain Group" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($PSCmdlet.ShouldProcess($vcDomainName,"Remove VC Domain From VC Domain Group")) 
			{

				if ($apiVersion -ge "7.4.1") 
				{ 
				
					$uri = "https://$($VCEMCMS):50000/mvcd$($apiVersionString)/SoapApi" 
					$nameSpaceVer = "v$($apiVersionString)"
				}

				else 
				{ 
				
					$uri = "https://$($VCEMCMS):50000/mvcdExtra/SoapApi" 
					$nameSpaceVer = "vExtra"
						
				}

				$removeVcDomainRequest = '<s11:Envelope xmlns:s11="http://schemas.xmlsoap.org/soap/envelope/">
											<s11:Body>
											<ns1:removeVcDomainFromGroup xmlns:ns1="http://$nameSpaceVer.api.mvcd.hp.com">
												<String_1>{0}</String_1>
												<Long_2>{1}</Long_2>
											</ns1:removeVcDomainFromGroup>
											</s11:Body>
										</s11:Envelope>' -f $AuthToken, $vcemDomainId

				# Attempt removeVcDomainFromGroup request to API
				try 
				{

					"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Attempting SOAP Call to '$uri'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$soapWebRequest               = [System.Net.HttpWebRequest]::Create($uri) 
					$soapWebRequest.Accept        = "text/xml" 
					$soapWebRequest.ContentType   = "text/xml"
					$soapWebRequest.Method        = "POST" 
					$bytes                        = [System.Text.Encoding]::UTF8.GetBytes($removeVcDomainRequest) 
					$soapWebRequest.ContentLength = $bytes.Length

					[System.IO.Stream] $outputStream = [System.IO.Stream]$soapWebRequest.GetRequestStream()
					$outputStream.Write($bytes,0,$bytes.Length)  
					$outputStream.Close()

					$resp           = $soapWebRequest.GetResponse() 
					$responseStream = $resp.GetResponseStream() 
					$soapReader     = [System.IO.StreamReader]($responseStream) 
					$reply          = [Xml]$soapReader.ReadToEnd() 
					$responseStream.Close() 
					$resp.Close()
					$soapWebRequest = $Null
					
					"[{0}] {1} Response received: {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), (get-date -UFormat "%Y-%m-%d %T"), $reply.OuterXml | Write-Verbose 
	
				}

				Catch [System.Net.WebException] 
				{

					"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") [System.Net.WebException] exception caught: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_.Exception.Response | Write-Verbose

					$HttpWebResponse = $_.Exception.Response
					$ResponseCode = [int]$_.Exception.response.statuscode
					$ResponseMessage = $_.Exception.Message

					"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Getting error response stream." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					$rs = $HttpWebResponse.GetResponseStream()
					$reader = New-Object System.IO.StreamReader($rs)

					if ($HttpWebResponse.ContentType.Contains("text/xml")) { [XML]$ErrorBodyResponse = $reader.ReadToEnd() }

					else { [String]$ErrorBodyResponse = $reader.ReadToEnd() }

					if ($ErrorBodyResponse -is [String] -and $ErrorBodyResponse.StartsWith("<script>") -and [int]$ResponseCode -eq 404) 
					{ 
					
						"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") [System.Net.WebException] SOAP API Endpoint not found.  Generating terminating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
						$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException VCEMSoapAPIEndPointNotFound ResourceUnavailable 'VCEMCMS' -Message "The provided VCEM CMS host '$VCEMCMS' does not have the required VCEM patch installed.  Please download the patch from (ftp://ftp.hp.com/pub/softlib2/software1/pubsw-generic/p270829882/v106568) and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					elseif ($ErrorBodyResponse -is [XML] -and [int]$HttpWebResponse.StatusCode -eq 500 -and $ErrorBodyResponse.Envelope.Body.Fault.faultstring -match "Failed to parse source: For input string: `"$vcemDomainId`"") 
					{

						"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") '$vcDomainName' was not found on the VCEM host '$VCEMCMS'.  Generating terminating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException VcDomainNotFound ResourceUnavailable 'VCEMCMS' -Message "The Virtual Connect Domain '$vcDomainName' not found on VCEM host '$VCEMCMS'.  Please verify the Virtual Connect Domain is managed by the provided VCEM CMS host and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					elseif ($ErrorBodyResponse -is [XML]) 
					{

						$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException $ErrorBodyResponse.Envelope.Body.Fault.faultcode InvalidResult 'VCEMCMS' -Message "$($ErrorBodyResponse.Envelope.Body.Fault.faultstring)"
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
					}

					else 
					{

						$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException VCEMApiCallGenericError InvalidResult 'VCEMCMS' -Message "HTTP '$ResponseCode ' Error. Message: $ResponseMessage"
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
					}

				}

				$jobId = $reply.Envelope.body.removeVcDomainFromGroupResponse.result

				if (-not ($jobId))
				{

					$ErrorRecord = New-ErrorRecord HPOneview.VCMigratorException InvalidJobIdResult InvalidResult 'VCEMCMS' -Message "A valid VCEM Job ID was not provided."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
				}

				"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Monitoring VCEM Job ID '$jobId'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$Uri = "https://$($VCEMCMS):50000/mvcd7_3/SoapApi"

				$jobMonitorRequest = '<s11:Envelope xmlns:s11="http://schemas.xmlsoap.org/soap/envelope/">
										<s11:Body>
											<ns1:listStatusForMvcdJob xmlns:ns1="http://v7_3.api.mvcd.hp.com">
											<String_1>{0}</String_1>
											<Long_2>{1}</Long_2>
											</ns1:listStatusForMvcdJob>
										</s11:Body>
									  </s11:Envelope>' -f $AuthToken, $jobId

				do 
				{

					# Hide the progress display of Invoke-WebRequest, which adds unecessary tet to the Write-Progress output
					$progressPreference = 'silentlyContinue' 
					$reply = Invoke-WebRequest -uri $Uri -Method POST -ContentType "text/xml" -Body $jobMonitorRequest

					# Reset hidding progress display prior to executing Write-Progress
					$progressPreference = 'Continue'  

					[xml]$jobStatus = $reply.Content

					Write-Verbose $($jobStatus.Envelope.body.listStatusForMvcdJobResponse.result | out-string)
					Write-Verbose $($jobStatus.Envelope.body.listStatusForMvcdJobResponse.result.jobProgress[-1] | out-string)

					if ($jobStatus.Envelope.body.listStatusForMvcdJobResponse.result.jobProgress[-1].progressDescription) { $status = $jobStatus.Envelope.body.listStatusForMvcdJobResponse.result.jobProgress[-1].progressDescription}
					else { $status = "Waiting" }

					if ($jobStatus.Envelope.body.listStatusForMvcdJobResponse.result.jobProgress[-1].percentComplete) { $PrecentComplete = $jobStatus.Envelope.body.listStatusForMvcdJobResponse.result.jobProgress[-1].percentComplete}
					else { $PrecentComplete = 0 }

					Write-Progress -id 2 -Activity $jobStatus.Envelope.body.listStatusForMvcdJobResponse.result.jobName -Status $status -PercentComplete $PrecentComplete

				} Until ($jobStatus.Envelope.body.listStatusForMvcdJobResponse.result.state -eq "COMPLETED" -or $jobStatus.Envelope.body.listStatusForMvcdJobResponse.result -eq "FAILED")
	
				
				# [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $_ServicePointManagerOriginalState # Restore certificate validation

				#Job Failed, terminate
				if ($jobStatus.Envelope.body.listStatusForMvcdJobResponse.result -eq "FAILED") 
				{
				
					$ErrorRecord = New-ErrorRecord HPOneView.VCMigratorException $thisTask.taskErrors.errorCode InvalidArgument 'Invoke-HPOVVcMigration' -Message "$($thisTask.taskErrors.message)"
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
				}           
				
				Write-Progress -id 2 -Activity $jobStatus.Envelope.body.listStatusForMvcdJobResponse.result.jobName -Completed

				"[{0}] $(get-date -UFormat `"%Y-%m-%d %T`") Checking Compatibility again." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Check for report status now
				Try
				{

					$thisTask = Send-HPOVRequest -method POST -uri $VCMigratorUri -body $VcMigrationObject -appliance $ApplianceConnection | Wait-HPOVTaskComplete

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}                

				if ($thisTask.taskState -ieq "Error") 
				{

					$ErrorRecord = New-ErrorRecord HPOneView.VCMigratorException $thisTask.taskErrors.errorCode InvalidResult 'Invoke-HPOVVcMigration' -Message "$($thisTask.taskErrors.message)"
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# If we get here, task was successful. Generate new VCMMigrator report
				$vcMigrationReport = MigrationReport $thisTask

				if ($vcMigrationReport.apiVcMigrationReport.migrationState -eq "UnableToMigrate") 
				{

					$ErrorRecord = New-ErrorRecord HPOneView.VCMigratorException UnableToMigrateVCDomain InvalidResult 'Invoke-HPOVVcMigration' -Message "The VC Domain in unable to be migrated due to $($vcMigrationReport.apiVcMigrationReport.highCount) Critical Issues.  Please examine the VC Migration Report to identify what needs to be resolved before migration can continue."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# Generate and return the report
				""
				"Migration Compatibility Report"
				"------------------------------"
				""
				$vcMigrationReport.apiVcMigrationReport | Format-Table $a -AutoSize -wrap
				$vcMigrationReport.apiVcMigrationReport| Format-Table $b -AutoSize -wrap
				$vcMigrationReport.outReport | Sort-Object severity | Format-List $i

			}

			Else 
			{

				if ($PSBoundParameters['whatif'].ispresent) 
				{ 
							
					write-warning "-WhatIf was passed, would have proceeded with removing '$vcDomainName' from VCEM Domain Group."
					$resp = $null
			
				}
				else 
				{

					# If here, user chose "No", End Processing
					write-host ""
					write-warning "Not removing '$vcDomainName'from VCEM Domain Group and unable to proceed without removing the VC Domain from the VCEM Domain Group."
					write-host ""
					
					$resp = $Null

				}

			}

		}

		# We are ready to migrate
		if ($vcMigrationReport.migrationState -eq "ReadyToMigrate" -and -not ($report.IsPresent)) 
		{
			
			if ($PSCmdlet.ShouldProcess("enclosure $EnclosureName at $($vcMigrationReport.apiVcMigrationReport.enclosureIp)","Process migration")) 
			{
				
				Try
				{

					# Make the PUT call to migrate
					$migrateTask = Send-HPOVRequest -method PUT -uri $vcMigrationReport.apiVcMigrationReport.uri -body @{acknowledgements = $vcMigrationReport.apiVcMigrationReport.acknowledgements; migrationState = "Migrated"; type = "MigratableVcDomainV300"}  -appliance $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				

				if (-Not($PSBoundParameters['Async']))
				{

					$migrateTask = $migrateTask | Wait-HPOVTaskComplete -timeout (New-TimeSpan -Minutes 60)

				}

			}

			else 
			{

				if ($PSBoundParameters['whatif'].ispresent) 
				{ 
							
					write-warning "-WhatIf was passed, would have proceeded with migration of $($vcMigrationReport.apiVcMigrationReport.enclosureName)."
					$migrateTask = $null
			
				}

				else 
				{

					# If here, user chose "No", End Processing
					write-host ""
					write-warning "Not migrating enclosure, $($vcMigrationReport.apiVcMigrationReport.enclosureName)."
					write-host ""
					
					$migrateTask = $Null

				}

			}

		}# End if ReadyToMigrate

		# Handle error conditions that need to be resolved by the caller before migration can be performed.
		elseif ($vcMigrationReport.migrationState -eq "UnableToMigrate" -and $vcMigrationReport.apiVcMigrationReport.criticalCount -ge 1) 
		{
		
			$ErrorRecord = New-ErrorRecord HPOneView.VCMigratorException UnableToMigrateEnclosure InvalidResult 'Invoke-HPOVVcMigration' -Message "There are 1 or more critical issues preventing the enclosure from being eligible to migrate.  Please run a compatibility report using the -report switch, then review and resolve the reported issues before continuing."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif ($vcMigrationReport.migrationState -eq "Migrated") 
		{
		
			$ErrorRecord = New-ErrorRecord HPOneView.VCMigratorException EnclosureMigrated OperationStopped 'OAIP' -Message "The enclosure '$EnclosureName' was already migrated.  Not performing action again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif ($vcMigrationReport.migrationState -eq "Migrating") 
		{
		
			$ErrorRecord = New-ErrorRecord HPOneView.VCMigratorException MigratingEnclosure InvalidOperation 'OAIP' -Message "An asynchronOut task migrating enclosure '$EnclosureName' exists and is currently still running."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}
		   
	}# End Process
	
	End 
	{
		 
		Return $migrateTask

	}

}
