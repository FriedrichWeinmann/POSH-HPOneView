function Set-HPOVLdapGroupRole 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = 'Role')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Role')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Scope')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'RoleAndScope')]
		[ValidateNotNullOrEmpty()]
		[Alias ("g","name",'GroupName', 'Group')]
		[Object]$InputObject,

		[Parameter (Mandatory, ParameterSetName = 'Role')]
		[Parameter (Mandatory, ParameterSetName = 'RoleAndScope')]
		[ValidateNotNullOrEmpty()]
		[Alias ("r","role")]
		[Array]$Roles,
		
		[Parameter (Mandatory, ParameterSetName = 'Scope')]
		[Parameter (Mandatory, ParameterSetName = 'RoleAndScope')]
		[ValidateNotNullOrEmpty()]
		[Array]$ScopePermissions,		

		[Parameter (Mandatory = $false, ParameterSetName = 'Role')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Scope')]
		[Parameter (Mandatory = $false, ParameterSetName = 'RoleAndScope')]
		[ValidateNotNullOrEmpty()]
		[Alias ("u")]
		[string]$UserName,

		[Parameter (Mandatory = $false, ParameterSetName = 'Role')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Scope')]
		[Parameter (Mandatory = $false, ParameterSetName = 'RoleAndScope')]
		[Alias ("p")]
		[ValidateNotNullOrEmpty()]
		[SecureString]$Password,

		[Parameter (Mandatory = $false, ParameterSetName = 'Role')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Scope')]
		[Parameter (Mandatory = $false, ParameterSetName = 'RoleAndScope')]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential,
		
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Role')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Scope')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'RoleAndScope')]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		if ($PSBoundParameters['Username'])
		{

			Write-Warning "The -Username parameter will be deprecated in a future release. Please transition to using the -Credental Parameter."
			
		}

		if ($PSBoundParameters['Password'])
		{

			Write-Warning "The -Username parameter will be deprecated in a future release. Please transition to using the -Credental Parameter."

		}

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		# No need to validate ApplianceConnection, as object is passed via pipeline.
		if (-not $PSboundParameters['InputObject'])
		{

			"[{0}] Pipeline input." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			$PipelineInput = $True

		}

		else
		{

			"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if (-not($ApplianceConnection) -and -not(${Global:ConnectedSessions}))
			{

				$ExceptionMessage = "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command agian."
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message $ExceptionMessage
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

		$_DirectoryGroupsToUpdate = New-Object System.Collections.ArrayList
		$_DirectoryGroupStatus    = New-Object System.Collections.ArrayList

		# Decrypt the password
		if (-not($PSBoundParameters['Password']) -and $PSBoundParameters['Username'])
		{

			do 
			{
				
				$securepass   = Read-Host 'Password' -AsSecureString
				$securepass2  = Read-Host 'Confirm Password' -AsSecureString
				$_DecryptPassword  = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepass))
				$_DecryptPassword2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepass2))

				if ($_DecryptPassword -ne $_DecryptPassword2)
				{

					Write-Host "Passwords do not match!" -BackgroundColor Red

				}

			} until ($_DecryptPassword -eq $_DecryptPassword2)
			
		}

		elseif ($Password -is [SecureString])
		{

			$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

		}

		elseif ($PSBoundParameters['Password'])
		{

			$_DecryptPassword = $Password

		}

		elseif ($PSBoundParameters['Credential'])
		{

			$Username = $Credential.Username
			$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

		}

		else
		{

			"[{0}] Credentials were not provided. Will validate directory object for 'directoryBindingType' in Process block." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

	}

	Process 
	{

		ForEach ($_Group in $InputObject)
		{

			# Validate pipeline input is user object
			if (-not $_Group.category -eq 'users')
			{

				"[{0}] Invalid Group provided: $($_Group )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.LdapDirectoryGroupException InvalidDirectoryGroupObject InvalidArgument "Group" -TargetType 'PSObject' -Message "The Group Parameter value is not a valid Directory Group object resource.  Object category provided '$($Group.category)', allowed object category value 'users'.  Please verify the input object and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			"[{0}] Processing Group: $($_Group.egroup)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_UpdateDirectroyGroup = NewObject -DirectoryGroup
			$_UpdateDirectroyGroup.group2PermissionPerGroup.egroup  = $_Group.egroup
			$_UpdateDirectroyGroup.group2PermissionPerGroup.loginDomain  = $_Group.loginDomain

			"[{0}] Original Group object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_Group | ConvertTo-Json -Depth 99 | Out-String) | Write-Verbose

			# Get the auth directory associated with the group
			Try
			{

				$_Directory = Get-HPOVLdapDirectory -Name $_Group.loginDomain -ApplianceConnection $_Group.ApplianceConnection -ErrorAction Stop

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_unsupportedRoles = New-Object System.Collections.ArrayList
			$_PremissionsCol   = New-Object System.Collections.ArrayList

			if ($PSBoundParameters['Roles'])
			{

				"[{0}] Validating requested role values" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				# Validate roles provided are allowed.
				foreach ($_role in $Roles) 
				{

					"[{0}] Processing role: $_role" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					if (-not ((${Global:ConnectedSessions} | Where-Object Name -EQ $ApplianceConnection.Name).ApplianceSecurityRoles -contains $_role)) 
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

						[void]$_UpdateDirectroyGroup.group2PermissionPerGroup.permissions.Add($_NewPermission)

					}

				}

				if ($_unsupportedRoles.count -ge 1) 
				{ 

					$ExceptionMessage = "The '{0}' role(s) is/are not supported or the correct names.  Please validate the -roles Parameter contains one or more valid roles.  Allowed roles are: {1}." -f [String]::Join(', ', $_unsupportedRoles.ToArray()), [String]::Join(', ', (${Global:ConnectedSessions} | Where-Object Name -EQ $ApplianceConnection.Name).ApplianceSecurityRoles)
					$ErrorRecord = New-ErrorRecord ArgumentException UnsupportedRolesFound InvalidArgument $($MyInvocation.InvocationName.ToString().ToUpper()) -Message $ExceptionMessage
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

						[void]$_UpdateDirectroyGroup.group2PermissionPerGroup.permissions.Add($_NewPermission)					

					}

				}				

			}			

			"[{0}] Directory binding type: '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LdapDirectoryAccountBindTypeEnum[$_Directory.directoryBindingType] | Write-Verbose

			if ($_Directory.directoryBindingType -ne $LdapDirectoryAccountBindTypeEnum['SERVICEACCOUNT'] -and (-not $PSBoundParameters['Username'] -and -not $PSBoundParameters['Credential']))
			{
	
				$ExceptionMessage = 'Please provide valid credentials using either -Username/-Password or -Credential parameters.'
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.LdapAuthenticationException NoValidCredentialParameters AuthenticationError "ApplianceConnection" -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
			}

			elseif ($_Directory.directoryBindingType -eq $LdapDirectoryAccountBindTypeEnum['SERVICEACCOUNT'])
			{

				"[{0}] Adding username to object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_UpdateDirectroyGroup.credentials.userName = $Directory.credential.userName

			}
	
			elseif ($_Directory.directoryBindingType -eq $LdapDirectoryAccountBindTypeEnum['USERACCOUNT'])
			{

				"[{0}] Adding username and password to object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
				# Add credentials to object
				$_UpdateDirectroyGroup.credentials.userName = $Username
				$_UpdateDirectroyGroup.credentials.password = $_decryptPassword
	
			}
			
			"[{0}] Sending request to update '$($_Group.egroup)' group." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_resp = Send-HPOVRequest -Uri $AuthnEgroupRoleMappingUri -Method PUT -Body $_UpdateDirectroyGroup -Hostname $_Group.ApplianceConnection

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_resp.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.AuthDirectoryGroupRoleMapping')

			$_resp

		}

	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
