function Set-HPOVApplianceSecurityProtocol
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default', SupportsShouldProcess, ConfirmImpact = 'High')]
	[OutputType([System.Collections.Generic.List[HPOneView.Appliance.SecurityProtocol]], ParameterSetName = "Default")]
	param
	(

		[Parameter (ParameterSetName = 'Default', Mandatory)]
		[ValidateSet ('TLSv1', 'TLSv1.1', 'TLSv1.2')]
		[String[]]$EnableTlsVersion,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = ($ConnectedSessions | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection) -and -not($ConnectedSessions))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command agian."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif ($ApplianceConnection -is [System.Collections.IEnumerable] -and $ApplianceConnection -isnot [System.String])
		{

			For ([int]$c = 0; $c -gt $ApplianceConnection.Count; $c++)
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

		$_SecurityProtocolsToSet = NewObject -ApplianceSecurityProtocols

		ForEach ($_Protocol in $EnableTlsVersion)
		{

			"[{0}] Will enable '{1}' security protocol." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Protocol | Write-Verbose

			($_SecurityProtocolsToSet | Where-Object protocolName -eq $_Protocol).enabled = $true

		}

		$_ApplianceProtocolsCollection = New-Object 'System.Collections.Generic.List[HPOneView.Appliance.SecurityProtocol]'

	}

	Process
	{		

		ForEach ($_appliance in $ApplianceConnection)
		{

			$_WaitedFoReboot = $false

			"[{0}] Processing appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Write-Warning "Changing the appliance security protocol(s) will immediately reboot the appliance."

			$_ShouldProcessMessage = "enable only '{0}' security protocol(s)" -f [String]::Join("','", $EnableTlsVersion)

			if ($PSCmdlet.ShouldProcess($_appliance, $_ShouldProcessMessage))
			{

				try
				{

					$_CurrentSecurityMode = Send-HPOVRequest -Uri $ApplianceSecurityProtocolsUri -Method PUT -Body $_SecurityProtocolsToSet -Hostname $_appliance

				}

				catch
				{

					# Appliance has likely rebooted.
					if ($_.Exception.Message -match 'The operation has timed out' -or $_.Exception.Message -match 'An unexpected error occurred on a receive')
					{

						Write-Warning "Appliance has now started to reboot."

						# Lets wait 10 minutes for appliance to reboot.  Waiting less time may cause excessive timeout issues waiting for heavily loaded appliance from rebooting in time.
						Wait-Reboot

						$_WaitedFoReboot = $true

					}

					else
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				try
				{

					# In case the appliance didn't reboot in time and cause the operation timed out exception
					if (-not $_WaitedFoReboot)
					{

						Wait-Reboot

					}					

					Get-HPOVApplianceSecurityProtocol -ApplianceConnection $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

		}		

	}

	end
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
