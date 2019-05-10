function Get-HPOVServerProfileConnectionList 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding ()]
	Param 
	(
		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

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

		$allConnections = New-Object System.Collections.ArrayList

	}

	Process 
	{
		
		ForEach($_Connection in $ApplianceConnection)
		{

			$profiles = New-Object System.Collections.ArrayList
	
			# Get profiles
			if ($Name)
			{

				$uri = "{0}?filter=name='{1}'" -f $ServerProfilesUri, $Name

				Try
				{

					$profile = (Send-HPOVRequest $uri -appliance $_Connection).members

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if (-not ($profile)) 
				{ 

					$ErrorRecord = New-ErrorRecord InvalidOperationException ProfileResourceNotFound ObjectNotFound 'Get-HPOVServerProfileConnectionList' -Message "Server Profile '$name' was not found."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
				}
			
				[void]$profiles.Add($profile)
	
			} 

			else 
			{

				Try
				{

					$index = Send-HPOVRequest -Uri $ServerProfileIndexListUri -appliance $_Connection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}                

				if ($index.count -eq 0) 
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException ProfileResourceNotFound ObjectNotFound 'Get-HPOVServerProfileConnectionList' -Message "No Server Profile resources found.  Use New-HPOVServerProfile to create one."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)            
					
				}
	
				foreach ($entry in $index.members)
				{

					Try
					{

						$profile = Send-HPOVRequest $entry.uri -appliance $_Connection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
	
					[void]$profiles.Add($profile)

				}     
					   
			}
	
			# Get connections
			$conns = New-Object System.Collections.ArrayList

			foreach($p in $profiles)
			{
	
				foreach($c in $p.connectionSettings.connections) 
				{ 

					Try
					{

						$c | add-member -membertype noteproperty -name cid -value $c.id;
						$c | add-member -membertype noteproperty -name serverProfile -value $p.name;
						$c | add-member -membertype NoteProperty -name Network -value (Send-HPOVRequest $c.networkUri -appliance $_Connection).Name
						$c | Add-Member -NotePropertyName Appliance -NotePropertyValue $_Connection.name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}                    

					if($c.boot.targets) 
					{

						$c | add-member -membertype noteproperty -name arrayTarget -value $c.boot.targets[0].arrayWwpn
						$c | add-member -membertype noteproperty -name lun -value $c.boot.targets[0].lun

					}
	
					if($c.portId) 
					{ 

						$c.portId = $c.portId.Replace("Flexible", "")

					} 

					else 
					{
						 
						$name = "Dev:" + $c.deviceNumber + '-' + $c.physicalPortNumber

						$c | add-member -membertype noteproperty -name portId -value $name

					}
	
				   if($c.boot) { $c.boot = $c.boot.priority; }

				   if($c.boot -eq "NotBootable") { $c.boot = "-"; }      
				   
				   [void]$conns.Add($c)

				}

			}

			# Output
			[void]$allConnections.Add($conns)
		
		}   

	}
	
	End 
	{

		$allConnections | Sort-Object serverProfile, cid | format-table -Property serverProfile, cid, portId, functionType, Network, mac, wwpn, boot, arrayTarget, lun, Appliance  -AutoSize

	} 

}
