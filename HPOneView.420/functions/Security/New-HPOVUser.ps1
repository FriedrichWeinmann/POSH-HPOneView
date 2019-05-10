function New-HPOVUser 
{
	 
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[string]$UserName, 

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[string]$Password, 

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[string]$FullName, 

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Array]$Roles = @(),
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Array]$ScopePermissions,	

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[validatescript({$_ -as [Net.Mail.MailAddress]})]
		[string]$EmailAddress,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')] 
		[ValidateNotNullOrEmpty()]
		[string]$OfficePhone,
	 
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[string]$MobilePhone,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[switch]$Enabled,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{


		if ($PSBoundParameters['Enabled'])
		{

			Write-Warning 'The -Enabled Parameter is now deprecated.  By default, all new user accounts will be enabled.  In order to disable a user account, use the Set-HPOVUser Cmdlet.'

		}

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
		
		$_UserStatus = New-Object System.Collections.ArrayList

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			"[{0}] Validating requested role values" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			$_unsupportedRoles = New-Object System.Collections.ArrayList
			$_NewUserRoles     = New-Object System.Collections.ArrayList

			$_user = NewObject -UserAccount

			$_user.userName     = $userName
			$_user.fullName     = $fullName
			$_user.password     = $password
			$_user.emailAddress = $emailAddress
			$_user.officePhone  = $officePhone 
			$_user.mobilePhone  = $mobilePhone
			$_user.enabled      = $true

			# Validate roles provided are allowed.
			if ($PSBoundParameters['Roles'])
			{
				foreach ($_role in $Roles) 
				{
	
					"[{0}] Processing role: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_role | Write-Verbose
	
					if (-not ((${Global:ConnectedSessions} | Where-Object Name -EQ $_appliance.Name).ApplianceSecurityRoles -contains $_role)) 
					{ 
					
						"[{0}] Invalid or unsupported" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
						[void]$_unsupportedRoles.Add($_role)
				
					}

					else
					{

						"[{0}] Supported" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_TempName = $_role.split(' ')

						$_NewPermission = NewObject -DirectoryGroupPermissions

						$_UpdatedName = New-Object System.Text.StringBuilder

						for ($s = 0; $s -lt $_TempName.count; $s++) 
						{

							if ($s -eq 0) 
							{ 
								
								[void]$_UpdatedName.Append($_TempName[$s].Substring(0, 1).ToUpper() + $_TempName[$s].SubString(1, ($_TempName[$s].length - 1)).ToLower()) 
							
							}

							else 
							{

								[void]$_UpdatedName.Append(" " + $_TempName[$s].ToLower()) 
							
							}

						}

						$_NewPermission.roleName = $_UpdatedName.ToString()

						[void]$_user.permissions.Add($_NewPermission)

					}
	
				}
	
				if ($_unsupportedRoles.count -ge 1) 
				{ 
			
					$ErrorRecord = New-ErrorRecord ArgumentException UnsupportedRolesFound InvalidArgument $($MyInvocation.InvocationName.ToString().ToUpper()) -Message "The '$($_unsupportedRoles -join ", ")' role(s) is/are not supported or the correct names.  Please validate the -roles Parameter contains one or more valid roles.  Allowed roles are: $((${Global:ConnectedSessions} | ? Name -EQ $_appliance.Name).ApplianceSecurityRoles -join ", ")"
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)            
				
				}

			}

			# Process scopes with permissions
			if ($PSBoundParameters['ScopePermissions'])
			{

				ForEach ($_ScopeToPermission in $ScopePermissions)
				{

					"[{0}] Processing role: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeToPermission.Role | Write-Verbose
					
					if ((${Global:ConnectedSessions} | Where-Object Name -EQ $ApplianceConnection.Name).ApplianceSecurityRoles -notcontains $_ScopeToPermission.Role)
					{ 
					
						"[{0}] Invalid or unsupported" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						[void]$_unsupportedRoles.Add($_ScopeToPermission.Role)

					}

					else
					{

						"[{0}] Supported role." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						if ([System.String]::IsNullOrWhiteSpace($_ScopeToPermission.Scope))
						{

							Throw "Scope property within ScopePermissions must contain at least 1 entry."

						}

						$_TempName = $_ScopeToPermission.Role.split(' ')

						"[{0}] Process scope." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						"[{0}] Scope object type: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeToPermission.Scope.GetType().Fullname | Write-Verbose
						"[{0}] Scope object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeToPermission.Scope | Write-Verbose

						if ($_ScopeToPermission.Scope -IsNot [HPOneView.Appliance.ScopeCollection] -and $_ScopeToPermission.Scope -ne 'All')
						{

							Throw ("Invalid scope resource {0}" -f $_ScopeToPermission.Name)

						}

						elseif ($_ScopeToPermission.Scope -eq 'All')
						{

							"[{0}] Scope is not an HPOneView.Appliance.ScopeCollection resource, but String 'All'.  Will set uri to null." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							$_Scope = [PSCustomObject]@{uri = $null}

						}

						else
						{

							$_Scope = $_ScopeToPermission.Scope

						}
						
						$_NewPermission = NewObject -DirectoryGroupPermissions

						$_UpdatedName = New-Object System.Text.StringBuilder

						for ($s = 0; $s -lt $_tempname.count; $s++) 
						{

							if ($s -eq 0) 
							{ 
								
								[void]$_UpdatedName.Append($_TempName[$s].Substring(0, 1).ToUpper() + $_TempName[$s].SubString(1, ($_TempName[$s].length - 1)).ToLower()) 
							
							}

							else 
							{

								[void]$_UpdatedName.Append(" " + $_TempName[$s].ToLower()) 
							
							}

						}
						
						"[{0}] Adding Role '{1}' -> '{2}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_UpdatedName.ToString(), $_Scope.uri | Write-Verbose

						$_NewPermission.roleName = $_UpdatedName.ToString()
						$_NewPermission.scopeUri = $_Scope.uri

						[void]$_user.permissions.Add($_NewPermission)					

					}

				}				

			}			

			"[{0}] Sending request to create user: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_user.userName | Write-Verbose
		
			Try
			{

				$_resp = Send-HPOVRequest -Uri $ApplianceUserAccountsUri -Method POST -Body $_user -Hostname $_appliance

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_resp.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.User')

			$_resp

		}

	}

	End
	{
		
		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
