function Get-HPOVStorageSystem 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Name")]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "Name")]
		[ValidateNotNullOrEmpty()]
		[Alias ('SystemName')]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Name")]
		[ValidateNotNullOrEmpty()]
		[string]$Hostname,

		[Parameter (Mandatory = $false, ParameterSetName = "Serial")]
		[ValidateNotNullOrEmpty()]
		[Alias ('SN')]
		[string]$SerialNumber,

		[Parameter (Mandatory = $false, ParameterSetName = "Name")]
		[Parameter (Mandatory = $false, ParameterSetName = "Serial")]
		[ValidateSet ('StoreVirtual', 'StoreServ')]
		[string]$Family,

		[Parameter (Mandatory = $false, ParameterSetName = "Name")]
		[Parameter (Mandatory = $false, ParameterSetName = "Serial")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false, ParameterSetName = "Name")]
		[Parameter (Mandatory = $false, ParameterSetName = "Serial")]
		[Alias ('Report')]
		[switch]$List

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

		if ($PSBoundParameters['List'])
		{

			Write-Warning "The -List parameter has been deprecated."

		}

		$_StorageSystemCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			$uri = $StorageSystemsUri + '?sort:asc'

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			if ($Name)
			{ 

				"[{0}] Filtering for Name property" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_method = 'eq'

				if ($Name.Contains('*'))
				{

					$Name = $Name.Replace("*","%25").Replace("&","%26") 

					$_method = 'matches'

				}
				
				
				$uri += "&filter=name {0} '{1}'" -f $_method, $Name
						
			}

			elseif ($Hostname)
			{

				"[{0}] Filtering for Hostname property" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_method = 'eq'

				if ($Hostname.Contains('*'))
				{

					$Hostname = $Hostname.Replace("*","%25").Replace("&","%26") 

					$_method = 'matches'

				}

				$uri += "&filter=hostname {0} '{1}'" -f $_method, $Hostname

			}

			if ($Family)
			{

				$uri += "&filter=family EQ '{0}'" -f $Family

			}

			"[{0}] Getting list of Storage Systems" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_StorageSystems = Send-HPOVRequest -Uri $uri -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($SerialNumber)
			{

				[Array]$_StorageSystems.members = $_StorageSystems.members | Where-Object { $_.deviceSpecificAttributes.serialNumber -eq $SerialNumber }

			}

			# Generate Terminating Error if resource not found
			if (-not($_StorageSystems.members.Count -gt 0) -and ($Name -or $SerialNumber -or $Hostname)) 
			{
				
				if ($Name) 
				{ 
					
					"[{0}] Woops! No '$Name' Storage System found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					$ExceptionMessage = "No Storage System with '{0}' system name found.  Please check the name or use Add-HPOVStorageSystem to add the Storage System." -f $Name
						
					$ErrorRecord = New-ErrorRecord HPOneView.StorageSystemResourceException StorageSystemResourceNotFound ObjectNotFound 'Name' -Message $ExceptionMessage

				}

				elseif ($Hostname) 
				{ 
					
					"[{0}] Woops! No '$Hostname' Storage System found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					$ExceptionMessage = "No Storage System with '{0}' system name found.  Please check the name or use Add-HPOVStorageSystem to add the Storage System." -f $Hostname
						
					$ErrorRecord = New-ErrorRecord HPOneView.StorageSystemResourceException StorageSystemResourceNotFound ObjectNotFound 'Hostname' -Message $ExceptionMessage

				}

				elseif ($SerialNumber) 
				{ 
					
					"[{0}] Woops! No Storage System with '$SerialNumber' serial number found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					$ExceptionMessage = "No Storage System with '{0}' serial number found.  Please check the name or use Add-HPOVStorageSystem to add the Storage System." -f $SerialNumber
					$ErrorRecord = New-ErrorRecord HPOneView.StorageSystemResourceException StorageSystemResourceNotFound ObjectNotFound 'SerialNumber' -Message $ExceptionMessage

				}
					
				# Generate Terminating Error
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				$_StorageSystems.members | ForEach-Object {

					$_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.System')

					if ($_.ports)
					{

						$_.ports | ForEach-Object { 
							
							# This is temporary
							Add-Member -InputObject $_ -NotePropertyName ApplianceConnection -NotePropertyValue $_.ApplianceConnection

							$_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.System.Port') 

						}

					}

					if ($_.deviceSpecificAttributes.discoverdPools) { $_.deviceSpecificAttributes.discoverdPools | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.System.Pool')} }
					if ($_.deviceSpecificAttributes.managedPools) { $_.deviceSpecificAttributes.managedPools | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'HPOneView.Storage.System.Pool')} }

					$_

				}	

			}	

		}
		 
	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
