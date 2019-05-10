function Get-HPOVAuditLog 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Int]$Count = 0,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[TimeSpan]$TimeSpan,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[DateTime]$Start,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[DateTime]$End = [DateTime]::Now,

		[Parameter (Mandatory = $false, ParameterSetName = 'default')]
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

		$_AllAuditLogs = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			$uri = $applAuditLogsUri + "?sort:asc"

			if ($PSBoundParameters['Count'])
			{

				$uri = "{0}&count={1}" -f $uri, $Count

			}

			$Filter = New-Object System.Collections.ArrayList

			if ($TimeSpan)
			{

				[Void]$Filter.Add(("DATE<='{0}/P{1}D'" -f [DateTime]::Now.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ"),$TimeSpan.Days))
				
			}

			elseif ($Start)
			{

				[Void]$Filter.Add(("DATE>='{0}' and DATE<='{1}'" -f $Start.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"), $End.ToUniversalTime().ToString("yyyy-MM-ddT23:59:59Z")))

			}

			if ($Filter.count -gt 0)
			{

				$uri = '{0}&filter="{1}"' -f $uri, [String]::Join(' and ',$Filter.ToArray())

			}

			Try
			{
				
				# Send the request
				$_AuditLogs = Send-HPOVRequest -Uri $uri -Hostname $_appliance

				$_AuditLogs.members | ForEach-Object {

					$_.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.AuditLogEntry')

					[void]$_AllAuditLogs.Add($_)

				}

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

	}

	End
	{

		Return $_AllAuditLogs

	}

}
