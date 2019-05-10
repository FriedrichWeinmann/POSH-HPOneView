function Get-HPOVManagedSan 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Fabric')]
		[string]$Name,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Label,

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

		$ManagedSansCollection = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			if ($PSBoundParameters['Label'])
			{

				$_uri = '{0}?category:fc-sans&query=labels:{1}' -f $IndexUri, $Label

				Try
				{

					$_IndexMembers = Send-HPOVRequest -Uri $_uri -Hostname $_appliance

					# Loop through all found members and get full SVT object
					ForEach ($_member in $_IndexMembers.members)
					{

						Try
						{

							$_member = Send-HPOVRequest -Uri $_member.uri -Hostname $_appliance

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}						

						$_member.PSObject.TypeNames.Insert(0,"HPOneView.Storage.ManagedSan")

						$_member

					}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			else
			{

				$uri = $fcManagedSansUri + '?sort=name:asc'

				if ($Name)
				{

					$Name = $Name -replace ("[*]","%25") -replace ("[&]","%26")

					$uri += "&query=lower(name) like '{0}'" -f $Name.ToLower()

				}
				
				"[{0}] Getting list of Managed SANs" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				Try
				{

					$_managedSans = Send-HPOVRequest $uri -Hostname $_appliance.Name

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($_managedSans.count -eq 0 -and $Name) 
				{

					"[{0}] Woops! Requested Managed SAN '$($_managedSans)' not found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						
					$ErrorRecord = New-ErrorRecord InvalidOperationException ManagedSanResourceNotFound ObjectNotFound 'Name' -Message "Request Managed SAN '$($Name)' not found on appliance $($_appliance.Name).  Please check the name and try again."
						
					# Generate Terminating Error
					$PSCmdlet.WriteError($ErrorRecord)

				}

				else
				{

					$_managedSans.members | ForEach-Object { 
						
						$_.PSObject.TypeNames.Insert(0,"HPOneView.Storage.ManagedSan")
					
						[void]$ManagedSansCollection.Add($_)

					}

				}

			}

		}

	}

	End 
	{

		return $ManagedSansCollection 
	
	}

}
