function Get-HPOVIloSso
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

    [CmdletBinding (DefaultParameterSetName = "Default")]
    Param 
	(

        [Parameter (ValueFromPipeline, Mandatory, ParameterSetName = 'Default')]
        [Parameter (ValueFromPipeline, Mandatory, ParameterSetName = 'IloRestSession')]
        [ValidateNotNullOrEmpty()]
		[Alias('Server')]
        [Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Switch]$RemoteConsoleOnly,		

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'IloRestSession')]
		[Switch]$IloRestSession,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "IloRestSession")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

    )

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

        "[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $PSBoundParameters['InputObject'])
		{

			$PipelineInput = $true

		}

		else
		{

			"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if (-not($ApplianceConnection) -and -not(${Global:ConnectedSessions}))
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if (-not($InputObject -is [PSCustomObject]) -or (-not($InputObject.ApplianceConnection)))
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException InvalidApplianceConnectionDataType InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "The specified 'InputObject' is not an object or is missing the 'ApplianceConnection' property.  Please correct this value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			else
			{

				Try 
				{
	
					$ApplianceConnection = Test-HPOVAuth $ApplianceConnection

				}

				Catch [HPOneview.Appliance.AuthSessionException] 
				{

					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError 'ApplianceConnection' -TargetType $InputObject.ApplianceConnection.GetType().Name -Message $_.Exception.Message -InnerException $_.Exception
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				Catch 
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

		}

		$colStatus = New-Object System.Collections.ArrayList

    }

    Process 
	{

		if (-not($PipelineInput) -and (-not($InputObject -is [PSCustomObject])))
		{

			$ExceptionMessage = "The specified 'InputObject' is not an object.  Please correct this value and try again."
			$ErrorRecord = New-ErrorRecord HPOneview.ServerResourceException InvalidServerObject InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ('server-hardware',$ResourceCategoryEnum.ServerProfile  -notcontains $InputObject.category)
		{
			
			$ExceptionMessage = "The specified 'InputObject' is not a Server or Server Profile object.  Please correct this value and try again."
			$ErrorRecord = New-ErrorRecord HPOneview.ServerResourceException InvalidObject InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($InputObject.category -eq $ResourceCategoryEnum.ServerProfile )
		{

			"[{0}] Server Profile was provided." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
			$_uri = $InputObject.serverHardwareUri

			# get server hardware from resource
			try
			{

				$_Server = Send-HPOVRequest -Uri $_uri -Hostname $InputObject.ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		else
		{

			"[{0}] Server Hardware was provided." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose
			$_uri = $InputObject.uri

			$_Server = $InputObject

		}

		if ($PSBoundParameters['RemoteConsoleOnly'])
		{

			$_uri = $_uri + '/remoteConsoleUrl'

		}

		else
		{

			$_uri = $_uri + '/iloSsoUrl'

		}		

        "[{0}] Processing {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

		Try
		{
		
			$_ssoresp = Send-HPOVRequest -URI $_uri -Hostname $InputObject.ApplianceConnection.Name
		
		}
        
		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not $PSBoundParameters['IloRestSession'])
		{

			"[{0}] Returning iLO SSO Session" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_ssoresp

		}

		else
		{

			"[{0}] Generating and returning iLO REST/RedFish SSO Session object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$CookieContainer = New-Object System.Net.CookieContainer
				
				[System.Net.HttpWebRequest]$WebRequest          = [System.Net.HttpWebRequest]::Create($_ssoresp.iloSsoUrl)
				$WebRequest.CookieContainer                     = $CookieContainer
				$WebRequest.Accept                              = 'application/json, *.*'
				$WebRequest.ServerCertificateValidationCallback = { $True }
				
				"[{0}] Getting Redfish SessionID token from iLO, {1}." -f $MyInvocation.InvocationName.ToString().ToUpper(), ([URI]$_ssoresp.iloSsoUrl).Host | Write-Verbose

				$Response = $WebRequest.GetResponse()
				$Response.Close()
				$Response.Dispose()

				"[{0}] Getting Redfish SessionID token from cookies." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				$SessionID = $CookieContainer.GetCookieHeader($_ssoresp.iloSsoUrl)

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			"[{0}] Building iLO Session Object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			switch ($_Server.mpModel)
			{

				'iLO5'
				{

					$_RootUri = "https://{0}/redfish/v1" -f ([URI]$_ssoresp.iloSsoUrl).Host

				}

				'iLO4'
				{

					$_RootUri = "https://{0}/rest/v1" -f ([URI]$_ssoresp.iloSsoUrl).Host

				}

			}

			$IloSession                = NewObject -IloRestSession
			$IloSession.RootUri        = $_RootUri
			$IloSession.'X-Auth-Token' = $SessionID.Replace('sessionKey=',$null)

			$IloSession

		}
       
    }

    End 
	{
        
        "[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

    }

}
