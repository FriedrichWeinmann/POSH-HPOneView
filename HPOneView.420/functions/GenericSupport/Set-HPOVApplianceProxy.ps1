function Set-HPOVApplianceProxy
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'Authentication')]
		[ValidateNotNullorEmpty()]
		[String]$Hostname,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'Authentication')]
		[ValidateNotNullorEmpty()]
		[int]$Port,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Authentication')]
		[ValidateNotNullorEmpty()]
		[switch]$Https,

		[Parameter (Mandatory, ParameterSetName = 'Authentication')]
		[ValidateNotNullorEmpty()]
		[String]$Username,

		[Parameter (Mandatory, ParameterSetName = 'Authentication')]
		[ValidateNotNullorEmpty()]
		[SecureString]$Password,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Authentication')]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Authentication')]
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

	}

	Process
	{

		$_ApplianceProxyConfig = NewObject -ApplianceProxy
		$_ApplianceProxyConfig.server   = $Hostname
		$_ApplianceProxyConfig.port     = $Port
		
		if ($PSCmdlet.ParameterSetName -eq 'Authentication')
		{
			
			$_ApplianceProxyConfig.username = $Username
			$_ApplianceProxyConfig.password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
		
		}

		ForEach ($_appliance in $ApplianceConnection)
		{

			'[{0}] Processing "{1}" appliance connection.' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			if ($Https)
			{

				'[{0}] Setting Proxy to HTTPS.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_ApplianceProxyConfig.communicationProtocol = 'HTTPS'

				'[{0}] Getting HTTPS certificate from endpoint.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_Uri = '{0}/{1}' -f $RetrieveHttpsCertRemoteUri, $Hostname

				Try
				{

                    $_resp = Send-HPOVRequest -Uri $_Uri Hostname $_appliance
					
				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			Try
			{

				$_resp = Send-HPOVRequest -uri $ApplianceProxyConfigUri -Method POST -Body $_ApplianceProxyConfig -Hostname $_appliance

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

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
