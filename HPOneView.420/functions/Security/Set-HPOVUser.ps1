function Set-HPOVUser 
{
	 
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'default')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Pipeline')]
		[ValidateNotNullorEmpty()]
		[Object]$UserObject,

		[Parameter (Mandatory, ParameterSetName = 'default')]
		[ValidateNotNullorEmpty()]
		[string]$UserName, 

		[Parameter (Mandatory = $false, ParameterSetName = 'default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Pipeline')]
		[ValidateNotNullorEmpty()]
		[string]$Password, 

		[Parameter (Mandatory = $false, ParameterSetName = 'default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Pipeline')]
		[ValidateNotNullorEmpty()]
		[string]$FullName, 

		[Parameter (Mandatory = $false, ParameterSetName = 'default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Pipeline')]
		[ValidateNotNullorEmpty()]
		[Array]$Roles, 

		[Parameter (Mandatory = $false, ParameterSetName = 'default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Pipeline')]
		[ValidateNotNullorEmpty()]
		[Array]$ScopePermissions,

		[Parameter (Mandatory = $false, ParameterSetName = 'default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Pipeline')]
		[validatescript({$_ -as [Net.Mail.MailAddress]})]
		[string]$EmailAddress,

		[Parameter (Mandatory = $false, ParameterSetName = 'default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Pipeline')] 
		[ValidateNotNullorEmpty()]
		[string]$OfficePhone,
	 
		[Parameter (Mandatory = $false, ParameterSetName = 'default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Pipeline')]
		[ValidateNotNullorEmpty()]
		[string]$MobilePhone,
	 
		[Parameter (Mandatory = $false, ParameterSetName = 'default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Pipeline')]
		[Alias ('enable')]
		[ValidateNotNullorEmpty()]
		[switch]$Enabled,

		[Parameter (Mandatory = $false, ParameterSetName = 'default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Pipeline')]
		[Alias ('disable')]
		[ValidateNotNullorEmpty()]
		[switch]$Disabled,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'default')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Pipeline')]
		[Alias ('Appliance')]
		[ValidateNotNullorEmpty()]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		# No need to validate ApplianceConnection, as object is passed via pipeline.
		if ($PSCmdlet.ParameterSetName -eq 'Pipeline')
		{

			"[{0}] Pipeline input." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			$PipelineInput = $True

		}

		else
		{

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

		$_UsersToUpdate = New-Object System.Collections.ArrayList
		$_UserStatus    = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput)
		{

			# Validate pipeline input is user object
			if (-not($UserObject -is [PSCustomObject]) -and -not($UserObject.category -eq 'users'))
			{

				"[{0}] Invalid UserObject provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.UserResourceException InvalidUserObject InvalidArgument "UserObject" -TargetType 'PSObject' -Message "The UserObject Parameter value is not a valid User object resource.  Object category provided '$($UserObject.category)', allowed object category value 'users'.  Please verify the input object and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			"[{0}] Adding UserObject to Process collection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $UserObject.Username | Write-Verbose

			[void]$_UsersToUpdate.Add($UserObject)

		}

		else
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				try 
				{ 
					
					$_UserObject = Get-HPOVUser -Name $userName -ApplianceConnection $_appliance
				
				}
		
				# If not found, throw error
				catch [HPOneView.Appliance.UserResourceException]
				{
				
					# Generate terminating error
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.UserResourceException UserNotFound ObjectNotFound 'UserName' -Message "Username `'$userName`' was not found. Please check the spelling, or create the user and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				[void]$_UsersToUpdate.Add($_UserObject)

			}

		}

	}

	End
	{

		ForEach ($_User in $_UsersToUpdate)
		{

			"[{0}] Processing User: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_User.userName | Write-Verbose

			if ($PSBoundParameters['Roles'] -or $PSBoundParameters['ScopePermissions'])
			{

				$_user.permissions = New-Object System.Collections.ArrayList

			}

			#$_User | Add-Member -NotePropertyName type -NotePropertyValue 'UserAndRoles'

			switch ($PSBoundParameters.keys) 
			{

				"Password" 
				{ 

					if ($_User.userName -eq (${Global:ConnectedSessions} | Where-Object Name -eq $_User.ApplianceConnection.Name).UserName) 
					{

						write-warning "This CMDLET will not modify the password for your account.  Please use the Set-HPOVUserPassword CMDLET to update your user account password.  Password update will not be Processed."

					}  
								  
					else 
					{ 
						
						$_User | Add-Member -NotePropertyName password -NotePropertyValue $Password -force
						
					} 
				
				}

				"fullName" 
				{ 
					
					$_User.fullName = $FullName
				
				}

				"roles" 
				{

					if ($_User.userName -eq (${Global:ConnectedSessions} | Where-Object Name -eq $_User.ApplianceConnection.Name).UserName) 
					{

						write-warning "Unable to modify roles for your account, as you must be authenticated to the appliance with a different administrator account.  Roles will not be Processed."

					}

					else 
					{
					
						$_User | add-member -NotePropertyName replaceRoles -NotePropertyValue $True -force

						# Validate roles provided are allowed.
						$_unsupportedRoles = New-Object System.Collections.ArrayList
						$_NewUserRoles     = New-Object System.Collections.ArrayList

						# Validate roles provided are allowed.
						foreach ($_role in $Roles) 
						{
			
							"[{0}] Processing role: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_role | Write-Verbose
			
							if (-not ((${Global:ConnectedSessions} | Where-Object Name -EQ $_User.ApplianceConnection.Name).ApplianceSecurityRoles -contains $_role)) 
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
					
							$ExceptionMessage = "The '{0}' role(s) is/are not supported or the correct names.  Please validate the -roles Parameter contains one or more valid roles.  Allowed roles are: {1}" -f [String]::Join(', ', $_unsupportedRoles.ToArray()), [String]::Join(', ', (${Global:ConnectedSessions} | Where-Object Name -EQ $_User.ApplianceConnection.Name).ApplianceSecurityRoles.ToArray())
							$ErrorRecord = New-ErrorRecord ArgumentException UnsupportedRolesFound InvalidArgument 'Roles' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)            
						
						}

					}

				}			

				# Process scopes with permissions
				'ScopePermissions'
				{

					$_User | add-member -NotePropertyName replaceRoles -NotePropertyValue $True -force

					ForEach ($_ScopeToPermission in $ScopePermissions)
					{

						"[{0}] Processing role: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeToPermission.Role | Write-Verbose
						
						if ((${Global:ConnectedSessions} | Where-Object Name -EQ $_user.ApplianceConnection.Name).ApplianceSecurityRoles -notcontains $_ScopeToPermission.Role)
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

				"emailAddress" 
				{ 
					
					$_User.emailAddress = $EmailAddress
				
				}

				"officePhone" 
				{ 
					
					$_User.officePhone = $OfficePhone
				
				}

				"mobilePhone" 
				{ 
					
					$_User.mobilePhone = $MobilePhone
				
				}

				"enabled" 
				{ 
				
					if ($_User.userName -eq (${Global:ConnectedSessions} | Where-Object Name -eq $_User.ApplianceConnection.Name).UserName) 
					{

						write-warning "This CMDLET will not modify the state for your account.  Please authenticate to the appliance with a different administrator account.  Account state will not be Processed."

					}

					else 
					{ 
						
						$_User.enabled = $true
					
					}

				}

				"disabled" 
				{ 

					if ($_User.userName -eq (${Global:ConnectedSessions} | Where-Object Name -eq $_User.ApplianceConnection.Name).UserName) 
					{

						write-warning "This CMDLET will not modify the state for your account.  Please authenticate to the appliance with a different administrator account.  Account state will not be Processed."

					}

					else 
					{ 
						
						$_User.enabled = $false

					}

				}

			}

			# "[{0}] Updated User object: $($_User )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Sending request to update `'$($_User.userName)`' user at '$ApplianceUserAccountsUri'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_resp = Send-HPOVRequest $ApplianceUserAccountsUri PUT $_User -Hostname $_User.ApplianceConnection.Name

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_resp.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.User')

			[void]$_UserStatus.Add($_resp)

		}
		
		Return $_UserStatus

	}

}
