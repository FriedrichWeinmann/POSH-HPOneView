function Get-HPOVVersion 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[switch]$ApplianceVer,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'CheckOnlineOnly')]
		[switch]$CheckOnline,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Alias ('appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)
	
	Begin 
	{	
		
		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if  ($ApplianceConnection.Count -eq 0 -and (-not($PSBoundParameters['CheckOnline'])) -and $PSBoundParameters['ApplianceVer'])
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoAuthSessionFound InvalidArgument 'ApplianceConnection' -Message 'No ApplianceConnections were found.  Please use Connect-HPOVMgmt to establish an appliance connection.'
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif ($PSBoundParameters['ApplianceVer'])
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

		$_ApplianceVersionCollection = New-Object System.Collections.ArrayList
	
	}
	
	Process 
	{

		if ($PSboundParameters['CheckOnline']) 
		{

			try 
			{ 

				"[{0}] Testing for Proxy settings" -f  $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[Uri]$_ProxyUri = $null

				$_Options = @{Uri = $Repository}

				$_Proxy = [System.Net.WebRequest]::GetSystemWebProxy()

				$_Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
				$_ProxyUri = $_Proxy.GetProxy($_Options.Uri)

				if ($_ProxyUri.OriginalString -ne $_Options.Uri)
				{

					$_Options.Add('Proxy',$_proxyUri)
					$_Options.Add('ProxyUseDefaultCredentials', $true)
					
				}

				$_OriginalProgressPreference = $ProgressPreference
				
				# Hide the display of Write-Progress Invoke-RestMethod displays
				$ProgressPreference = 'silentlyContinue'

				"[{0}] Invoke-RestMethod Options: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_Options | Out-String) | Write-Verbose
				
				$resp = Invoke-RestMethod @_Options

				$ProgressPreference = $_OriginalProgressPreference

				$versionMajorMinor = "{0}.{1}" -f $PSLibraryVersion.Major, $PSLibraryVersion.Minor

				# Filter for versions that match Major and Minor release, and exclude the HP VCM to OneView Migration Tool
				$matchedVersions = $resp | Where-Object { $_.tag_name -like "v$versionMajorMinor*" -and (-not($_.tag_name.startswith('HPVCtoOV'))) -and (-not($_.tag_name.startswith('HPSIMtoOV'))) } 

				"[{0}] Found versions online: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [System.String]::Join(' ,', $resp.tag_name) | Write-Verbose

				$newerVersion = $false

				# Compare the releases
				$matchedVersions | ForEach-Object { 
	
					if ($newerVersion) 
					{ 
						
						Write-Verbose "Found previous version to compare: $newerVersion" 
					
					}

					[version]$version = $_.tag_name -replace "v","" 

					"[{0}] Comparing {1} to {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $version, $PSLibraryVersion.LibraryVersion | Write-Verbose
		
					# Compare found version with library
					if (-not($newerVersion) -and $version.build -gt $PSLibraryVersion.LibraryVersion.build) 
					{
			
						[version]$newerVersion = $version
						$newerVersionObj = $_

						"[{0}] Newer version found:  {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $newerVersion | Write-Verbose

					}

					elseif ($newerVersion.Build -lt $version.Build -and $version.build -gt $PSLibraryVersion.LibraryVersion.build) 
					{

						[version]$newerVersion = $version
						$newerVersionObj = $_

						"[{0}] Newer version found:  {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $newerVersion | Write-Verbose

					}
	
				}

				if ($newerVersion) 
				{ 

					"[{0}] Found: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [string]$version | Write-Verbose

					$PSLibraryVersion | Add-Member -NotePropertyName UpdateAvailable -NotePropertyValue $True

					if ($ReleaseNotes) { $newerVersionObj.body -replace "## ","" -replace "\*","  ? " }

					$caption = "Please Confirm";
					$message = "You currently have v{0} installed.  The HP OneView PowerShell Library v{1} was found that is newer.  Do you want to download the current version of the HP OneView POSH Library (will open your web browser for you to download)?" -f $PSLibraryVersion.LibraryVersion, [string]$newerVersion
					$yes     = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Open your browser to download latest HP OneView POSH Library version.";
					$no      = New-Object System.Management.Automation.Host.ChoiceDescription "&No","No, you will do this later.";
					$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no);
					$answer  = $host.ui.PromptForChoice($caption,$message,$choices,0) 

					switch ($answer)
					{

						0 
						{

							"[{0}] Launching users browser to '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $newerVersionObj.html_url | Write-Verbose
							
							Start-Process "$($newerVersionObj.html_url)"
		
						}

					}     
	
				}

				else 
				{ 
				
					$PSLibraryVersion | Add-Member -NotePropertyName UpdateAvailable -NotePropertyValue $False

					"[{0}] Library is already up-to-date." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
				}

				$PSLibraryVersion

			}

			catch 
			{

				$errorMessage = "$($_[0].exception.message). $($_[0].exception.InnerException.message)"
				$ErrorRecord = New-ErrorRecord HPOneView.Library.UpdateConnectionError InvalidResult ConnectionError 'CheckOnline' -TargetType 'Switch' -Message "$($_[0].exception.message)." -InnerException $_.exception.InnerException
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else
		{

			$PSLibraryVersion

		}

	}

	end
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
