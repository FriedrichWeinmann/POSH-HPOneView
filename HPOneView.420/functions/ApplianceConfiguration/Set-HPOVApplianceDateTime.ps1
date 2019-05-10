function Set-HPOVApplianceDateTime
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = 'SyncHost')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'SyncHost')]
		[Switch]$SyncWithHost,

		[Parameter (Mandatory, ParameterSetName = 'NTPServers')]
		[Array]$NTPServers,

		[Parameter (Mandatory = $false, ParameterSetName = 'NTPServers')]
		[Int]$PollingInterval,

		[Parameter (Mandatory = $False, ParameterSetName = 'SyncHost')]
		[Parameter (Mandatory = $False, ParameterSetName = 'NTPServers')]
		[ValidateSet ('en_US','zh_CN','ja_JP')]
		[String]$Locale,

		[Parameter (Mandatory = $False, ParameterSetName = 'SyncHost')]
		[Parameter (Mandatory = $False, ParameterSetName = 'NTPServers')]
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

	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			$_SyncWithHost = $false
		
			"[{0}] Processing Appliance Connection {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Try
			{

				$_CurrentConfig = Send-HPOVRequest -Uri $ApplianceDateTimeUri -Hostname $_appliance.Name

			}


			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_ApplianceTimeConfig = NewObject -ApplianceTimeLocale
			
			switch ($PSCmdlet.ParameterSetName)
			{

				'SyncWithHost'
				{

					"[{0}] Seting ntpServers to 'null' for Sync with Host." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					$_ApplianceTimeConfig.ntpServers = @()
					$_SyncWithHost = $true

				}

				'NTPServers'
				{

					ForEach ($_ntpserver in $NTPServers)
					{

						"[{0}] Adding '{1}' to collection."-f $MyInvocation.InvocationName.ToString().ToUpper(), $_ntpserver | Write-Verbose

						[void]$_ApplianceTimeConfig.ntpServers.Add($_ntpserver)

					}

					if ($PSBoundParameters['PollingInterval'])
					{

						$_ApplianceTimeConfig.pollingInterval = $PollingInterval.ToString()

					}

				}

			}

			if ($PSBoundParameters['TimeZone'])
			{

				$_ApplianceTimeConfig.timezone = $TimeZone

			}

			else
			{

				$_ApplianceTimeConfig.timezone = $_CurrentConfig.timezone

			}

			if ($PSBoundParameters['Locale'])
			{

				$_ApplianceTimeConfig.locale = $ApplianceLocaleSetEnum[$Locale]

			}

			else
			{

				$_ApplianceTimeConfig.locale = $_CurrentConfig.locale

			}

			Try
			{
			
				$_Results = Send-HPOVRequest -Uri $ApplianceDateTimeUri -Method POST -Body $_ApplianceTimeConfig -Hostname $_appliance.Name | Wait-HPOVTaskComplete

				if ('Warning', 'Completed' -notcontains $_Results.taskState)
				{

					$ExceptionMessage = [String]::Join(' ', $_Results.taskErrors.Message)
					$ErrorRecord = New-ErrorRecord InvalidOperationException ApplianceDateTimeInvalidOperation InvalidOperation $ApplianceConnection.Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_appliancedatetime = Send-HPOVRequest -Uri $ApplianceDateTimeUri -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

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
