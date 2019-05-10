function Get-HPOVApplianceDateTime
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding ()]
	Param 
	(
		
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

		$_ApplianceDateTimeCol = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{
		
			"[{0}] Processing Appliance Connection {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Try
			{
			
				$_appliancedatetime = Send-HPOVRequest -Uri $ApplianceDateTimeUri -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
		
			$SyncWithHost = $true

			if ($_appliancedatetime.ntpServers.Count -gt 0)
			{

				$SyncWithHost = $false

			}

			New-Object HPOneView.Appliance.ApplianceLocaleDateTime($_appliancedatetime.locale,
																   $_appliancedatetime.timezone,
																   $_appliancedatetime.dateTime,
																   [String[]]$_appliancedatetime.ntpServers,
																   $_appliancedatetime.pollingInterval,
																   $SyncWithHost,
																   $_appliancedatetime.LocaleDisplayName,
																   $_appliancedatetime.ApplianceConnection)

		}
	
	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
