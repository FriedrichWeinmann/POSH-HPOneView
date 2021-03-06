﻿function Get-HPOVApplianceNetworkConfig 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[Alias ("x", "export", 'exportFile')]
		[ValidateScript({Test-Path $_})]
		[String]$Location,
		
		[Parameter (Mandatory = $false)]
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

		$_ApplianceNetworkConfiguration = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{
		
			"[{0}] Processing Appliance Connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			Try
			{
			
				$_appliancenetconfig = Send-HPOVRequest -Uri $ApplianceNetworkConfigUri -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
		
		
			$_appliancenetconfig | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.ApplianceServerConfiguration") }
			$_appliancenetconfig.applianceNetworks | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.ApplianceServerConfiguration.ApplianceNetworks") }
		
			[void]$_ApplianceNetworkConfiguration.Add($_appliancenetconfig)

		}
	
	}

	End 
	{

		If ($PSBoundParameters['Location']) 
		{

			ForEach ($_ApplianceConfig in $_ApplianceNetworkConfiguration)
			{

				$_filename = "{0}_ApplianceNetConf.json" -f $_ApplianceConfig.ApplianceConnection.Name

				ForEach ($nic in $_ApplianceConfig.applianceNetworks) 
				{

					if ($nic.IPv4Type -eq "DHCP") { $nic.app1IPv4Addr = $null }

					if ($nic.IPv6Type -eq "DHCP") { $nic.app1IPv6Addr = $null }
				
				}

				$_ApplianceConfig = $_ApplianceConfig | Select-Object * -ExcludeProperty ApplianceConnection

				$_ApplianceConfig | convertto-json -depth 99 > ($Location + '\' + $_filename)

				Get-ChildItem ($Location + '\' + $_filename)

			}
			
		}
		
		Else 
		{
		
			Return $_ApplianceNetworkConfiguration

		}

	}

}
