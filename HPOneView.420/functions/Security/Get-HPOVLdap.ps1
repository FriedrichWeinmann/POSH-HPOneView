function Get-HPOVLdap 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName='Default')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Export')]
		[Alias ('x')]
		[switch]$Export,

		[Parameter (Mandatory, ParameterSetName = 'Export')]
		[Alias ('location')]
		[ValidateScript ({split-path $_ | Test-Path})]
		[string]$Save,
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Export')]
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

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Try
			{

				$_AuthDirectoryGlobalSettings = Send-HPOVRequest $authnSettingsUri -Hostname $_appliance.Name
				
				$_AuthDirectoryGlobalSettings | ForEach-Object { $_.psobject.typenames.Insert(0,"HPOneView.Appliance.AuthGlobalDirectoryConfiguration") }

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			[void]$_GlobalAuthDirectorySettings.Add($_AuthDirectoryGlobalSettings)

		}
		
	}

	End 
	{

		if ($PSBoundParameters['export'])
		{

			"[{0}] Exporting Global Directory configuration." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			ForEach ($_Directory in $_GlobalAuthDirectorySettings)
			{

				"[{0}] Saving to: $($save)\$($_Directory.ApplianceConnection.Name)_globalSettings.json" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				ConvertTo-Json $_Directory > $save\$($_Directory.ApplianceConnection.Name)_globalSettings.json

			}		

		}

		else
		{
 			
			Return $_GlobalAuthDirectorySettings 

		}

	}

}
