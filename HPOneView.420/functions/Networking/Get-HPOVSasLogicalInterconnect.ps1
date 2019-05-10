function Get-HPOVSasLogicalInterconnect 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[String]$Label,
		
		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Alias ("x", "ExportFile")]
		[ValidateScript({split-path $_ | Test-Path})]
		[String]$Export

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

		$LiCollection = New-Object System.Collections.ArrayList
		$NotFound     = New-Object System.Collections.ArrayList

		if (-not $PSBoundParameters['Type'])
		{

			$Type = 'Ethernet', 'FibreChannel', 'SAS'

		}
		
	}
	
	Process 
	{
		
		ForEach ($_appliance in $ApplianceConnection)
		{

			$_IndexLookup = $false

			$uri = $SasLogicalInterconnectsUri

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose		

			if ($PSBoundParameters['Name']) 
			{

				$Method = 'eq'

				if ($Name.Contains('*'))
				{

					$Name = $Name.Replace('*', '%25')
					$Method = 'matches'

				}	

				"[{0}] Logical Interconnect name provided: '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

				$uri = "{0}?filter=name {1} '{2}'" -f $uri, $Method, $Name

			}

			if ($PSBoundParameters['Label'])
			{

				$uri = "{0}?category:logical-interconnects&sort=name:asc&query=labels:{1}" -f $IndexUri, $Label

				if ($PSBoundParameters['Name'])
				{

					$uri += '&query=name:{0}' -f $Name

				}

				$_IndexLookup = $true

			}

			Try
			{

				$resp = Send-HPOVRequest -Uri $uri -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
				
			if ($resp.count -eq 0 -and $Name) 
			{ 

				"[{0}] Logical Interconnect '{1}' resource not found on '{2}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name, $_appliance.Name | Write-Verbose

				$ExceptionMessage = "Specified Logical Interconnect '{0}' was not found on '{1}' appliance.  Please check the name and try again." -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord InvalidOperationException SASLogicalInterconnectGroupNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)  

			}

			elseif ($resp.count -eq 0) 
			{ 

				"[{0}] No Logical Interconnect resources found on '{1}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			}

			else 
			{

				"[{0})] Found {1} Logical Interconnect resource(s)." -f $MyInvocation.InvocationName.ToString().ToUpper(), $resp.count | Write-Verbose

				ForEach ($_LiObject in $resp.members)
				{

					Try
					{

						if ($_IndexLookup)
						{

							"[{0}] Getting LI resource object for {1} (Indexed)." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_LiObject.name | Write-Verbose

							Try
							{

								$_LiObject = Send-HPOVRequest -Uri $_LiObject.uri -Hostname $_appliance.Name

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}							

						}						

						$_LiObject.PSobject.TypeNames.Insert(0,"HPOneView.Storage.SasLogicalInterconnect")  
					
						[void]$LiCollection.Add($_LiObject) 

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}
 
			}

		}
   
	}

	End 
	{
		
		"[{0}] Done. {1} logical interconnect(s) found." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LiCollection.count | Write-Verbose

		if ($Export)
		{
			
			$LiCollection | convertto-json -Depth 99 | Set-Content -Path $ExportFile -force -encoding UTF8 
		
		}
		
		else 
		{

			 $LiCollection 
		
		}    

	}

}
