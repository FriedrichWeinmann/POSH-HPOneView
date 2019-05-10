function Get-HPOVServer 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(
		
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[string]$ServerName,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[switch]$NoProfile,

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "Default")]
		[Alias ('ServerHardwareType','ServerProfileTemplate')]
		[object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[String]$Label,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$Scope = "AllResourcesInScope",

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

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

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

			if ($ServerName)
			{

				if ($ServerName.Contains('*'))
				{

					[Void]$_Query.Add(("serverName%3A%2A{0}" -f $ServerName.Replace("*", "%2A").Replace(" ", "?")))

				}

				else
				{

					[Void]$_Query.Add(("serverName:'{0}'" -f $ServerName))

				}                
				
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

			if ($Label)
			{

				[Void]$_Query.Add(("labels:'{0}'" -f $Label))

			}

			$_Category = 'category=server-hardware'

			# Build the final URI
			$_uri = '{0}?{1}&sort=name:asc&query={2}' -f $IndexUri,  [String]::Join('&', $_Category), [String]::Join(' AND ', $_Query.ToArray())

			Try
			{

				[Array]$_ResourcesFromIndexCol = Get-AllIndexResources -Uri $_uri -ApplianceConnection $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# Filter collection for resources without profile assigned
			if ($PSBoundParameters['NoProfile']) 
			{ 
				
				"[{0}] Filtering for server hardware with no assigned profiles." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

				$_ResourcesFromIndexCol = $_ResourcesFromIndexCol | Where-Object { $null -eq $_.serverProfileUri }
			
			}

			# Filter collection for resources that match the SHT of inputobject provided
			if ($InputObject)
			{

				switch ($InputObject.category)
				{

					$ResourceCategoryEnum.ServerProfileTemplate
					{

						$_FilterProperty = "serverHardwareTypeUri"

						$_FilterUri = $InputObject.serverHardwareTypeUri

					}

					$ResourceCategoryEnum.ServerProfile
					{

						$_FilterProperty = "serverProfileUri"

						$_FilterUri = $InputObject.uri

					}

					$ResourceCategoryEnum.ServerHardwareType
					{

						$_FilterProperty = "serverHardwareTypeUri"

						$_FilterUri = $InputObject.uri

					}

					default
					{

						if ($InputObject.PSObject.properties -match 'category')
						{

							$InputObjectName = $InputObject.name.Clone()

						}

						else
						{

							$InputObjectName = $InputObject.Clone()

						}

						$ExceptionMessage = "The provided InputObject parameter value, '{0}', is not a supported resource type.  Only server profile template or server hardware type resources are supported.  Please check the value, and try again." -f $InputObjectName
						$ErrorRecord = New-ErrorRecord HPOneView.InputObjectResourceException InvalidInputObject InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				"FilterProperty: {0}" -f $_FilterProperty | Write-Verbose
				"FilterUri: {0}" -f $_FilterUri | Write-Verbose

				$_ResourcesFromIndexCol = $_ResourcesFromIndexCol | Where-Object { $_.$_FilterProperty -eq $_FilterUri }

			}

			if ($_ResourcesFromIndexCol.count -eq 0 -and $Name) 
			{
					
				$ExceptionMessage = "Server Hardware '{0}' not found on '{1}' appliance connection. Please check the name again, and try again." -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord HPOneView.ServerHardwareResourceException ServerHardwareResourceNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			if ($_ResourcesFromIndexCol.count -eq 0 -and $ServerName) 
			{
					
				$ExceptionMessage = "Server Hardware OS Server Name '{0}' not found on '{1}' appliance connection. Please check the name again, and try again." -f $ServerName, $_appliance.Name
				$ErrorRecord = New-ErrorRecord HPOneView.ServerHardwareResourceException ServerHardwareResourceNotFound ObjectNotFound 'ServerName' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				ForEach ($s in ($_ResourcesFromIndexCol | Sort-Object name)) 
				{

					$s.PSObject.TypeNames.Insert(0,'HPOneView.ServerHardare')

					$s

				}

			}	

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
