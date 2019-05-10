function Update-HPOVRackManager
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(
	
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'RefreshWithCredentials')]
		[ValidateNotNullOrEmpty()]
		[Alias ("name",'Server')]
		[HPOneView.Servers.RackManager[]]$InputObject,

		[Parameter (Mandatory, ParameterSetName = "RefreshWithCredentials")]
		[String]$Hostname,

		[Parameter (Mandatory, ParameterSetName = "RefreshWithCredentials")]
		[PSCredential]$Credential,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'RefreshWithCredentials')]
		[Switch]$Force,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'RefreshWithCredentials')]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'DefRefreshWithCredentialsault')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject']))
		{

			"[{0}] Server object provided by pipeline." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$PipelineInput = $True

		}

		else
		{

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

	}
	
	Process 
	{

		"[{0}] Rackmanager: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.Name, $InputObject.Uri | Write-Verbose

		"[{0}] Rackmanager State: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.State | Write-Verbose 
		"[{0}] Rackmanager Status: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.Status | Write-Verbose 

		$_body = @{
			op       = "RefreshRackManagerOp";
			isforce  = $Force.IsPresent;
			hostname = $null;
			username = $null;
			password = $null;
		}
	
		if ($InputObject.State -ieq 'Unmanaged' -and $InputObject.refreshState -ieq 'RefreshFailed')
		{

			if (-not $PSBoundParameters['Credential'])
			{

				$ExceptionMessage = "The appliance can no longer communicate with '{0}' resource, and requires valid Credentials." -f $InputObject.name
				$ErrorRecord = New-ErrorRecord HPOneView.Library.UnsupportedArgumentException MissingRequiredUsernameParameter InvalidOperation 'Credential' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if (-not $PSBoundParameters['Hostname'])
			{

				$ExceptionMessage = "The appliance can no longer communicate with '{0}' resource, and requires a Hostname/IPAddress." -f $InputObject.name
				$ErrorRecord = New-ErrorRecord HPOneView.Library.UnsupportedArgumentException MissingRequiredHostnameParameter InvalidOperation 'Hostname' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			$_body.hostname = $Hostname
			$_body.username = $Credential.Username
			$_body.password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

		}
		
		Try
		{

			$_resp = Send-HPOVRequest -Uri $InputObject.Uri -Method PATCH -Body $_body -Hostname $InputObject.ApplianceConnection -AddHeader @{'If-Match' = $InputObject.ETag}
		
		}
		
		Catch
		{
		
			$PSCmdlet.ThrowTerminatingError($_)
		
		}

		if ($PSBoundParameters['Async'])
		{

			$_resp

		}

		else
		{

			$_resp | Wait-HPOVTaskComplete

		}
	
	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
