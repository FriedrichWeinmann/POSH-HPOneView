function Set-HPOVSmtpConfig 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param
	(
	

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[validatescript({if ($_ -as [Net.Mail.MailAddress]) {$true} else { Throw "The Parameter value is not an email address. Please correct the value and try again." }})]
		[System.String]$SenderEmailAddress,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('SmtpServer')]		
		[ValidateNotNullOrEmpty()]
		[System.String]$Server,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('SmtpPort')]
		[ValidateNotNull()]
		[System.Int32]$Port,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateSet ('None', 'TLS', 'StartTls')]
		[String]$ConnectionSecurity = 'None',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$Password,

		[Parameter (Mandatory, ParameterSetName = "Disabled")]
		[Switch]$AlertEmailDisabled,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Switch]$AlertEmailEnabled,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "Disabled")]
		[Switch]$Async,
	
		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "Disabled")]
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

		if ($PSBoundParameters['Password'])
		{

			if ($Password -is [SecureString])
			{

				$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

			}

			else 
			{

				$_DecryptPassword = $Password

			}
		
		}

		$_ResponseCollection = New-Object System.Collections.ArrayList

	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			$_SmtpConfig = NewObject -SmtpConfig
		
			$_SmtpConfig.password           = $_DecryptPassword
			$_SmtpConfig.smtpServer         = $Server
			$_SmtpConfig.alertEmailDisabled = if ($alertEmailDisabled.IsPresent) { $True }
												elseif ($alertEmailEnabled.IsPresent) { $False }
												else { $False }

			if ($PSBoundParameters['ConnectionSecurity'])
			{

				$_SmtpConfig.smtpProtocol = $SmtpConnectionSecurityEnum[$ConnectionSecurity]

			}

			Try
			{

				# Get current SMTP Configuration
				$_CurrentSmtpConfiguation = Send-HPOVRequest -Uri $SmtpConfigUri -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($PSBoundParameters['AlertEmailEnabled'] -and -not $PSBoundParameters['SenderEmailAddress'] -and -not $_CurrentSmtpConfiguation.senderEmailAddress) 
			{ 
				
				$ExceptionMessage = 'The -AlertEmailEnabled Parameter requires the -SenderEmailAddress Parameter to be provided when the appliance is first configured.'
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.EmailAlertResourceException InvalidArgumentValue InvalidArgument 'AlertEmailEnabled' -TargetType 'SwitchParameter' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

			elseif ($PSBoundParameters['AlertEmailEnabled'] -and -not $PSBoundParameters['SenderEmailAddress'] -and $_CurrentSmtpConfiguation.senderEmailAddress)
			{

				$_SmtpConfig.senderEmailAddress = $_CurrentSmtpConfiguation.senderEmailAddress

			}
			
			elseif ($PSBoundParameters['SenderEmailAddress'])
			{ 
				
				$_SmtpConfig.senderEmailAddress = $SenderEmailAddress 
			
			}

			elseif ($_CurrentSmtpConfiguation.senderEmailAddress)
			{

				$_SmtpConfig.senderEmailAddress = $_CurrentSmtpConfiguation.senderEmailAddress 
				
			}

			if (-not $_CurrentSmtpConfiguation.smtpServer -and -not $PSBoundParameters['Server'] -and $PSBoundParameters['Port'])
			{

				$ExceptionMessage = "When specifying an SMTP Server Port value, the -Server parameter or an existing SMTP Server value must be present on the appliance."

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.EmailAlertResourceException InvalidSmtpServer InvalidArgument "Port" -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			elseif ($_CurrentSmtpConfiguation.smtpServer -and -not $PSBoundParameters['Server'] -and $PSBoundParameters['Port'])
			{

				"[{0}] Using configured SMTP Server: {1}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_CurrentSmtpConfiguation.smtpServer | Write-Verbose

				$_SmtpConfig.smtpServer = $_CurrentSmtpConfiguation.smtpServer

			}

			if (-not $_CurrentSmtpConfiguation.smtpPort -and -not $PSBoundParameters['Port'] -and $PSBoundParameters['Server'])
			{

				"[{0}] Using default SMTP TCP Port 25." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			else
			{

				$_SmtpConfig.smtpPort = $Port

			}

			# Copy existing email alert filter settings
			if ($_CurrentSmtpConfiguation.alertEmailFilters)
			{

				[Array]$_SmtpConfig.alertEmailFilters = $_CurrentSmtpConfiguation.alertEmailFilters

			}

			# "[{0}] SMTP Configuration: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_resp = Send-HPOVRequest -Uri $SmtpConfigUri -Method POST -Body $_SmtpConfig -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

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
