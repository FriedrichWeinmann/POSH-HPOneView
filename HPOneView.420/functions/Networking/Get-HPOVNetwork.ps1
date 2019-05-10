function Get-HPOVNetwork 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (ParameterSetName = 'Default', ValueFromPipeline, Mandatory = $false)]
		[ValidateNotNullOrEmpty ()]
		[SupportsWildcards ()]
		[String]$Name,
		
		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateSet ("Ethernet", "FC", "FibreChannel", "FCOE")]
		[String]$Type,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateSet ("General", "Management", "VMMigration", "FaultTolerance", "ISCSI")]
		[String]$Purpose,

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty ()]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty ()]
		[String]$Label,
		
		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),
		
		[Parameter (ParameterSetName = 'Default', Mandatory = $false)]
		[Alias ("x", "export")]
		[ValidateScript ({split-path $_ | Test-Path})]
		[String]$exportFile
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['type']))
		{

			"[{0}] -Type Parameter wasn't provided. Specifying all Network Resource Types." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			[Array]$Type = "Ethernet","FibreChannel","FCOE"

		}

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

		$NetworkCollection = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			if ($PSBoundParameters['Purpose'])
			{

				$Type = 'Ethernet'

			}

			$Found = New-Object System.Collections.ArrayList

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			# Build the category to search for
			$_Category = New-Object System.Text.StringBuilder

			switch ($Type)
			{

				"Ethernet" 
				{ 
					
					[void]$_Category.Append('category=ethernet-networks&')
				
				}
				
				"FibreChannel" 
				{ 
					
					[void]$_Category.Append('category=fc-networks&')
				
				}
				
				"FCOE" 
				{ 
					
					[void]$_Category.Append('category=fcoe-networks&')

				}

			}

			$_Query = New-Object System.Collections.ArrayList

			# Handle default cause of AllResourcesInScope
			if ($Scope -eq 'AllResourcesInScope')
			{

				"[{0}] Processing AllResourcesInScope." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_Scopes = $ApplianceConnection.ActivePermissions | Where-Object Active

				# If one scope contains 'AllResources' ScopeName "tag", then all resources should be returned regardless.
				if ($_Scopes | Where-Object ScopeName -eq 'AllResources')
				{

					$_ScopeNames = [String]::Join(', ', ($_Scopes | Where-Object ScopeName -eq 'AllResources').ScopeName)

					"[{0}] Scope(s) {1} is set to 'AllResources'.  Will not add scope to URI query parameter." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeNames | Write-Verbose

				}

				# Process ApplianceConnection ActivePermissions collection
				else
				{

					Try
					{

						$_ScopeQuery = Join-Scope $_Scopes

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					[Void]$_Query.Add(("({0})" -f $_ScopeQuery))

				}

			}

			elseif ($Scope | Where-Object ScopeName -eq 'AllResources')
			{

				$_ScopeNames = [String]::Join(', ', ($_Scopes | Where-Object ScopeName -eq 'AllResources').ScopeName)

				"[{0}] Scope(s) {1} is set to 'AllResources'.  Will not add scope to URI query parameter." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeNames | Write-Verbose

			}

			elseif ($Scope -eq 'AllResources')
			{

				"[{0}] Requesting scope 'AllResources'.  Will not add scope to URI query parameter." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeNames | Write-Verbose

			}

			else
			{

				Try
				{

					$_ScopeQuery = Join-Scope $Scope

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				[Void]$_Query.Add(("({0})" -f $_ScopeQuery))

			}

			if ($Name)
			{

				if ($Name.Contains('*'))
				{

					[Void]$_Query.Add(("name%3A{0}" -f $Name.Replace(" ","?").Replace("*", "%2A")))

				}

				else
				{

					[Void]$_Query.Add(("name:'{0}'" -f $Name))

				}                
				
			}

			if ($Label)
			{

				[Void]$_Query.Add(("labels:'{0}'" -f $Label))

			}

			if ($Purpose)
			{

				[Void]$_Query.Add(("purpose:'{0}'" -f $Purpose))

			}

			# Build the final URI
			$_uri = '{0}?{1}sort=name:asc&query={2}' -f $IndexUri, $_Category.ToString(), [String]::Join(' AND ', $_Query.ToArray())

			Try
			{

				$_NetworksFromIndexCol = Get-AllIndexResources -Uri $_uri -ApplianceConnection $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			ForEach ($_member in $_NetworksFromIndexCol)
			{

				switch ($_member.category)
				{

					'ethernet-networks'
					{

						$_member.psobject.typenames.Insert(0,"HPOneView.Networking.EthernetNetwork")  

					}

					'fc-networks'
					{

						$_member.psobject.typenames.Insert(0,"HPOneView.Networking.FibreChannelNetwork")  

					}

					'fcoe-networks'
					{

						$_member.psobject.typenames.Insert(0,"HPOneView.Networking.FCoENetwork")  

					}

				}

				"[{0}] Adding '{1}' to found collection" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_member.Name | Write-Verbose
				
				[void]$Found.Add($_member)

			}

			# If network not found, report error
			if ($Found.Count -eq 0 -and $Name)
			{ 

				"[{0}] Network Resource Name was provided, yet no results were found.  Generate Error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ExceptionMessage = "The specified '{0}' Network resource was not found on '{1}' appliance connection.  Please check the name and try again." -f $Name, $_appliance.Name 
				$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException NetworkResourceNotFound ObjectNotFound "Name" -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				ForEach ($_item in $Found)
				{

					"[{0}] Adding '{1}' to final collection" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_.Name | Write-Verbose
				
					[void]$NetworkCollection.Add($_item)
				
				} 

			}			

		}

	}

	End 
	{

		if ($NetworkCollection) 
		{

			"[{0}] Results returned " -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Networks Found: {1} " -f $MyInvocation.InvocationName.ToString().ToUpper(), $NetworkCollection.Count | Write-Verbose

			"[{0}] Getting Network resource Connection Template Object to add bandwidth values to network objects." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			ForEach ($NetObject in $NetworkCollection) 
			{

				"[{0}] Processing '$($NetObject.Name)' Network resource." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				if ($NetObject.connectionTemplateUri) 
				{

					Try
					{

						$ct = Send-HPOVRequest -uri $NetObject.connectionTemplateUri -Hostname $NetObject.ApplianceConnection.Name

					}

					Catch
					{

					  $PSCmdlet.ThrowTerminatingError($_)

					}					
			
					Add-Member -InputObject $NetObject -NotePropertyName defaultMaximumBandwidth -NotePropertyValue $ct.bandwidth.maximumBandwidth -Force 
					Add-Member -InputObject $NetObject -NotePropertyName defaultTypicalBandwidth -NotePropertyValue $ct.bandwidth.typicalBandwidth -Force

				}
		
			}

			"[{0}] Done. {1} network resource(s) found." -f $MyInvocation.InvocationName.ToString().ToUpper(), $NetworkCollection.Count | Write-Verbose 
			
			if ($exportFile) 
			{ 
				
				"[{0}] Exporting JSON to $($exportFile)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
			
				$NetworkCollection | Sort-Object type,name | convertto-json > $exportFile
			
			}
			
			else
			{

				$NetworkCollection | Sort-Object type,name
			
			}
		
		}

		# No networks found
		else
		{ 
			
			"[{0}] No Network resources found."  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
		
		}

	}

}
