function Get-HPOVLdapDirectory 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName='Default')]
		[Alias ('directory','domain')]
		[String]$Name,

		[Parameter (Mandatory, ParameterSetName = 'Export')]
		[Alias ('x')]
		[ValidateScript({split-path $_ | Test-Path})]
		[string]$Export,

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

		$_AuthDirectorySettings = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{
		
			$Found = New-Object System.Collections.ArrayList

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Try
			{

				$_AuthDirectories = Send-HPOVRequest -uri $AuthnProvidersUri -Hostname $_appliance.Name

				If ($PSBoundParameters['Name']) 
				{

					$_AuthDirectories.members = $_AuthDirectories.members | Where-Object name -like $Name

				}
			
				if ($_AuthDirectories.members)
				{

					$_AuthDirectories.members | ForEach-Object {

						$_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AuthDirectory") 
					
						[void]$Found.Add($_)

					}

				}				

				if ($Found.Count -eq 0 -and $PSBoundParameters['Name'])
				{
					
					$ExceptionMessage = "The specified '{0}' Authentication Directory resource not found on Appliance '{1}'.  Please check the name and try again." -f $Name, $_appliance.Name
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.LdapDirectoryException AuthDirectoryResourceNotFound ObjectNotFound "Name" -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)

				}

				$Found | ForEach-Object {

					$_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AuthDirectory") 
				
					[void]$_AuthDirectorySettings.Add($_)

				}

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

	}

	End 
	{	
	
		# Export directory settings (raw JSON) to file
		if ($PSboundParameters['export'])
		{

			# Loop through each directory and get all configured settings
			ForEach ($_directory in $_AuthDirectorySettings)
			{

				"[{0}] Exporting Directory $($_directory.name) configuration." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_SaveLocation = $Export + "\" + $_directory.ApplianceConnection.Name + "_" + $_directory.name + ".json"

				"[{0}] Saving to: $_SaveLocation" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				$_directory                 | Select-Object * -ExcludeProperty credential,created,modified,eTag 			
				$_directory.directoryServers | Select-Object * -ExcludeProperty directoryServerCertificateStatus,serverStatus,created,modified,eTag
				$_directory                 | convertto-json > $_SaveLocation
			
			}
		
		}
		
		else
		{
			
			Return $_AuthDirectorySettings

		}

	}

}
