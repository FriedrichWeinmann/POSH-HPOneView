function Enable-HPOVRemoteSyslog
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param
	(

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('Appliance')]
		[ValidateNotNullOrEmpty()]
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

		$_ColStatus = New-Object System.Collections.ArrayList

	}
	 
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing {1} appliance connection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			Try
			{

				"[{0}] Getting current settings from the appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_RemoteSyslogSettings = Get-HPOVRemoteSyslog -ApplianceConnection $_appliance.Name

			}

			Catch
			{
				
				$_ColStatus

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($_RemoteSyslogSettings.enabled)
			{

				"[{0}] SysLog already enabled." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			else
			{

				$_RemoteSyslogSettings.enabled = $true

				Try
				{

					$_results = Send-HPOVRequest $RemoteSyslogUri PUT $_RemoteSyslogSettings -Hostname $_appliance.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			if ($PSBoundParameters['Async'])
			{

				$_results

			}

			else
			{

				$_results | Wait-HPOVTaskComplete

			}
			
		}

	}
	
	End 
	{
	
		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
	}

}
