function Get-HPOVLogicalEnclosure 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
  
	[CmdletBinding (DefaultParameterSetName = "default")]    
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[validateNotNullorEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "default")]
		[validateNotNullorEmpty()]
		[Object]$EnclosureGroup,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[switch]$NonCompliant,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[validateNotNullorEmpty()]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
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

		$_LogicalEnclosureCollection = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			# Handle pipeline input for connection object
			if ($_appliance -isnot [HPOneView.Appliance.Connection])
			{

				$_appliance = $ConnectedSessions | Where-Object ConnectionId -eq $_appliance.ConnectionId

			}

			"[{0}] Processing appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			$_Query = New-Object System.Collections.ArrayList

			# Handle default cause of AllResourcesInScope
            if ($Scope -eq 'AllResourcesInScope')
            {

                "[{0}] Processing AllResourcesInScope." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

                $_Scopes = $_appliance.ActivePermissions | Where-Object Active

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

					[Void]$_Query.Add(("name%3A{0}" -f $Name.Replace("*", "%2A").Replace(',','%2C').Replace(" ", "?")))

				}

				else
				{

					[Void]$_Query.Add(("name:'{0}'" -f $Name))

				}                
				
			}

			if ($PSBoundParameters['NonCompliant'])
			{

				"[{0}] Filtering for non-compliant logical enclosures." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[Void]$_Query.Add("state:'Inconsistent'")

			}

			if ($Label)
			{

				[Void]$_Query.Add(("labels:'{0}'" -f $Label))

			}

			# Build the final URI
			$_uri = '{0}?category=logical-enclosures&sort=name:asc&query={1}' -f $IndexUri, [String]::Join(' AND ', $_Query.ToArray())

			Try
			{

				[Array]$_ResourcesFromIndexCol = Get-AllIndexResources -Uri $_uri -ApplianceConnection $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($EnclosureGroup)
			{

				"[{0}] Filtering Logical Enclosures for parent Enclosure Group '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $EnclosureGroup.name | Write-Verbose

				[Array]$_ResourcesFromIndexCol = $_ResourcesFromIndexCol | Where-Object enclosureGroupUri -eq $EnclosureGroup.uri

			}
	
			if ($_ResourcesFromIndexCol.count -eq 0 -and $Name) 
			{ 
	
				"[{0}] Logical Enclosure '{1}' resource not found. Generating error" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

				$ExceptionMessage = "The specified Logical Enclosure '{0}' was not found on '{1}' appliance.  Please check the name and try again." -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord HPOneView.LogicalEnclosureResourceException LogicalEnclosureNotFound ObjectNotFound 'Name' -Message $ExceptionMessage  
				$PSCmdlet.WriteError($ErrorRecord)  
				
			}
	
			elseif ($_ResourcesFromIndexCol.count -eq 0) 
			{ 
	
				"[{0}] No Logical Enclosure resources found on {1}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.name | Write-Verbose
	
			}
	
			else 
			{
	
				"[{0}] Found {1} Enclosure Group resources." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ResourcesFromIndexCol.count | Write-Verbose
	
				$_ResourcesFromIndexCol | ForEach-Object { 
					
					$_.PSObject.TypeNames.Insert(0,'HPOneView.LogicalEnclosure')	
	
					[void]$_LogicalEnclosureCollection.Add($_) 
					
				}
	 
			}

		}

	}

	End 
	{
				
		"[{0}] Done. {1} total Logical Enclosure(s) found." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_LogicalEnclosureCollection.count | Write-Verbose
				
		# Export results to exportfile
		if ($exportFile) 
		{ 
			
			$_LogicalEnclosureCollection | convertto-json -depth 99 > $exportFile 
		
		}
		
		# else Return Logical Enclosure object(s)
		else 
		{ 

			Return $_LogicalEnclosureCollection
		
		}

	}

}
