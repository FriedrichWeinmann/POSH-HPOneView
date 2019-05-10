function Get-HPOVSwitchType
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

			$uri = $SwitchTypesUri + "?sort=name:descEnding"

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

					$_switchtype = $_

					$_switchtype | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'HPOneView.Networking.SwitchType')}

					[void]$Collection.Add($_switchtype)

				}

			}

			else 
			{

				[Void]$NotFound.Add($_appliance.Name)

			}

		}

	}

	End 
	{

		if ((-not($Collection) -or ($NotFound.count -gt 1)) -and $Name) 
		{

			$Collection

			$ErrorRecord = New-ErrorRecord HPOneView.SwitchTypeResourceException SwitchTypeNameResourceNotFound ObjectNotFound 'Name' -Message "No Switch Types with '$Name' name were found on appliance $($NotFound -join ", ")."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif ((-not($Collection) -or ($NotFound.count -gt 0)) -and $PartNumber) 
		{

			$Collection

			$ErrorRecord = New-ErrorRecord HPOneView.SwitchTypeResourceException SwitchTypePartnumberResourceNotFound ObjectNotFound 'PartNumber' -Message "No Switch Types with '$PartNumber' partnumber were found on appliance $($NotFound -join ", ")."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		else 
		{ 
		
			return $Collection

		}

	}

}
