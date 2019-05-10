function Get-HPOVAddressPoolSubnet
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(
	
		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$NetworkId,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
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

		$_SubnetCollection = New-Object System.Collections.ArrayList
					
	}

	Process 
	{

		$uri = $ApplianceIPv4SubnetsUri

		if ($PSBoundParameters['NetworkId'])
		{

			$uri += "?filter=networkId='$NetworkId'"

		}

		ForEach ($_appliance in $ApplianceConnection)
		{

			# if ($_appliance.ApplianceType -ne 'Composer')
			# {

			# 	$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message ('The ApplianceConnection {0} is not a Synergy Composer.  This Cmdlet is only supported with Synergy Composers.' -f $_appliance.Name)
			# 	$PSCmdlet.WriteError($ErrorRecord)

			# }

			# else
			# {

				Try
				{

					$_IPv4SubnetPool = Send-HPOVRequest $uri -ApplianceConnection $_appliance.Name

					$_IPv4SubnetPool.members | ForEach-Object { 
					
						$_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.IPv4AddressSubnet") 
				
						[void]$_SubnetCollection.Add($_)

					} 

				}

				Catch
				{

					$_SubnetCollection

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($NetworkId -and -not $_IPv4SubnetPool.members)
				{

					$ExceptionMessage = "The NetworkID {0} was not found on appliance {1}." -f $NetworkId, $_appliance.Name
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolResourceException ResourceNotFound ObjectNotFound 'NetworkId' -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)

				}		

			# }

		}

	}

	End 
	{

		Return $_SubnetCollection

	}

}
