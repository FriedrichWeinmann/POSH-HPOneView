function Add-HPOVSmtpAlertEmailFilter 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param
	(

		[Parameter (Mandatory, ParameterSetName = "RemoteSupportFilter")]
		[Switch]$RemoteSupportFilter,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[System.String]$Name,
	
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('query')]
		[ValidateNotNullOrEmpty()]
		[System.String]$Filter,

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[Alias ('recipients')]
		[ValidateNotNullOrEmpty()]
		[validatescript({$_ | ForEach-Object { if ($_ -as [Net.Mail.MailAddress]) {$true} else { Throw "The Parameter value '$_' is not an email address. Please correct the value and try again." }}})]
		[System.Array]$Emails,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[System.Array]$Scope,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateSet ('AND','OR')]
		[System.String]$ScopeMatchPreference = 'OR',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "RemoteSupportFilter")]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "RemoteSupportFilter")]
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

		$colStatus = New-Object System.Collections.ArrayList

		if (-not($PSBoundParameters['Filter']))
		{

			Write-Warning 'The Filter provided is Null or Empty.  This will return all resources and severities, which will cause performance issues in a large environment.'

		}

		# This is needed as the scopeQuery property cannot be null
		if (-not $PSBoundParameters['Scope'])
		{

			[String]$Scope = ""

		}

		else
		{

			$_ScopeEntries = New-Object System.Collections.ArrayList

			ForEach ($_entry in $Scope)
			{

				if (-not $_entry.StartsWith("scope:'"))
				{

					$_entry = "scope:'{0}'" -f $_entry
					
				}

				[void]$_ScopeEntries.Add($_entry)				

			}

			[String]$Scope = [System.String]::Join(" $ScopeMatchPreference ",$_ScopeEntries.ToArray())

		}

	}
	 
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			$_resp = $null

			if ($PSBoundParameters['RemoteSupportFilter'])
			{

				"[{0}] Getting current remote support configuration from '{1}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance | Write-Verbose

				Try
				{

					$_remoteSupportConfig = Send-HPOVRequest -Uri $RemoteSupportConfigUri -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if (-not $_remoteSupportConfig.enableEmailNotification)
				{

					$_remoteSupportConfig.enableEmailNotification = $true

					"[{0}] Enabling remote support email filter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_resp = Send-HPOVRequest -Uri $RemoteSupportConfigUri -Method PUT -Body $_remoteSupportConfig -Hostname $_appliance.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				else
				{

					"[{0}] Remote support email filter already configured." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

			}

			else
			{

				"[{0}] Getting current SMTP Configuration from '$($_appliance.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_smtpFilterConfiguration = Send-HPOVRequest $SmtpConfigUri -Hostname $_appliance.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
				$_OriginalFilterConfig = $_smtpFilterConfiguration.alertEmailFilters

				# Rebuild property as ArrayList
				$_smtpFilterConfiguration.alertEmailFilters = New-Object System.Collections.ArrayList

				$_OriginalFilterConfig | ForEach-Object {

					[void]$_smtpFilterConfiguration.alertEmailFilters.Add($_)

				}
			
				# Create new alert filter object
				$_alertFilter = NewObject -AlertFilter
			
				$_alertFilter.filter          = $filter
				$_alertFilter.displayFilter   = $filter
				$_alertFilter.userQueryFilter = $filter
				$_alertFilter.emails          = $Emails
				$_alertFilter.scopeQuery      = $Scope
				$_alertFilter.filterName      = $Name

				"[{0}] Processing SMTP Alert Configuration for '$($_appliance.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[void]$_smtpFilterConfiguration.alertEmailFilters.Add($_alertFilter)

				Try
				{

					$_resp = Send-HPOVRequest -Uri $SmtpConfigUri -Method POST -Body $_smtpFilterConfiguration -Hostname $_appliance.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			if ($null -ne $_resp)
			{

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

	}
	
	End 
	{
	
		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
	
	}

}
