function Connect-HPOVMgmt 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'UsernamePassword')]
	Param
	(

		[Parameter (Mandatory, ParameterSetName = 'UsernamePassword')]
		[Parameter (Mandatory, ParameterSetName = 'PSCredential')]
		[Parameter (Mandatory, ParameterSetName = 'Certificate')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance', 'Computername')]
		[string]$Hostname,

		[Parameter (Mandatory = $false, ParameterSetName = 'UsernamePassword')]
		[Parameter (Mandatory = $false, ParameterSetName = 'PSCredential')]
		[ValidateNotNullOrEmpty()]
		[Alias ('authProvider')]
		[string]$AuthLoginDomain = 'LOCAL',

		[Parameter (Mandatory, ParameterSetName = 'UsernamePassword')]
		[ValidateNotNullOrEmpty()]
		[Alias ("u",'user')]
		[string]$UserName,

		[Parameter (Mandatory = $false, ParameterSetName = 'UsernamePassword')]
		[Alias ("p")]
		[ValidateNotNullOrEmpty()]
		[Object]$Password,

		[Parameter (Mandatory, ParameterSetName = 'PSCredential')]
		[ValidateNotNullOrEmpty()]
		[Alias ('PSCredential')]
		[PSCredential]$Credential,

		[Parameter (Mandatory, ParameterSetName = 'Certificate')]
		[Object]$Certificate,

		[Parameter (Mandatory = $false, ParameterSetName = 'UsernamePassword')]
		[Parameter (Mandatory = $false, ParameterSetName = 'PSCredential')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Certificate')]
		[switch]$LoginAcknowledge 

	)

	Begin 
	{

		# Clone PSBoundParameters
		$_Params = @{}
		
		$PSBoundParameters.GetEnumerator() | ForEach-Object {

			if ($_.Key -eq 'Password')
			{

				$_Params['Password'] = '[*****REDACTED******]'

			}

			elseif ($_.Key -eq 'Certificate')
			{

				$_Params['Certificate'] = '[*****REDACTED******]'

			}

			else
			{

				$_Params.Add($_.Key,$_.Value)

			}			

		}

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_Params | out-string) | Write-Verbose
		
		# Check to see if a connection to the appliance exists
		if ((${Global:ConnectedSessions}.Name -contains $Hostname) -and ((${Global:ConnectedSessions} | Where-Object name -eq $Hostname).SessionID)) 
		{

			Write-Warning "You are already connected to $Hostname"
			continue
				
		}

		# Create the connection object for tracking
		else 
		{

			# Look for Connection where Name exists but SessionID does not, and remove the object from $ConnectedSessions
			if ((${Global:ConnectedSessions}.Name -contains $Hostname) -and (-not(${Global:ConnectedSessions} | Where-Object name -eq $Hostname).SessionID)) 
			{

				"[{0}] Found incomplete session object in `$ConnectedSessions for '{1}'. Removing." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Hostname | Write-Verbose

				# Found incomplete session connection. must remove it from the collection first.
				$_ndx = [array]::IndexOf(${Global:ConnectedSessions}, (${Global:ConnectedSessions}.Name -contains $Hostname))

				if ($_ndx -gt 0)
				{

					[void]${Global:ConnectedSessions}.RemoveAt($_ndx)

				}

				else
				{

					"[{0}] Index was {1}, connection doesn't exist in global tracker." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ndx | Write-Verbose

				}	
					
			}

			"[{0}] Creating Session Container" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$tmpConnectionId = 1

			# Figure out ConnectionId
			if (${Global:ConnectedSessions})
			{

				While (${Global:ConnectedSessions}.ConnectionId -contains $tmpConnectionId) 
				{

					$tmpConnectionId++

				}
			
			}

			# Store the entire auth request for later deletion when issuing Disconnect-HPOVmgmt
			[HPOneView.Appliance.Connection]$ApplianceConnection = New-Object HPOneView.Appliance.Connection($tmpConnectionId, 
																											$Hostname, 
																											$UserName)

			if (-not(${Global:ConnectedSessions} | Where-Object Default)) 
			{ 
				
				$ApplianceConnection.SetDefault($True)
			
			}

			[void]${Global:ConnectedSessions}.Add($ApplianceConnection)
			
		}

		if (-not($PSBoundParameters['Password']) -and $PSCmdlet.ParameterSetName -eq 'UsernamePassword')
		{

			[SecureString]$password = read-host -AsSecureString "Password"
			$decryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
			
		}

		elseif ($Password -is [SecureString] -and $PSCmdlet.ParameterSetName -eq 'UsernamePassword')
		{

			$decryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

		}

		elseif ($PSCmdlet.ParameterSetName -eq 'UsernamePassword')
		{

			$decryptPassword = $Password

		}

		elseif ($PSCmdlet.ParameterSetName -eq 'PSCredential')
		{

			$Username = $Credential.UserName
			$decryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

		}

		elseif ($PSCmdlet.ParameterSetName -ne 'Certificate')
		{

			$Credential = Get-Credential
			$Username = $Credential.UserName
			$decryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

		}

		# Check to make sure the appliance X-API-Version is at least the supported minimum
		"[{0}] Checking X-API Version." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
		try 
		{
			
			$applianceVersion = (Send-HPOVRequest -Uri $ApplianceXApiVersionUri -Hostname $Hostname).currentVersion

			if ($applianceVersion -and $applianceVersion -lt $MinXAPIVersion ) 
			{

				[void] $ConnectedSessions.RemoveConnection($ApplianceConnection)

				# Display terminating error
				$ErrorRecord = New-ErrorRecord System.NotImplementedException LibraryTooNew OperationStopped $Hostname -Message "The appliance you are connecting to supports an older version of this library.  Please visit https://github.com/HewlettPackard/POSH-HPOneView for a supported version of the library."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		catch 
		{

			"[{0}] Exception caught when checking X-API version." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			[void] $ConnectedSessions.RemoveConnection($ApplianceConnection)
			
			$PSCmdlet.ThrowTerminatingError($_)

		}

	}

	Process 
	{

		try 
		{

			"[{0}] Getting global login settings to check for login message acknowledgement." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_LoginDetails = Send-HPOVRequest -Uri $ApplianceLoginDomainDetails -Hostname $Hostname

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		# Build the parameters object depending on what type of credential passed

		$_Params = @{
			
			Uri      = $null;
			Method   = 'POST';
			Body     = $null;
			Hostname = $Hostname

		}
		
		# Username/Password or PSCredential auth
		if ($PSCmdlet.ParameterSetName -ne 'Certificate')
		{

			$_authinfo = NewObject -AuthLoginCredential
			
			$_authinfo.userName = $UserName
			$_authinfo.password = $decryptPassword

			if (-not $PSBoundParameters['AuthLoginDomain'])
			{
				
				$_authinfo.authLoginDomain = $_LoginDetails.defaultLoginDomain
				# (${Global:ConnectedSessions} | ? Name -EQ $Hostname).AuthLoginDomain = $_LoginDetails.defaultLoginDomain

			}

			else
			{
				
				$_authinfo.authLoginDomain = $AuthLoginDomain

			}

			$_Params.Uri = $ApplianceLoginSessionsUri

			$_Params.Body = $_authinfo

			if ($PSBoundParameters['LoginAcknowledge'])
			{
	
				$_Params.Body | Add-Member -NotePropertyName loginMsgAck -NotePropertyValue $True
	
			}

		}

		# Cert/SmartCard auth
		else
		{

			$_CertificateBase64Object = $Certificate

			$_Params.Uri  = $ApplianceLoginSessionsSmartCardAuthUri
			$_Params.Body = $_CertificateBase64Object

			if ($PSBoundParameters['LoginAcknowledge'])
			{
	
				[void] $_Params.Add('AddHeader', @{'X-LoginMsgAck' = $True})
	
			}

		}

		Try
		{

			if ($_LoginDetails.loginMessage.message)
			{

				Write-Host ("{0}`n" -f $_LoginDetails.loginMessage.message)

			}			
			
			# Send the auth request
			$resp = Send-HPOVRequest @_Params

		}

		catch [HPOneview.ResourceNotFoundException]
		{

			[void] $ConnectedSessions.RemoveConnection($ApplianceConnection)
			
			if ($PSCmdlet.ParameterSetName -eq 'Certificate')
			{

				$ExceptionMessage = "The appliance is not configured for 2-Factor authentication.  Please provide a valid username and password in order to authenticate to the appliance."
				$ErrorRecord = New-ErrorRecord HPOneview.ResourceNotFoundException TwoFactorAuthenticationNotEnabled PermissionDenied 'Certificate' -Message $ExceptionMessage

			}

			else
			{

				$ExceptionMessage = "The provided '{0}' authentication directory is not configured on the appliance '{1}'." -f $AuthLoginDomain, $Hostname
				$ErrorRecord = New-ErrorRecord HPOneview.ResourceNotFoundException AuthenticationDirectoryNotFound ObjectNotFound 'AuthLoginDomain' -Message $ExceptionMessage

			}

			
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		catch [HPOneView.Appliance.AuthSessionException] 
		{

			"[{0}] Authentication Exception Caught." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_ErrorId = $_.FullyQualifiedErrorId.Split(',')[0]

			$_ErrorRecord = $_

			switch ($_ErrorId)
			{

				'LoginMessageAcknowledgementRequired'
				{

					"[{0}] Login Message Acknowledgement Required" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# Get LoginMessage from appliance.
					Try
					{

						$caption = "Please Confirm";
						$message = "Do you acknowledge the login message?";
						$yes     = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Yes, I accept the login message.";
						$no      = New-Object System.Management.Automation.Host.ChoiceDescription "&No","No, I do not.";
						$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no);
						$answer  = $host.ui.PromptForChoice($caption,$message,$choices,1) 

						switch ($answer)
						{

							#YES
							0 
							{

								"[{0}] Submitting auth request again, with login message acknowledgement." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								if ($PSCMdlet.ParameterSetName -eq 'Certificate')
								{

									$_Params.AddHeader.Add('X-LoginMsgAck', $True)

								}

								else
								{

									$_Params.Body | Add-Member -NotePropertyName loginMsgAck -NotePropertyValue $True

								}

								Try
								{

									$resp = Send-HPOVRequest @_Params

								}

								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}

							}

							# NO
							1
							{

								"[{0}] User selected 'No'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								'You are not authenticated to {0}, as you chose not to accept the Login Message acknowledgement.' -f $Hostname | Write-Warning 

								# Remove Connection from global tracker
								[void] $ConnectedSessions.RemoveConnection($ApplianceConnection)

								Return

							}

						}   

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				'InvalidUsernameOrPassword'
				{

					# Remove Connection from global tracker
					[void] $ConnectedSessions.RemoveConnection($ApplianceConnection)

					$PSCmdlet.ThrowTerminatingError($_ErrorRecord)

				}

				default
				{

					# Remove Connection from global tracker
					[void] $ConnectedSessions.RemoveConnection($ApplianceConnection)

					#$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AuthSessionException $_ErrorId InvalidResult 'Connect-HPOVMgmt' -Message $_.Exception.Message 
					$PSCmdlet.ThrowTerminatingError($_ErrorRecord)

				}

			}           

		}

		catch [HPOneview.Appliance.PasswordChangeRequired] 
		{

			"[{0}] Password needs to be changed. Use Set-HPOVInitialPassword if this is first time setup, or Set-HPOVUserPassword to update your own accounts password." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			[void] $ConnectedSessions.RemoveConnection($ApplianceConnection)

			# Throw terminating error
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.PasswordChangeRequired PasswordExpired PermissionDenied 'Username' -Message "The password has expired and needs to be updated. Use Set-HPOVInitialPassword if this is first time setup, or Set-HPOVUserPassword to update your own accounts password."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)   
		
		}
			
		catch [Net.WebException] 
		{

			"[{0}] Response: $($resp)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			[void] $ConnectedSessions.RemoveConnection($ApplianceConnection)

			$ErrorRecord = New-ErrorRecord System.Net.WebException ApplianceNotResponding OperationStopped $Hostname -Message "The appliance at $Hostname is not responding on the network.  Check for firewalls or ACL's prohibiting access to the appliance."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Something bad happened, should not leave connection in this state
		catch
		{

			[void] $ConnectedSessions.RemoveConnection($ApplianceConnection)

			$PSCmdlet.ThrowTerminatingError($_)

		}

    }	

	End 
	{

		"[{0}] Authentication Response Received. Processing final connection object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# If a sessionID is returned, then the user has authenticated
		if ($resp.sessionId) 
		{

			$_RedactedResp = $resp.PSObject.Copy()

			$_RedactedResp.SessionId = '[*****REDACTED******]'

			$_Index = ${Global:ConnectedSessions}.IndexOf((${Global:ConnectedSessions} | Where-Object Name -EQ $Hostname))

			${Global:ConnectedSessions}[$_Index].SetSessionID($resp.sessionId)
			
			"[{0}] Session received: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $($_RedactedResp | Out-String) | Write-Verbose

			if ($PSCmdlet.ParameterSetName -eq 'Certificate')
			{

				$_AuthType = 'Certificate'
				$_UserName = $resp.userName
				$_AuthLoginDomain = $resp.authLoginDomain

			}

			else
			{

				$_AuthType = 'Credentials'
				$_Username = $Username
				$_AuthLoginDomain = $AuthLoginDomain

			}

			# Get list of supported Roles from the appliance
			"[{0}] Getting list of supported roles from appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_ApplianceSecurityRoles = $null

			try 
			{ 
				
				$_ApplianceSecurityRoles = (Send-HPOVRequest $ApplianceRolesUri -Hostname $Hostname).members.roleName
			
			}

			catch [HPOneview.Appliance.AuthPrivilegeException] 
			{ 
				
				"[{0}] User is not authorizaed to get list of security groups." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			}

			catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			"[{0}] Get appliance platform type." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Get Appliance Type to track what Cmdlet features are available
			# try 
			# { 
				
			# 	$ApplianceType = (Send-HPOVRequest $ApplianceVersionUri -Hostname $Hostname).platformType
			
			# }

			# catch
			# { 
				
			# 	$PSCmdlet.ThrowTerminatingError($_)
			
			# }

			$_applianceversioninfo = NewObject -ApplianceVersion
			
			Try
			{

				$applVersionInfo = Send-HPOVRequest -Uri $ApplianceVersionUri -Hostname $Hostname

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			Try
			{

				$_applianceversioninfo = New-Object HPOneView.Appliance.NodeInfo ($applVersionInfo.softwareVersion, (Get-HPOVXApiVersion -ApplianceConnection $Hostname).currentVersion, $applVersionInfo.modelNumber)
				
				$PSLibraryVersion | Add-Member -NotePropertyName $Hostname -NotePropertyValue $_applianceversioninfo -Force

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			"[{0}] Get users available Scopes and Permissions." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_UserDefaultSession = Send-HPOVRequest -Uri $UserLoginSessionUri -Hostname $Hostname -AddHeader @{'Session-ID' = $resp.sessionId}

				$_UserDefaultSessionPermissions = New-Object System.Collections.ArrayList

				ForEach ($_Permission in $_UserDefaultSession.permissions)
				{

					"[{0}] Adding {1} into permissions collection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Permission.roleName | Write-Verbose

					$_Scope = $null

					if (-not [String]::IsNullOrWhiteSpace($_Permission.scopeUri))
					{

						$_Scope = Send-HPOVRequest -Uri $_Permission.scopeUri -Hostname $Hostname

					}				

					$_NewPermission = New-Object HPOneView.Appliance.ConnectionPermission ($_Permission.roleName, 
																						   $_Scope.Name, 
																						   $_Permission.scopeUri, 
																						   $_Permission.active)

					[void]$_UserDefaultSessionPermissions.Add($_NewPermission)

				}

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# Recreate the full appliance connection
			$_NewConnection = New-Object HPOneView.Appliance.Connection($ConnectedSessions[$_Index].ConnectionID,
																		$ConnectedSessions[$_Index].Name,
																		$_Username,
																		$resp.sessionId,
																		$_AuthLoginDomain,
																		$_AuthType,
																		$AppliancePlatformType[$applVersionInfo.platformType],
																		$ConnectedSessions[$_Index].Default,
																		[Array]$_ApplianceSecurityRoles,
																		[Array]$_UserDefaultSessionPermissions)
			
			${Global:ConnectedSessions}[$_Index] = $_NewConnection

			# $Validator.AddTrustedHost($_NewConnection.Name)
			[HPOneView.PKI.SslValidation]::AddTrustedHost($_NewConnection.Name)

			Return $_NewConnection

		}

		else 
		{ 
							  
			Return $resp 

		}

	}

}
