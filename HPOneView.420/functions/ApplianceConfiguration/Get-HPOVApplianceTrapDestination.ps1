function Get-HPOVApplianceTrapDestination
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$Destination,

		[Parameter (Mandatory = $false)]
		[ValidateSet ('SNMPv1', 'SNMPv3')]
		[Array]$Type,
					
		[Parameter (Mandatory = $false)]
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

		if (-not $PSBoundParameters['Type'])
		{

			$Type = @('SNMPv1','SNMPv3')

		}

		ForEach ($_appliance in $ApplianceConnection)
		{

			$SnmpTrapDestinationCol = New-Object System.Collections.ArrayList

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Switch ($Type)
			{

				'SNMPv1'
				{

					# This code does not work.  Will need to create a collection of results and do PowerShell Linq-style filtering

					$_Uri = $ApplianceSnmpV1TrapDestUri				

					Try
					{

						$_ApplianceSnmpV1trapDestinations = Send-HPOVRequest -Uri $_Uri -Hostname $_appliance

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					if ($Destination)
					{

						if ($Destination.Contains('*'))
						{

							$_ApplianceSnmpV1trapDestinations.members = $_ApplianceSnmpV1trapDestinations.members | Where-Object destination -matches $Destination

						}

						else
						{

							$_ApplianceSnmpV1trapDestinations.members = $_ApplianceSnmpV1trapDestinations.members | Where-Object destination -eq $Destination

						}

					}

					ForEach ($_entry in $_ApplianceSnmpV1trapDestinations.members)
					{

						$_SnmpTrap = New-Object HPOneView.Appliance.SnmpV1TrapDestination ($_entry.destination, 
																						   $_entry.port, 
																						   $_entry.communityString, 
																						   $_entry.uri, 
																						   $_entry.ApplianceConnection)

						[void]$SnmpTrapDestinationCol.Add($_SnmpTrap)

					}

				}

				'SNMPv3'
				{

					$_Uri = $ApplianceSnmpV3TrapDestUri

					if ($Destination)
					{

						$_operator = 'eq'

						if ($Destination.Contains('*'))
						{

							$_operator = 'matches'

						} 

						$_Uri = "{0}?filter=destinationAddress {1} '{2}'" -f $_Uri, $_operator, $Destination.Replace('*', '%25')

					}

					Try
					{

						$_ApplianceSnmpV3trapDestinations = Send-HPOVRequest -Uri $_Uri -Hostname $_appliance

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					ForEach ($_entry in $_ApplianceSnmpV3trapDestinations.members)
					{

						Try
						{

							$_SnmpV3User = Send-HPOVRequest -Uri $_entry.userUri -Hostname $_appliance

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						# (string Username, string SecurityLevel, string AuthProtocol, string AuthPassphrase, string PrivateProtocol, string PrivatePassphrase)
						$_SnmpV3UserObject = New-Object HPOneView.Appliance.SnmpV3User($_SnmpV3User.userName,
																					   $_SnmpV3User.securityLevel,
																					   $_SnmpV3User.authenticationProtocol,
																					   $_SnmpV3User.authenticationPassphrase,
																					   $_SnmpV3User.privacyProtocol,
																					   $_SnmpV3User.privacyPassphrase,
																					   $_SnmpV3User.id,
																					   $_SnmpV3User.uri)

						# (string TrapDestinationAddress, int Port, string Uri, SnmpV3User SnmpV3User, string SnmpV3UserUri, Library.ApplianceConnection ApplianceConnection )
						$_SnmpTrap = New-Object HPOneView.Appliance.SnmpV3TrapDestination ($_entry.destinationAddress, 
																						   $_entry.port, 
																						   $_entry.uri, 
																						   $_SnmpV3UserObject,
																						   $_entry.userUri,
																						   $_entry.ApplianceConnection)

						[void]$SnmpTrapDestinationCol.Add($_SnmpTrap)

					}

				}

			}
			
			if ($SnmpTrapDestinationCol.Count -eq 0 -and $Destination)
			{

				$_Message = "SNMP Trap Destination '{0}' was not found on {1} Appliance Connection." -f $Destination, $_appliance.Name 
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.SnmpResourceException SnmpTrapDestinationNotFound ObjectNotFound "Destination" -Message $_Message
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				$SnmpTrapDestinationCol.ToArray()

			}

		}

	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
