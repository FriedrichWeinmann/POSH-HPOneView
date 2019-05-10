function Update-HPOVApplianceTrustedAuthorityCrl
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	# [OutputType([System.Collections.Generic.List[HPOneView.Appliance.SecurityProtocol]], ParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'FilePath')]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.TrustedCertificateAuthority[]]$InputObject,

		[Parameter (Mandatory, ParameterSetName = 'FilePath')]
		[System.IO.FileInfo]$Path,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'FilePath')]
		[switch]$Async,
	
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = 'FilePath')]
		[ValidateNotNullOrEmpty()]
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

		$_GlobalAuthDirectorySettings = New-Object System.Collections.ArrayList
		
	}

	Process
	{

		if (-not $PSBoundParameters['Path'])
		{

			try 
			{ 

				"[{0}] Testing for Proxy settings" -f  $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[Uri]$_ProxyUri = $null

				$_Options = @{Uri = $InputObject.CRLInfo.EndPointList[0]}

				$_filename = Split-Path $InputObject.CRLInfo.EndPointList[0] -Leaf

				$_Proxy = [System.Net.WebRequest]::GetSystemWebProxy()

				$_Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

				$_ProxyUri = $_Proxy.GetProxy($_Options.Uri)

				if ($_ProxyUri.OriginalString -ne $_Options.Uri)
				{

					"[{0}] Using proxy settings" -f  $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_Options.Add('Proxy',$_proxyUri)
					$_Options.Add('ProxyUseDefaultCredentials', $true)
					
				}

				"[{0}] Invoke-WebRequest Options: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_Options | Out-String) | Write-Verbose
				
				Invoke-WebRequest @_Options -OutFile "$env:TEMP\$_filename"	
				
				[System.IO.FileInfo]$Path = "$env:TEMP\$_filename"	

			}

			catch 
			{

				$errorMessage = "$($_[0].exception.message). $($_[0].exception.InnerException.message)"
				$ErrorRecord = New-ErrorRecord HPOneView.Library.UpdateConnectionError InvalidResult ConnectionError 'CheckOnline' -TargetType 'Switch' -Message "$($_[0].exception.message)." -InnerException $_.exception.InnerException
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		Try
		{

			$_Uri = '{0}/crl' -f $InputObject.Uri

			Upload-File -Uri $_Uri -Method PUT -File $Path | Wait-HPOVTaskComplete

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}
	
}
