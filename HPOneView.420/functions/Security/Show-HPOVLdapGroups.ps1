function Show-HPOVLdapGroups 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'PSCredential')]
		[ValidateNotNullOrEmpty()]
		[Alias ("d","domain","AuthProvider")]
		[Object]$Directory,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ("u")]
		[string]$UserName,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Alias ("p")]
		[ValidateNotNullOrEmpty()]
		[SecureString]$Password,
		
		[Parameter (Mandatory = $false, ParameterSetName = "PSCredential")]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $False, ParameterSetName = 'PSCredential')]
		[ValidateNotNullOrEmpty()]
		[string]$GroupName,
			
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'PSCredential')]
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

		if (-not $Directory) 
		{

			$PipelineINput = $true

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

			$Password = $securepass
			
		}

		elseif (-not $PSBoundParameters['Password'] -and -not $PSBoundParameters['Username'] -and -not $PSBoundParameters['Credential'])
		{

			"[{0}] Credentials were not provided. Will validate directory object for 'directoryBindingType' in Process block." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		$_DirectoryGroupsCollection = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{
		
			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			if ($PSBoundParameters['Directory'])
			{

				"[{0}] Validating directory parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				switch ($Directory.GetType().Name)
				{

					'String'
					{

						"[{0}] Looking for directory by name." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
						Try
						{
						
							$Directory = Get-HPOVLdapDirectory -Name $Directory -ApplianceConnection $_appliance

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

					'PSCustomObject'
					{

						"[{0}] Directory object provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						if ($Directory.type -notmatch 'LoginDomainConfig')
						{

							$ExceptionMessage = 'The provided -Directory Parameter value is not a support object type, {0}.  Please verify the object.' -f $Directory.name
							$ErrorRecord      = New-ErrorRecord ArgumentException InvalidGroupCommonName InvalidArgument 'Group' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

						}

					}

				}

				$_Search = $Directory.baseDN

			}
			
			if ($PSBoundParameters['GroupName'])
			{

				$_Search = $GroupName

			}

			Try
			{ 

				$_Params = @{

					Search              = $_Search;
					Directory           = $Directory.name;
					Username            = $null;
					Password            = $null;
					ApplianceConnection = $_appliance

				}

				if ($Directory.directoryBindingType -eq $LdapDirectoryAccountBindTypeEnum['SERVICEACCOUNT'])
				{

					"[{0}] Directory uses Service Account to bind." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_Params.Username = $Directory.credential.userName

				}

				elseif ($Directory.directoryBindingType -eq $LdapDirectoryAccountBindTypeEnum['USERACCOUNT'])
				{

					if ($PSBoundParameters['Credential'])
					{
	
						"[{0}] Using PSCredential object to provide directory auth credentials." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
						$_Params.Username = $Credential.Username
						$_Params.Password = $Credential.Password
	
					}
	
					elseif ($PSBoundParameters['Username'])
					{
	
						"[{0}] Providing user crednetials for directory auth." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
						$_Params.Username = $Username
						$_Params.Password = $Password
	
					}

					# User did not provide required authentication for directory. Throw error.
					else
					{
			
						$ExceptionMessage = 'Please provide valid credentials using either -Username/-Password or -Credential parameters.  The directory {0} is configured to require user authentication in order to bind to the authentication directory.' -f $Directory.name
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.LdapAuthenticationException NoValidCredentialParameters AuthenticationError "ApplianceConnection" -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
	
					}

				}				
				
                $_Groups = BuildGroupList @_Params
				
			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}    
 
	}

	End 
	{
	
		return $_Groups

	}

}
