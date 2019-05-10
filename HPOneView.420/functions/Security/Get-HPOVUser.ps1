function Get-HPOVUser 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[Alias ('Username')]
		[ValidateNotNullorEmpty()]
		[string]$Name,
		
		[Parameter (Mandatory = $false)]
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
		
		$_UserCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			$_Query = New-Object System.Collections.ArrayList

			$_Category = "category=users&"

			if ($Name)
			{

				if ($Name.Contains('*'))
				{

					[Void]$_Query.Add(("user_name%3A{0}" -f $Name.Replace(" ","?").Replace("*", "%2A")))

				}

				else
				{

					[Void]$_Query.Add(("user_name:'{0}'" -f $Name))

				}                
				
			}

			# Build the final URI
			$_uri = '{0}?{1}sort=name:asc&query={2}' -f $IndexUri, $_Category.ToString(), [String]::Join(' AND ', $_Query.ToArray())

			Try
			{

				$_users = Get-AllIndexResources -Uri $_uri -ApplianceConnection $_appliance

				if ($_users.count -eq 0 -and $Name) 
				{
				
					$_Message    = "Username '{0}' was not found on {1} Appliance Connection. Please check the spelling, or create the user and try again." -f $Name, $_appliance.Name 
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.UserResourceException UserNotFound ObjectNotFound "Name" -Message $_Message
					$PSCmdlet.WriteError($ErrorRecord)

				}

			}

			# User isn't authorized, so let's display their user account
			Catch [HPOneView.Appliance.AuthPrivilegeException]
			{

				Try
				{

					$_user = Send-HPOVRequest ($ApplianceUserAccountsUri + '/' + $_appliance.Username) -Hostname $_appliance.Name 

					$_user.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.User')

					[void]$_UserCollection.Add($_user)

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			"[{0}] Found {1} user resources on '{2}' appliance." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_users.count, $_appliance.Name | Write-Verbose

			if ($_users)
			{

				ForEach ($u in $_users) 
				{

					$u.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.User')

					[void]$_UserCollection.Add($u)

				}

			}
			
		}

	}

	End 
	{

		"Done. {0} user(s) found." -f $_UserCollection.count | Write-Verbose 
		
		Return $_UserCollection    

	}

}
