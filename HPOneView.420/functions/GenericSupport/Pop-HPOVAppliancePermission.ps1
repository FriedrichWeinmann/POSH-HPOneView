function Pop-HPOVAppliancePermission
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName)]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

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

		$_UpdateToActivePermissions = NewObject -UpdateToActivePermissions

		$_UpdateToActivePermissions.sessionID = $ApplianceConnection.SessionID

		ForEach ($_Permission in $ApplianceConnection.ActivePermissions)
		{

			$_PermissionToActivate = NewObject -DirectoryGroupPermissions
			$_PermissionToActivate.roleName = $_Permission.RoleName

			if (-not [String]::IsNullOrWhiteSpace($_Permission.ScopeUri))
			{

				$_PermissionToActivate.scopeUri = $_Permission.ScopeUri

			}

			[void]$_UpdateToActivePermissions.permissionsToActivate.Add($_PermissionToActivate)

		}

		# Take the URI of the scopeUris and do a POST $UpdateApplianceSessionAuthUri to get new SessionID
		Try
		{

			$_UpdatedSessionID = Send-HPOVRequest -Uri $UpdateApplianceSessionAuthUri -Method POST -Body $_UpdateToActivePermissions -ApplianceConnection $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		# Update the appliance connection object 
		"[{0}] Updating SessionID of the appliance connection." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		($ConnectedSessions | Where-Object Name -match $ApplianceConnection.Name).SetSessionID($_UpdatedSessionID.sessionID)

		# After the new sessionID has successfully been created, look at what existing permissions there are. Set the ones that do not 
		#   match the $SetActivePermissions to .UpdateState($false)

		"[{0}] Updating ActivePermission(s) that were changed to 'false'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		ForEach ($_PermissionToUpdate in $ApplianceConnection.ActivePermissions)
		{

			$_PermissionToUpdate.UpdateState($true)

		}

		$ApplianceConnection.ActivePermissions

	}

}
