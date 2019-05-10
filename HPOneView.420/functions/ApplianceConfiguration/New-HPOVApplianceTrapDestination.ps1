function New-HPOVApplianceTrapDestination
{

    # .ExternalHelp HPOneView.420.psm1-help.xml

    [CmdletBinding (DefaultParameterSetName = 'Default')]
    Param 
    (

        [Parameter (Mandatory, ParameterSetName = 'Default')]
        [Parameter (Mandatory, ParameterSetName = 'SnmpV3')]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,
		
        [Parameter (Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter (Mandatory = $false, ParameterSetName = 'SnmpV3')]
        [ValidateNotNullOrEmpty()]
		[Int]$Port = 162,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$CommunityString,

        [Parameter (Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter (Mandatory = $false, ParameterSetName = 'SnmpV3')]
        [ValidateSet ('SNMPv1', 'SNMPv3')]
		[String]$Type = 'SNMPv1',
		
		[Parameter (Mandatory, ParameterSetName = 'SnmpV3')]
		[HPOneView.Appliance.SnmpV3User]$SnmpV3User,
					
        [Parameter (Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter (Mandatory = $false, ParameterSetName = 'SnmpV3')]
        [ValidateNotNullOrEmpty()]
        [Alias ('Appliance')]
        [Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
    )

    Begin 
    {

        "[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

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

	}
	
	Process
	{
		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Switch ($Type)
			{

				'SNMPv1'
				{

					'[{0}] Creating an SNMPv1 trap destination.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					'[{0}] Getting list of existing SNMPv1 trap destinations.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_ExistingTrapDestinations = Send-HPOVRequest -Uri $ApplianceSnmpV1TrapDestUri -Hostname $_appliance

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
					$_SnmpV1TrapDest = New-Object HPOneView.Appliance.SnmpTrapDestinationValidation($Destination)

					ForEach ($_entry in $_ExistingTrapDestinations.members)
					{

						[void]$_SnmpV1TrapDest.existingDestinations.Add($_entry.destination)

					}
					
					'[{0}] Validating SNMPv1 trap destination.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

                        $_resp = Send-HPOVRequest -Uri $ApplianceSnmpV3TrapDestValidationUri -Method POST -Body $_SnmpV1TrapDest -Hostname $_appliance

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}


					$_Uri = '{0}/{1}' -f $ApplianceSnmpV1TrapDestUri, ($_SnmpV1TrapDest.existingDestinations.Count + 1)

					$_NewSnmpTrapDestination = New-Object HPOneView.Appliance.NewSnmpV1TrapDestination ($Destination, $Port, $CommunityString, $_Uri)

				}

				'SNMPv3'
				{

					'[{0}] Creating an SNMPv3 trap destination.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					'[{0}] SNMPv3 User ID: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $SnmpV3User.id | Write-Verbose

					$_Uri = $ApplianceSnmpV3TrapDestUri

					$_NewSnmpTrapDestination = New-Object HPOneView.Appliance.NewSnmpV3TrapDestination ($Destination, $Port, $SnmpV3User)

				}

			}

			Try
			{

				$_resp = Send-HPOVRequest -Uri $_Uri -Method POST -Body $_NewSnmpTrapDestination -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			switch ($Type)
			{

				'SNMPv1'
				{

					New-Object HPOneView.Appliance.SnmpV1TrapDestination ($_resp.destination, 
																			$_resp.port, 
																			$_resp.communityString, 
																			$_resp.uri, 
																			$_resp.ApplianceConnection)

				}

				'SNMPv3'
				{

					Try
					{

						$_SnmpV3User = Send-HPOVRequest -Uri $_resp.userUri -Hostname $_appliance

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$_SnmpV3UserObject = New-Object HPOneView.Appliance.SnmpV3User($_SnmpV3User.userName,
																				   $_SnmpV3User.securityLevel,
																				   $_SnmpV3User.authenticationProtocol,
																				   $_SnmpV3User.authenticationPassphrase,
																				   $_SnmpV3User.privacyProtocol,
																				   $_SnmpV3User.privacyPassphrase,
																				   $_SnmpV3User.id,
																				   $_SnmpV3User.uri)

					New-Object HPOneView.Appliance.SnmpV3TrapDestination ($_resp.destinationAddress, 
																		$_resp.port, 
																		$_resp.uri, 
																		$_SnmpV3UserObject,
																		$_resp.userUri,
																		$_resp.ApplianceConnection)
				}

			}

		}		

	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
