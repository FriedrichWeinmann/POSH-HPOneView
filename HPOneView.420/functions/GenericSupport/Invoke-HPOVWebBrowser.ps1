function Invoke-HPOVWebBrowser
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]

	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateSet ("Dashboard",
					  "Settings", 
					  "ServerProfiles", 
					  "ServerProfileTemplates", 
					  "ServerHardware", 
					  "Enclosures", 
					  "RackManagers", 
					  "LogicalEnclosures", 
					  "Networks", 
					  "LogicalInterconnects", 
					  "LogicaInterconnectGroups", 
					  "StorageSystems", 
					  "StoragePools", 
					  "StorageVolumes")]
		[String]$Resource = "Dashboard",

		[Parameter (Mandatory = $false)]
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

		$_ApplianceStatus = New-Object System.Collections.ArrayList

	}

	Process
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			$_ResourceMap = @{
				Dashboard                = 'dashboard';
				Settings                 = 'settings/show/overview';
				ServerProfiles           = 'profiles';
				ServerProfileTemplates   = 'profile-templates';
				ServerHardware           = 'server-hardware';
				Enclosures               = 'enclosures';
				RackManagers             = 'rackmanagers';
				LogicalEnclosures        = 'logicalenclosures';
				Networks                 = 'network';
				LogicalInterconnects     = 'logicalswitch';
				LogicaInterconnectGroups = 'switchtemplate';
				StorageSystems           = 'storage-systems';
				StoragePools             = 'storage-pools';
				StorageVolumes           = 'storage-volumes'
			}

			Start-Process ("https://{0}/#/{1}?s_sid={2}" -f $_appliance.Name, $_ResourceMap.$Resource, $_appliance.SessionID)

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
