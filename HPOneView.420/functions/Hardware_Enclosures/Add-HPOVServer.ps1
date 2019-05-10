function Add-HPOVServer 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Managed", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (ValueFromPipeline, Mandatory, ParameterSetName = "Monitored")]
		[Parameter (ValueFromPipeline, Mandatory, ParameterSetName = "Managed")]
		[ValidateNotNullOrEmpty()]
		[string]$Hostname,
		 
		[Parameter (Mandatory = $false, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[ValidateNotNullOrEmpty()]
		[string]$Username,

		[Parameter (Mandatory = $false, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[ValidateNotNullOrEmpty()]
		[Object]$Password,

		[Parameter (Mandatory = $false, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential,

		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[ValidateSet ("OneView", "OneViewNoiLO")]
		[string]$LicensingIntent = 'OneView',

		[Parameter (Mandatory, ParameterSetName = "Monitored")]
		[switch]$Monitored,

		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $false, ParameterSetName = "Monitored")]
		[ValidateNotNullOrEmpty()]
        [HPOneView.Appliance.ScopeCollection]$Scope,

		[Parameter (Mandatory = $False, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $False, ParameterSetName = "Managed")]
		[switch]$Async,

		[Parameter (Mandatory = $False, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $False, ParameterSetName = "Managed")]
		[ValidateNotNullorEmpty()]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

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

		if ($PSBoundParameters['Credential'])
		{

			$_Username = $Credential.Username
			$_Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

		}

		elseif ($PSBoundParameters['Username'])
		{

			Write-Warning "The -Username and -Password parameters are being deprecated.  Please transition your scripts to using the -Credential parameter."

			$_Username = $Username.clone()

			if (-not $PSBoundParameters['Password'])
			{

				$ExceptionMessage = "The -Username parameter requires the -Password parameter.  Or please use the -Credential parameter instead."
				$ErrorRecord = New-ErrorRecord HPOneView.Library.UnsupportedArgumentException MissingRequiredPasswordParameter InvalidOperation 'Password' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if ($Password -is [SecureString])
			{

				$_Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

			}

			else
			{

				$_Password = $Password.Clone()

			}

		}

		elseif (-not $PSBoundParameters['Credential'] -and -not $PSBoundParameters['Username'])
		{

			$ExceptionMessage = "This Cmdlet requires credentials to the target resource.  Please provide either the -Username and -Password, or -Credential parameters."
			$ErrorRecord = New-ErrorRecord HPOneView.Library.UnsupportedArgumentException MissingRequiredPasswordParameter InvalidOperation 'Authentication' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

	}

	Process 
	{

		# New Server Resource Object
		$_server = NewObject -ServerImport
		$_server.hostname        = $Hostname;
		$_server.username        = $_Username;
		$_server.password        = $_Password;
		$_server.licensingIntent = $LicensingIntent;        

		if ([bool]$Monitored) 
		{ 
		
			$_server.licensingIntent    = "OneViewStandard"
			$_server.configurationState = "Monitored"

		}

		else 
		{ 
			
			$_server.configurationState = "Managed" 
		
		}

		if ($PSBoundParameters['Scope'])
		{

			ForEach ($_Scope in $Scope)
			{

				"[{0}] Adding resource to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

				[void]$_server.initialScopeUris.Add($_Scope.Uri)

			}

		}

		"[{0}] Sending request to add server resource {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Hostname | Write-Verbose

		Try
		{
		
			$task = Send-HPOVRequest -Uri $ServerHardwareUri -Method POST -Body $_server -Hostname $ApplianceConnection.Name
		
		}
		
		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		"[{0}] Initial task response: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($resp | out-string) | Write-Verbose

		Try
		{
			
			$resp = Wait-HPOVTaskStart $task

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		"[{0}] Second task response: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($resp | out-string) | Write-Verbose

		# Check to see if the task errored, which should be in the Task Validation stage
		if ($resp.taskState -ne "Running") 
		{

			if (($resp.taskState -eq "Error") -and ($resp.stateReason -eq "ValidationError")) 
			{

				"[{0}] Task error found: {1}, {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $resp.taskState, $resp.stateReason | Write-Verbose
				
				# TaskErrors should contain only a single value, so we will force pick the first one.
				$errorMessage = $resp.taskerrors[0]
				
				switch ($errorMessage.errorCode) 
				{

					{$_ -match "SERVER_ALREADY_*" }
					{ 

						# Support different external manager process
						if ([Uri]::IsWellFormedUriString($errorMessage.data.managementUrl, [System.UriKind]::Absolute))
						{

							$externalManagerType = $errorMessage.data.managementProduct

							$externalManagerIP   = $errorMessage.data.managementUrl.Replace("https://","")

							Try
							{
							
								$externalManagerFQDN = [System.Net.DNS]::GetHostByAddress($externalManagerIP)
							
							}

							Catch
							{

								"[{0}] Unable to resolve IP Address to DNS A Record." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
								$externalManagerFQDN = [PSCustomObject]@{HostName = 'UnknownFqdn'; Aliases = @(); AddressList = @($externalManagerIP.Clone())}

							}
							
							"[{0}] Found server '{1}' is already being managed by {2} at {3}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Hostname, $externalManagerType, $externalManagerIP | Write-Verbose
							"[{0}] {1} resolves to {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $externalManagerIP,  $($externalManagerFQDN | out-string) | Write-Verbose

							write-warning ("Server '{0}' is already being managed by {1} at {2} ({3})." -f $hostname, $externalManagerType, $externalManagerIP,  $($externalManagerFQDN | out-string))

							if ($PSCmdlet.ShouldProcess($hostname,("force add server that is already managed/monitored by {0} at {1} ({2})" -f $externalManagerType, $externalManagerIP, $externalManagerFQDN.HostName))) 
							{
						
								"[{0}] Server was claimed and user chose YES to force add." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								$_server | Add-Member -NotePropertyName force -NotePropertyValue $true -force | out-null
								
								Try
								{

									$resp = Send-HPOVRequest -Uri $ServerHardwareUri -Method POST -BOdy $_server -Hostname $ApplianceConnection.Name

								}

								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}							

							}

							else 
							{

								if ($PSBoundParameters['whatif'].ispresent) 
								{ 
						
									write-warning "-WhatIf was passed, would have force added '$hostname' server to appliance."
									
									$resp = $null
						
								}

								else 
								{

									# If here, user chose "No", End Processing
									write-warning "Not importing server, $hostname."
									
									$resp = $Null

								}

							}

						}

						# Device is already added to appliance as Monitored or Managed resource
						else
						{

							$_EmbeddedJson = ([Regex]::Match($errorMessage.message, "\{.*\}")).value | ConvertFrom-Json

							if ($null -eq $_EmbeddedJson)
							{

								# Get the server hardware in $errorMessage.data.uri
								Try
								{

									$_Server = Send-HPOVRequest -Uri $errorMessage.data.uri -Hostname $ApplianceConnection

								}

								Catch
								{

									$PSCmdlet.ThrowTerminatingError($_)

								}

							}

							else
							{

								$_Server = $_EmbeddedJson

							}							

							# Throw exception that resource is already managed by the appliance as $Server.name
							"[{0}] Generating error: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($errorMessage.message) | Write-Verbose

							$ExceptionMessage = '"The server hardware has already been added as "{0}". {1}  If the server is orphaned, use Remove-HPOVServer -Force Cmdlet, and then try your add again.' -f $_Server.name, $errorMessage.recommEndedActions
							$ErrorRecord = New-ErrorRecord HPOneView.ServerHardwareResourceException ServerResourceExists ResourceExists 'Hostname' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}
					
					}

					"INVALID_ADDR" 
					{ 
					
						"[{0}] Generating error: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($errorMessage.message) | Write-Verbose
						$ExceptionMessage = '{0} {1}' -f $errorMessage.message, $errorMessage.recommEndedActions
						$ErrorRecord = New-ErrorRecord HPOneView.ServerHardwareResourceException ServerResourceNotFound ObjectNotFound 'Hostname' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
					}

				}
					
			}

		}

		if (-not($PSBoundParameters['Async']))
		{

			$resp | Wait-HPOVTaskComplete

		}

		else
		{

			$resp

		}		
	   
	}

	End 
	{
		
		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
