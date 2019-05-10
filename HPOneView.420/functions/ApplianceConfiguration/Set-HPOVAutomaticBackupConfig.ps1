function Set-HPOVAutomaticBackupConfig
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = 'Default', SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[String]$Hostname,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[String]$Directory,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[String]$Username,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[SecureString]$Password,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[String]$HostSSHKey,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateSet ('SCP','SFTP')]
		[String]$Protocol = 'SCP',

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateSet ('Daily','Weekly')]
		[String]$Interval,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Array]$Days,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateScript ({[RegEx]::IsMatch($_,"([01]?[0-9]|2[0-3]):[0-5][0-9]")})]
		[String]$Time,

		[Parameter (Mandatory, ParameterSetName = 'Disable')]
		[Switch]$Disabled,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Disable')]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Disable')]
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

		$_AutoBackupStatusCollection = New-Object System.Collections.ArrayList

	}

	Process
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			$_resp = $null

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Try
			{

				$_AutomaticBackupStatus = Send-HPOVRequest -Uri $ApplianceAutoBackupConfUri -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_AutoBackupConfig = NewObject -AutoBackupConfig

			$_AutoBackupConfig.eTag = $_AutomaticBackupStatus.eTag

			if ($PSBoundParameters['Disabled'])
			{

				$_AutomaticBackupStatus.enabled = $false

			}

			else
			{

				if (-not $HostSSHKey.StartsWith('ssh-rsa'))
				{

					$_ExceptionMessage = 'The provided HostSSHKey is not a valid OpenSSL RSA key.'
					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AutomatedBackupConfigException InvalidedHostSSHRsaKey InvalidArgument 'HostSSHKey' -Message $_ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_AutoBackupConfig.remoteServerDir       = $Directory
				$_AutoBackupConfig.remoteServerName      = $Hostname
				$_AutoBackupConfig.remoteServerPublicKey = ($HostSSHKey | Out-String)
				$_AutoBackupConfig.userName              = $Username
				$_AutoBackupConfig.password              = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

				if ($PSBoundParameters['Protocol'])
				{

					$_AutoBackupConfig.protocol = $Protocol

				}

				else
				{

					$_AutoBackupConfig.protocol = $_AutomaticBackupStatus.Protocol

				}

				if ($PSBoundParameters['Interval'])
				{

					$_AutoBackupConfig.scheduleInterval = $Interval.ToUpper()

				}

				else
				{
			
					$_AutoBackupConfig.scheduleInterval = $_AutomaticBackupStatus.scheduleInterval
			
				}

				if ($PSBoundParameters['Days'] -and $PSBoundParameters['Interval'] -eq 'Weekly')
				{

					ForEach ($_day in $Days)
					{

						[void]$_AutoBackupConfig.scheduleDays.Add($DayOfWeekEnum.$_day.ToUpper())

					}

				}

				else
				{
			
					$_AutoBackupConfig.scheduleDays = $_AutomaticBackupStatus.scheduleDays
			
				}

				if ($PSBoundParameters['Time'])
				{

					$_AutoBackupConfig.scheduleTime = $Time

				}

				else
				{
			
					$_AutoBackupConfig.scheduleTime = $_AutomaticBackupStatus.scheduleTime
			
				}

			}

			# Prompt the user if they really want to disable Automatic Backups
			if ($PSBoundParameters['Disabled'])
			{

				if ($PSCmdlet.ShouldProcess($_appliance.Name,'disable automatic backup schedule on appliance')) 
				{

					Try
					{

						$_resp = Send-HPOVRequest -Uri $ApplianceAutoBackupConfUri PUT $_AutomaticBackupStatus -Hostname $_appliance

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				elseif ($PSBoundParameters['WhatIf'])
				{

					"[{0}] User provided -WhatIf switch." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

				else
				{
				
					"[{0}] User cancelled or stated 'No'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Return

				}

			}

			else
			{

				"[{0}] Sending request" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_resp = Send-HPOVRequest -Uri $ApplianceAutoBackupConfUri -Method PUT -Body $_AutoBackupConfig -Hostname $_appliance

				}
					
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			if ($PSBoundParameters['Async'])
			{

				$_resp

			}

			else
			{
				
				$_resp | Wait-HPOVTaskComplete

			}

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
