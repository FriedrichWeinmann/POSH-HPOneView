function Set-HPOVRemoteSupportDefaultSite
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default" )]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Alias ('a1')]
		[String]$AddressLine1,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Alias ('a2')]
		[String]$AddressLine2,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$City,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Province')]
		[String]$State,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$PostalCode,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$Country,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$TimeZone,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
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
			
					$ApplianceConnection[$c] = Test-HPOVAuth $_connection

				}

				Catch [HPOneview.Appliance.AuthSessionException] 
				{

					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError $_connection -Message $_.Exception.Message -InnerException $_.Exception
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

		$defaultSiteCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		ForEach($_Connection in $ApplianceConnection)
		{

			Try
			{

				$_DefaultSite = Send-HPOVRequest -uri $RemoteSupportDefaultSitesUri -Hostname $_Connection
				$_method      = 'PUT'
				$_uri         = $_DefaultSite.uri
				
				
			}

			Catch 
			{

				if ($_.FullyQualifiedErrorId -match 'ResourceNotFound')
				{

					$_method      = 'POST'
					$_uri         = $RemoteSupportDefaultSitesUri
					$_DefaultSite = NewObject -RemoteSupportSite

				}

				else
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}			

			}

			$_DefaultSite.streetAddress1 = $AddressLine1
			if ($PSBoundParameters['AddressLine2']) { $_DefaultSite.streetAddress2 = $AddressLine2 }
			$_DefaultSite.city           = $City 
			$_DefaultSite.provinceState  = $State
			$_DefaultSite.countryCode    = $Country
			if ($PSBoundParameters['PostalCode']) { $_DefaultSite.postalCode = $PostalCode }			
			$_DefaultSite.timeZone       = $TimeZone
		 
			Try
			{

				$_resp = Send-HPOVRequest -method $_method -uri $_uri -body $_defaultSite -Hostname $_Connection

			}

			Catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_resp.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.RemoteSupport.DefaultSite')

			$_resp

		}

	}

	End 
	{
		
		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
