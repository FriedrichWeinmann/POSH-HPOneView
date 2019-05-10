function New-HPOVScope
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$Description,

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

	}

	Process
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing {1} appliance connection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			$_Scope = New-Object HPOneView.Appliance.Scope($Name, $Description)

			# Get Scope resource
			Try
			{

				$_ScopeTask = Send-HPOVRequest -Uri $ScopesUri -Method POST -Body $_Scope -Hostname $_appliance	| Wait-HPOVTaskComplete			

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($_ScopeTask.taskState -eq 'Completed')
			{

				try
				{

					$_scoperesource = Send-HPOVRequest -Uri $_ScopeTask.associatedResource.resourceUri -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				# Return Strongly typed object
				New-Object HPOneView.Appliance.ScopeCollection($_Scope.name, 
															   $_Scope.description, 
															   $_Scope.uri, 
															   $_Scope.eTag, 
															   (New-Object HPOneView.Library.ApplianceConnection($_appliance.Name, $_appliance.ConnectionId)))

			}

			else
			{

				$ExceptionMessage = [String]::Join(' ', $_ScopeTask.taskErrors.message)
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ScopeResourceException InvalidResult InvalidResult 'ApplianceConnection' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}			

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
