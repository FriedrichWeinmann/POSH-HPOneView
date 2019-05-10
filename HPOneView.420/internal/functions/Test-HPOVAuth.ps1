function Test-HPOVAuth
{

	[CmdletBinding ()]
	Param
	(
	
		[Parameter (Mandatory = $false, ValueFromPipeline)]
		[AllowEmptyString()]
		[Object]$Appliance
	
	)

	Begin 
	{

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Caller: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($PSBoundParameters['Appliance'])
		{

			"[{0}] Verify Auth for {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Appliance | Write-Verbose

		}

		else
		{

			"[{0}] -Appliance value via pipeline." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			$PipelineInput = $True

		}

		$_ApplianceConnections = New-Object System.Collections.ArrayList

	}

	Process
	{

		if ([string]::IsNullOrWhiteSpace($Appliance))
		{
		
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "$($Caller):$($_Appliance)" -Message 'No default active HPOV connection session found (check ${Global:ConnectedSessions} global variable.)  Using this cmdlet requires either a default connection or the -ApplianceConnection parameter. Please use Connect-HPOVMgmt, if required, to establish a connection, or set a default connection and then try your command again.'
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
		
		}

		if ($PipelineInput)
		{
	
			"[{0}] Verify Auth for {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Appliance.Name | Write-Verbose

		}
		
		if ($Appliance -is [System.Collections.IEnumerable])
		{

			ForEach ($_Appliance in $Appliance)
			{

				Switch ($_Appliance.GetType().FullName)
				{

					'HPOneView.Appliance.Connection'
					{

						"[{0}] Received HPOneView.Appliance.Connection Object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_Appliance | Out-String) | Write-Verbose

						If (-not(${Global:ConnectedSessions} | Where-Object name -eq $_Appliance.Name))
						{

							$ExceptionMessage = "No Appliance connection session found for '{0}' within `$Global:ConnectedSessions global variable.  This CMDLET requires at least one active connection to an appliance.  Please use Connect-HPOVMgmt to establish a connection, then try your command again." -f $_Appliance.Name
							$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "$($Caller):$($_Appliance.Name)" -Message $ExceptionMessage

						}

						if ($_Appliance.SessionID -eq 'TemporaryConnection')
						{

							$ExceptionMessage = "The ApplianceConnection provided is a Temporary Connection, which is an invlaid state your PowerShell environment has become.  Plesae restart your session and try your calls again."
							$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException InvalidApplianceConnectionState InvalidOperation "$($Caller):$($_Appliance.Name)" -Message $ExceptionMessage

						}

						$_Appliance = $Appliance

					}

					'System.String'
					{

						if (-not(${Global:ConnectedSessions} | Where-Object name -eq $_Appliance))
						{

							$ExceptionMessage = "No connection session found for '{0}' within `$Global:ConnectedSessions global variable.  This CMDLET requires at least one active connection to an appliance.  Please use Connect-HPOVMgmt to establish a connection, then try your command again." -f $_Appliance
							$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "$($Caller):$($_Appliance)" -Message $ExceptionMessage

						}

						elseif (${Global:ConnectedSessions} | Where-Object name -eq $_Appliance)
						{
					
							$_Appliance = ${Global:ConnectedSessions} | Where-Object name -eq $_Appliance

						}

					}

					{'System.Management.Automation.PSCustomObject', 'HPOneView.Library.ApplianceConnection' -contains $_}
					{

						"[{0}] Received PSCustomObject: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_Appliance | Out-String) | Write-Verbose

						If (-not(${Global:ConnectedSessions} | Where-Object name -eq $_Appliance.Name))
						{

							$ExceptionMessage = "No Appliance connection session found for '{0}' within `$Global:ConnectedSessions global variable.  This CMDLET requires at least one active connection to an appliance.  Please use Connect-HPOVMgmt to establish a connection, then try your command again." -f $_Appliance.Name
							$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "$($Caller):$($_Appliance.Name)" -Message $ExceptionMessage

						}

						$_Appliance = ${Global:ConnectedSessions} | Where-Object name -eq $_Appliance.Name

					}

					default
					{

						"[{0}] Unsupported ApplianceConnection object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Appliance.GetType().FullName | Write-Verbose

						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NotaValidApplianceConnection AuthenticationError "$($Caller)" -Message "The provided appliance object is not valid, as it is neither an [HPOneView.Appliance.Connection] object, [String] value representing a potentially valid Appliance Connection, or a [PSCustomObject] property of a resource object obtained from an appliance.  Please correct the ApplianceConnection Parameter value, and then try your command again."

					}

				}

				If ($ErrorRecord)
				{ 

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				Else
				{

					[void]$_ApplianceConnections.Add($_Appliance)

				}

			}

		}

		else
		{

			"[{0}] `$Appliance is [{1}]"  -f $MyInvocation.InvocationName.ToString().ToUpper(), $Appliance.GetType().FullName | Write-Verbose

			Switch ($Appliance.GetType().FullName)
			{

				'HPOneView.Appliance.Connection'
				{

					"[{0}] Received HPOneView.Appliance.Connection Object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($Appliance | Out-String) | Write-Verbose

					If (-not(${Global:ConnectedSessions} | Where-Object name -eq $Appliance.Name))
					{

						$ExceptionMessage = "No Appliance connection session found for '{0}' within `$Global:ConnectedSessions global variable.  This CMDLET requires at least one active connection to an appliance.  Please use Connect-HPOVMgmt to establish a connection, then try your command again." -f $_Appliance.Name
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "$($Caller):$($_Appliance.Name)" -Message $ExceptionMessage

					}

				}

				'System.String'
				{

					if (-not(${Global:ConnectedSessions} | Where-Object name -eq $_Appliance))
					{

						$ExceptionMessage = "No connection session found for '{0}' within `$Global:ConnectedSessions global variable.  This CMDLET requires at least one active connection to an appliance.  Please use Connect-HPOVMgmt to establish a connection, then try your command again." -f $_Appliance
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "$($Caller):$($_Appliance)" -Message $ExceptionMessage

					}

					elseif (${Global:ConnectedSessions} | Where-Object name -eq $_Appliance)
					{
					
						$Appliance = ${Global:ConnectedSessions} | Where-Object name -eq $Appliance

					}

				}

				{'System.Management.Automation.PSCustomObject', 'HPOneView.Library.ApplianceConnection' -contains $_}
				{

					If (-not(${Global:ConnectedSessions} | Where-Object name -eq $Appliance.Name))
					{

						$ExceptionMessage = "No Appliance connection session found for '{0}' within `$Global:ConnectedSessions global variable.  This CMDLET requires at least one active connection to an appliance.  Please use Connect-HPOVMgmt to establish a connection, then try your command again." -f $Appliance.Name
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "$($Caller):$($Appliance.Name)" -Message $ExceptionMessage

					}

					$Appliance = ${Global:ConnectedSessions} | Where-Object name -eq $Appliance.Name

				}

				default
				{

					"[{0}] Unsupported ApplianceConnection object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NotaValidApplianceConnection AuthenticationError "$($Caller)" -Message "The provided appliance object is not valid, as it is neither an [HPOneView.Appliance.Connection] object, [String] value representing a potentially valid Appliance Connection, or a [PSCustomObject] property of a resource object obtained from an appliance.  Please correct the ApplianceConnection Parameter value, and then try your command again."

				}

			}

			If ($ErrorRecord)
			{ 

				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Else
			{

				[void]$_ApplianceConnections.Add($Appliance)

			}

		}		

	}

	End
	{
	
		Return $_ApplianceConnections

	}

}
