function Get-HPOVSasInterconnectType 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Name')]
	Param
	(
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Name')]
		[ValidateNotNullorEmpty()]
		[string]$Name,

		[Parameter (Mandatory, ParameterSetName = 'PartNumber')]
		[ValidateNotNullorEmpty()]
		[string]$PartNumber,

		[Parameter (Mandatory = $false, ParameterSetName = 'Name')]
		[Parameter (Mandatory = $false, ParameterSetName = 'PartNumber')]
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

		$Collection = New-Object System.Collections.ArrayList
		$NotFound   = New-Object System.Collections.ArrayList

	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			if ($_appliance.ApplianceType -ne 'Composer')
			{
	
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message ('The ApplianceConnection {0} is an HPE OneView Virtual Machine Appliance, which does not support SAS Logical Interconnect Group resources.' -f $_appliance.Name)
				$PSCmdlet.WriteError($ErrorRecord)
	
			}	

			else
			{		

				$uri = $SasInterconnectTypeUri  + "?sort=name:descEnding"

				if ($PSboundParameters['Name']) 
				{ 
					
					$uri += "&filter=name='$name'" 
				
				}
				
				elseif ($PSboundParameters['PartNumber']) 
				{
					
					$uri += "&filter=partNumber='$partNumber'" 
				
				}

				"[{0}] Sending request"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$resp = Send-HPOVRequest $uri -Appliance $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($resp.count -gt 0)
				{

					$resp.members | Sort-Object name | ForEach-Object {

						$_interconnectType = $_

						$_interconnectType | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'HPOneView.Networking.SasInterconnectType')}

						[void]$Collection.Add($_interconnectType)

					}

				}

				elseif ($resp.count -eq 0 -and $Name)
				{

					$ErrorRecord = New-ErrorRecord HPOneView.InterconnectResourceException SasInterconnectTypeNameResourceNotFound ObjectNotFound 'Name' -Message "No SAS Interconnect Types with '{0}' name were found on appliance '{1}'." -f $Name, $_appliance.Name
					$PSCmdlet.WriteError($ErrorRecord)

				}

				elseif ($resp.count -eq 0 -and $PartNumber)
				{

					$ErrorRecord = New-ErrorRecord HPOneView.InterconnectResourceException InterconnectTypePartnumberResourceNotFound ObjectNotFound 'Name' -Message "No SAS Interconnect Types with '{0}' PartNumber were found on appliance '{1}'." -f $PartNumber, $_appliance.Name
					$PSCmdlet.WriteError($ErrorRecord)

				}

			}

		}

	}

	End 
	{

		return $Collection

	}

}
