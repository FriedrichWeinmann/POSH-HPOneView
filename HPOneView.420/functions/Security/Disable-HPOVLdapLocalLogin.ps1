function Disable-HPOVLdapLocalLogin 
{
		
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory = $False)]
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

		$_TaskCollection = New-Object System.Collections.ArrayList
	
	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing Appliance $($_appliance.Name) (of $($ApplianceConnection.Count)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($_appliance.AuthLoginDomain -eq 'LOCAL')
			{

				$ExceptionMessage = 'To disable local login you must log in using another authentication service.'
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AuthSessionException InvalidLoginDomain InvalidOperation 'AuthLoginDomain' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Try
			{
				
				# Get current auth directory configuration
				$_currentDirectoryConfig = Send-HPOVRequest $authnSettingsUri -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($_currentDirectoryConfig.defaultLoginDomain.name -eq 'LOCAL')
			{

				$ExceptionMessage = 'The Default Login Domain must not be set to "LOCAL" before disabling Local Logins.'
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.LdapConfigurationException InvalidDefaultLoginDomain InvalidOperation 'DefaultLoginDomain' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}
			
			"[{0}] Current global authentication settings: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_currentDirectoryConfig | ConvertTo-Json) | Write-Verbose

			if ($PSCmdlet.ShouldProcess($_appliance.Name,"disable local logins")) 
			{

				$_request = 'false'

				Try
				{

					# Update Configuration
					$_resp = Send-HPOVRequest $AuthnAllowLocalLoginUri POST $_request -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
				[void]$_TaskCollection.Add($_resp)

			}

			elseif ($PSBoundParameters['Whatif'])
			{

				"[{0}] WhatIf Parameter was passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

		}
		
	}

	End 
	{

		Return $_TaskCollection

	}

}
