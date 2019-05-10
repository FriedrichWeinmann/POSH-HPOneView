function Show-HPOVSanEndpoint
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory = $False, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Object]$SAN,

		[Parameter (Mandatory, ParameterSetName = 'WWN')]
		[ValidateNotNullOrEmpty()]
		[String]$WWN,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'WWN')]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		
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

		$_SANEndpointCol = New-Object System.Collections.ArrayList

	}

	Process
	{

		$uri = $SanEndpoints

		if ($SAN)
		{

			switch ($SAN.GetType().Name)
			{


				'String'
				{

					$uri += '?query=sanName eq "{0}"' -f $SAN

				}

				'PSCustomObject'
				{

					$uri += '?query=sanName eq "{0}"' -f $SAN.name

				}

			}

			Try
			{

				$_resp = Send-HPOVRequest $uri -Hostname $ApplianceConnection

				$_resp.members | ForEach-Object {

					$_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.San.Endpoint')

					[void]$_SANEndpointCol.Add($_)

				}

			}

			Catch
			{

			  $PSCmdlet.ThrowTerminatingError($_)

			}

		}

		else
		{

			if ($WWN)
			{

				$uri += '?query=wwn eq "{0}"' -f $WWN

			}

			if ($ApplianceConnection -is [System.Collections.IEnumerable] -and $ApplianceConnection -isnot [System.String])
			{

				ForEach ($_appliance in $ApplianceConnection)
				{


					Try
					{

						$_resp = Send-HPOVRequest $uri -Hostname $_appliance

						$_resp.members | ForEach-Object {

							$_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.San.Endpoint')

							[void]$_SANEndpointCol.Add($_)

						}

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

					$_resp = Send-HPOVRequest $uri -Hostname $ApplianceConnection

					$_resp.members | ForEach-Object {

						$_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.San.Endpoint')

						[void]$_SANEndpointCol.Add($_)

					}

				}

				Catch
				{

				  $PSCmdlet.ThrowTerminatingError($_)

				}

			}
			
		}

	}

	End
	{

		Return $_SANEndpointCol

	}

}
