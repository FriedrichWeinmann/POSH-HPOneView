function Set-HPOVApplianceCurrentSecurityMode
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default', SupportsShouldProcess, ConfirmImpact = 'High' )]
	param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[HPOneView.Appliance.SecurityMode]$SecurityMode,

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

		$_CollectionName = New-Object System.Collections.ArrayList

	}

	Process
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Switch ($SecurityMode.ModeName)
			{

				'FIPS'
				{

					Write-Warning 'While in FIPS cryptography mode, the appliance uses strong cryptographic protocols and ciphers for all internal and external configuration and communications as defined by the FIPS standard.'

				}

				'CNSA'
				{

					Write-Warning 'While in CNSA cryptography mode, the appliance uses strong cryptographic protocols and ciphers for all internal and external configuration and communications as defined by the CNSA standard.'

				}

			}

			Write-Host ""
			Write-Warning "Changing the cryptography mode will generate new appliance certificates if the current certificates are self-signed and are not compatible with the new cryptography mode. Any externally signed appliance certificates will need to be re-imported by the user before changing the mode.`r`n`r`nIt is extremely important to create and review the compatibility report for the new cryptography mode before proceeding. Not doing so could result in disruptions to the normal operation of the appliance. Cancel this operation and review the report if you have not already done so."

			$_uri = '{0}' -f $ApplianceCurrentSecurityModeUri

			$_Body = @{
				modeName = $SecurityMode.ModeName
			}

			$_Message = 'change appliance active security mode to "{0}"' -f $SecurityMode.ModeName

			if ($PSCmdlet.ShouldProcess($_appliance, $_Message))
			{

				Try
				{

					Send-HPOVRequest -Uri $_uri -Method PUT -Body $_Body -ApplianceConnection $_appliance | Wait-HPOVTaskComplete -ApplianceWillReboot

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
