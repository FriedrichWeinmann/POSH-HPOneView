function Get-HPOVApplianceSecurityProtocol
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	[OutputType([System.Collections.Generic.List[HPOneView.Appliance.SecurityProtocol]], ParameterSetName = "Default")]
	param
	(

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateSet ('TLSv1', 'TLSv1.1', 'TLSv1.2')]
		[String[]]$TlsVersion,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateSet ('Legacy', 'FIPS', 'CNSA')]
		[String[]]$SecurityMode,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = ($ConnectedSessions | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject']))
		{

			$Pipelineinput = $True

		}

		else
		{

			"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if (-not($ApplianceConnection) -and -not($ConnectedSessions))
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command agian."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			elseif ($ApplianceConnection -is [System.Collections.IEnumerable] -and $ApplianceConnection -isnot [System.String])
			{

				For ([int]$c = 0; $c -gt $ApplianceConnection.Count; $c++)
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

		if (-not $PSBoundParameters['TlsVersion'])
		{

			$TlsVersion = 'TLSv1', 'TLSv1.1', 'TLSv1.2'
	
		}

		$_ApplianceProtocolsCollection = New-Object 'System.Collections.Generic.List[HPOneView.Appliance.SecurityProtocol]'

	}

	Process
	{		

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			# need to get the current security mode
			try
			{

				$_CurrentSecurityMode = Send-HPOVRequest -Uri $ApplianceCurrentSecurityModeUri -Hostname $_appliance

			}

			catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			ForEach ($_TlsVersion in $TlsVersion)
			{

				$_uri = '{0}/{1}' -f $ApplianceSecurityProtocolsUri, $_TlsVersion.Replace('tls','TLS')

				if ($PSBoundParameters['SecurityMode'])
				{

					ForEach ($_SecurityMode in $SecurityMode)
					{

						$_CipherSuitesCol = New-Object 'System.Collections.Generic.List[HPOneView.Appliance.SecurityProtocol+CipherSuite]'

						$__uri = '{0}?mode={1}' -f $_uri, $_SecurityMode

						try
						{

							$_SecurityProtocolWithMode = Send-HPOVRequest -Uri $__uri -Hostname $_appliance

						}

						catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						ForEach ($_cipherSuite in $_SecurityProtocolWithMode.cipherSuites)
						{

							$_CipherSuite = New-Object HPOneView.Appliance.SecurityProtocol+CipherSuite($_cipherSuite.cipherSuiteName, $_cipherSuite.enabled)
							$_CipherSuitesCol.Add($_CipherSuite)

						}

						$_Protocol = New-Object HPOneView.Appliance.SecurityProtocol($_SecurityProtocolWithMode.protocolName,
																					 $_CipherSuitesCol, 
																					 $_SecurityProtocolWithMode.category,
																					 $_SecurityMode,
																					 ($_CurrentSecurityMode.ModeName -eq $_SecurityMode),
																					 $_SecurityProtocolWithMode.enabled,
																					 $_SecurityProtocolWithMode.ApplianceConnection)

						$_ApplianceProtocolsCollection.Add($_Protocol)

					}

				}

				else
				{

					$_CipherSuitesCol = New-Object 'System.Collections.Generic.List[HPOneView.Appliance.SecurityProtocol+CipherSuite]'

					try
					{

						$_ApplianceSecurityProtocols = Send-HPOVRequest -Uri ($_uri + "?mode=$($_CurrentSecurityMode.modeName)") -Hostname $_appliance

					}

					catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					ForEach ($_SecurityProtocol in $_ApplianceSecurityProtocols)
					{

						ForEach ($_cipherSuite in $_SecurityProtocol.cipherSuites)
						{

							$_CipherSuite = New-Object HPOneView.Appliance.SecurityProtocol+CipherSuite($_cipherSuite.cipherSuiteName, $_cipherSuite.enabled)
							$_CipherSuitesCol.Add($_CipherSuite)

						}

						$_Protocol = New-Object HPOneView.Appliance.SecurityProtocol($_SecurityProtocol.protocolName,
																		$_CipherSuitesCol, 
																		$_SecurityProtocol.category,
																		$_CurrentSecurityMode.modeName,
																		$True,
																		$_SecurityProtocol.enabled,
																		$_SecurityProtocol.ApplianceConnection)

						$_ApplianceProtocolsCollection.Add($_Protocol)

					}					

				}

			}

		}		

	}

	end
	{

		$_ApplianceProtocolsCollection | Sort-Object Mode		

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
