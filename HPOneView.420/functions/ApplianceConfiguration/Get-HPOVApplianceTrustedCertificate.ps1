function Get-HPOVApplianceTrustedCertificate
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName='Default')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Resource')]
		[Object]$InputObject,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[String]$Name,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[Alias ("CASOnly")]
		[switch]$CertificateAuthoritiesOnly,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Resource')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = ($ConnectedSessions | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection) -and -not($ConnectedSessions))
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

		$_CertCollection = New-Object System.Collections.ArrayList

	}

	Process
	{

		$_uri = '{0}?category=certificates&count=10000&query=({1})'

		$_Query = New-Object 'System.Collections.Generic.List[String]'

		$_Query.Add("(NOT cert_type:STANDARD_ROOT)")

		if ($PSBoundParameters['Name'])
		{

			$_Query.Add('((cert_aliasName:/.*{0}.*/) OR (cert_altNames:/.*{0}.*/))' -f $Name)

		}

		if ($CertificateAuthoritiesOnly.IsPresent)
		{

			$_Query.Add('(cert_type:INTERMEDIATE OR cert_type:CUSTOM_ROOT)')

		}

		if ($InputObject)
		{

			switch ($InputObject.category)
			{

				'server-hardware'
				{

					$_Query.Add('((cert_aliasName:/.*{0}.*/) OR (cert_altNames:/.*{0}.*/))' -f $InputObject.uuid)

				}

				'enclosures'
				{

					$_Query.Add('((cert_aliasName:/.*{0}.*/) OR (cert_altNames:/.*{0}.*/))' -f $InputObject.serialNumber)

				}

				default
				{

					$ExceptionMessage = 'The provided resource "{0} ({1})" is unsupported with this Cmdlet.  Please provide a Server or Enclosure resource.' -f $InputObject.name, $InputObject.category
					$ErrorRecord = New-ErrorRecord
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

		}

		$_uri = $_uri -f $IndexUri, [String]::Join(' AND ', $_Query.ToArray())

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Try
			{

				$_CollectionResults = Send-HPOVRequest -Uri $_uri -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($_CollectionResults.members)
			{

				Try
				{
					$_CollectionResults.members | Sort-Object Type | ForEach-Object {
						
						$_Cert = Send-HPOVRequest -Uri $_.uri -Hostname $_appliance.Name

						"[{0}] Processing '{1}' ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Cert.certificateDetails.aliasName, $_Cert.uri | Write-Verbose

						Switch ($_Cert.type)
						{

							'CertificateAuthorityInfo'
							{

								if ($null -eq $_Cert.certRevocationConfInfo.crlExpiry -and
									$null -eq $_Cert.certRevocationConfInfo.crlSize)
								{

									$CertificateRevocationListInfo = New-Object HPOneView.Appliance.TrustedCertificateAuthority+CertificateRevocationListInfo("1/1/1970", 
																																						      "CrlNotFound", 
																																						      $_Cert.certRevocationConfInfo.crlSize)
								}

								else
								{

									$CertificateRevocationListInfo = New-Object HPOneView.Appliance.TrustedCertificateAuthority+CertificateRevocationListInfo($_Cert.certRevocationConfInfo.crlExpiry, 
																																						  $_Cert.certRevocationConfInfo.crlConf.crlDpList, 
																																						  $_Cert.certRevocationConfInfo.crlSize)

								}

								

								$_Certificate = New-Object HPOneView.Appliance.TrustedCertificateAuthority($_Cert.certificateDetails.base64Data,
																										   $_Cert.certificateDetails.aliasName,
																										   $_Cert.certificateDetails.state,
																										   $_Cert.created, 
																										   $_Cert.modified, 
																										   $_Cert.eTag, 
																										   $CertificateRevocationListInfo, 
																										   $_Cert.uri, 
																										   $_Cert.ApplianceConnection)

							}

							'CertificateInfoV2'
							{

								$_CertStatus = New-Object HPOneView.Appliance.CertificateStatus($_Cert.certificateStatus.chainStatus, 
																								$_Cert.certificateStatus.selfsigned, 
																								$_Cert.certificateStatus.trusted)

								$_Certificate = New-Object HPOneView.Appliance.TrustedCertificate($_Cert.certificateDetails.base64Data,
																								  $_Cert.certificateDetails.aliasName,
																								  $_Cert.certificateDetails.commonName,
																								  $_Cert.created, 
																								  $_Cert.modified,
																								  $_CertStatus,
																								  $_Cert.eTag, 
																								  $_Cert.uri, 
																								  $_Cert.ApplianceConnection)

							}

						}
	
						[void]$_CertCollection.Add($_Certificate)
	
					}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
			}

			else
			{

				$ExceptionMessage = "The specified '{0}' trusted SSL certificate resource not found on Appliance '{1}'.  Please check the name and try again." -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.TrustedCertificateResourceException TrustedCertificateResourceNotFound ObjectNotFound "Name" -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

		}

	}

	End
	{

		$_CertCollection | Sort-Object type

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
