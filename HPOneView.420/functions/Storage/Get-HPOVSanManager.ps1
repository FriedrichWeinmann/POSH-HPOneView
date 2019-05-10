function Get-HPOVSanManager 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ('SanManager')]
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

		$SanManagerCollection = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			$uri = '{0}?sort=name:asc' -f $fcSanManagersUri

			if ($Name)
			{
				
				$uri = '{0}&query=name like "{1}"' -f $uri, $Name.Replace("*","%25").Replace("&","%26")

			}

			# Send Request
			"[{0}] Getting list of SAN Managers" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_sanManagers = Send-HPOVRequest -Uri $uri -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# Generate Terminating Error if resource not found
			if (-not($_sanManagers.members) -and $Name) 
			{

				"[{0}] Requested Managed SAN '{1}' not found on {2}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name, $_appliance.Name | Write-Verbose

				$ExceptionMessage = "Request SAN Manager '{0}' not found on '{1}'.  Please check the name and try again." -f $Name, $_appliance.Name 
				$ErrorRecord = New-ErrorRecord InvalidOperationException SanManagerResourceNotFound ObjectNotFound 'SanManager' -Message $ExceptionMessage
					
				# Generate Terminating Error
				$PSCmdlet.WriteError($ErrorRecord)

			}
			
			elseif (-not($_sanManagers.members)) 
			{

				"[{0}] No SAN Managers found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						
			}

			else 
			{

				$_sanManagers.members | ForEach-Object { 
					
					$_.PSObject.TypeNames.Insert(0,"HPOneView.Storage.SanManager") 
				
					[void]$SanManagerCollection.Add($_)
				
				}

			}

		}

	}

	End 
	{

		Return $SanManagerCollection

	}

}
