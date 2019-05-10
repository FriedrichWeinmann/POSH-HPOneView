function New-HPOVLdapGroup 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Scope')]
		[ValidateNotNullOrEmpty()]
		[Alias ("d","domain","authProvider")]
		[Object]$Directory,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'Scope')]
		[ValidateNotNullOrEmpty()]
		[Alias ("g","GroupName","name")]
		[Object]$Group,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ("r","role")]
		[Array]$Roles,

		[Parameter (Mandatory = $false, ParameterSetName = 'Scope')]
		[ValidateNotNullOrEmpty()]
		[Array]$ScopePermissions,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Scope')]
		[ValidateNotNullOrEmpty()]
		[Alias ("u")]
		[string]$Username,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Scope')]
		[Alias ("p")]
		[ValidateNotNullOrEmpty()]
		[Object]$Password,
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = "Scope")]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential,
			
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Scope')]
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

		if (-not($PSBoundParameters['Directory'])) 
		{ 
			
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

		$_DirectroyGroupStatus = New-Object System.Collections.ArrayList

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
		
		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			$_unsupportedRoles = New-Object System.Collections.ArrayList
			$_PremissionsCol   = New-Object System.Collections.ArrayList

			if ($PSBoundParameters['Roles'])
			{

				"[{0}] Validating requested role values" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				# Validate roles provided are allowed.
				foreach ($_role in $Roles) 
				{

					"[{0}] Processing role: $_role" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

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

						[void]$_PremissionsCol.Add($_NewPermission)

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

				# Rebuild the 

				ForEach ($_ScopeToPermission in $ScopePermissions)
				{

					"[{0}] Processing role: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeToPermission.Role | Write-Verbose
					
					if (-not ((${Global:ConnectedSessions} | Where-Object Name -EQ $_appliance.Name).ApplianceSecurityRoles -contains $_ScopeToPermission.Role)) 
					{ 
					
						"[{0}] Invalid or unsupported" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						[void]$_unsupportedRoles.Add($_ScopeToPermission.Role)

					}

					else
					{

						"[{0}] Supported" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						if ([System.String]::IsNullOrWhiteSpace($_ScopeToPermission.Scope))
						{

							Throw "Scope property within ScopePermissions must contain at least 1 entry."

						}

						$_TempName = $_ScopeToPermission.Role.split(' ')

						ForEach ($_Scope in $_ScopeToPermission.Scope)
						{

							if ($_Scope -IsNot [HPOneView.Appliance.ScopeCollection])
							{
	
								Throw ("Invalid scope resource {0}" -f $_Scope.name)
	
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
	
							$_NewPermission.roleName = $_UpdatedName.ToString()
							$_NewPermission.scopeUri = $_Scope.uri
	
							[void]$_PremissionsCol.Add($_NewPermission)

						}						

					}

				}				

			}

			switch ($Group.GetType().Name)
			{

				'String'
				{

					if (-not [HPOneView.Utilities.Security.X500DistinguishedName]::TryParse($Group))
					{

						$Message     = 'The provided -Group Parameter value {0} is not a valid Distinguished Name (DN) value.  Please verify the Group DN follows this format: CN=GroupName,OU=OrganizationalUnit,DC=Domain,DC=com' -f $Group
						$ErrorRecord = New-ErrorRecord ArgumentException InvalidGroupCommonName InvalidArgument 'Group' -Message $Message
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

					}

					$Group = [PSCustomObject]@{ DN = $Group }

				}

				'PSCustomObject'
				{

					if (-not [HPOneView.Utilities.Security.X500DistinguishedName]::TryParse($Group.DN))
					{

						$Message     = 'The provided -Group Parameter value {0} does not contain a valid Distinguished Name (DN) value.  Please verify the Group DN follows this format: CN=GroupName,OU=OrganizationalUnit,DC=Domain,DC=com' -f $Group.Name
						$ErrorRecord = New-ErrorRecord ArgumentException InvalidGroupCommonName InvalidArgument 'Group' -TargetType 'PSObject' -Message $Message
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

					}

				}

			}
		
			# Get new Directory Group object   
			$_NewGroup = NewObject -DirectoryGroup

			$_NewGroup.group2PermissionPerGroup.loginDomain = $Directory.name
			$_NewGroup.group2PermissionPerGroup.egroup      = $Group.DN
			$_NewGroup.group2PermissionPerGroup.permissions = $_PremissionsCol

			if ($Directory.directoryBindingType -ne $LdapDirectoryAccountBindTypeEnum['SERVICEACCOUNT'] -and (-not $PSBoundParameters['Username'] -and -not $PSBoundParameters['Credential']))
			{
	
				$ExceptionMessage = 'Please provide valid credentials using either -Username/-Password or -Credential parameters.'
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.LdapAuthenticationException NoValidCredentialParameters AuthenticationError "ApplianceConnection" -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
				
			}

			elseif ($Directory.directoryBindingType -eq $LdapDirectoryAccountBindTypeEnum['SERVICEACCOUNT'])
			{

				$_NewGroup.credentials.userName = $Directory.credential.userName

			}
	
			elseif ($Directory.directoryBindingType -eq $LdapDirectoryAccountBindTypeEnum['USERACCOUNT'])
			{
	
				# Add credentials to object
				$_NewGroup.credentials.userName = $Username
				$_NewGroup.credentials.password = $_decryptPassword
	
			}			
		
			# "[{0}] Directory Group requested to create:  $($_NewGroup | out-string )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Sending request to create $($_NewGroup.egroup) Directory Group" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			Try
			{

				$_resp = Send-HPOVRequest -Uri $AuthnEgroupRoleMappingUri -Method POST -Body $_NewGroup -Hostname $_appliance

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_resp.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.AuthDirectoryGroupRoleMapping')

			[void]$_DirectroyGroupStatus.Add($_resp)
		   
		}

	}

	End
	{
		
		Return $_DirectroyGroupStatus

	}

}
