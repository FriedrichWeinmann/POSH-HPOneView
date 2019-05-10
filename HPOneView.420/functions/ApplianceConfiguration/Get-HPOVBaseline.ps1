function Get-HPOVBaseline 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

   	[CmdletBinding (DefaultParameterSetName = "ISOFileName" )]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "ISOFileName")]
		[ValidateNotNullOrEmpty()]
		[Alias ('isoFileName','FileName')]
		[Object]$File,

		[Parameter (Mandatory, ParameterSetName = "BaselineName")]
		[Alias ('name')]
		[ValidateNotNullOrEmpty()]
		[string]$SppName,

		[Parameter (Mandatory = $false, ParameterSetName = "BaselineName")]
		[ValidateNotNullOrEmpty()]
		[string]$Version,

		[Parameter (Mandatory = $false, ParameterSetName = "HotFixesOnly")]
		[switch]$HotfixesOnly,

		[Parameter (Mandatory = $false, ParameterSetName = "ISOFileName")]
		[Parameter (Mandatory = $false, ParameterSetName = "BaselineName")]
		[Parameter (Mandatory = $false, ParameterSetName = "HotFixesOnly")]
		[ValidateNotNullOrEmpty()]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (Mandatory = $false, ParameterSetName = "ISOFileName")]
		[Parameter (Mandatory = $false, ParameterSetName = "BaselineName")]
		[Parameter (Mandatory = $false, ParameterSetName = "HotFixesOnly")]
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

		$BaselineCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{
		
		ForEach($_Connection in $ApplianceConnection)
		{

			$_Query = New-Object System.Collections.ArrayList

			# Handle default cause of AllResourcesInScope
            if ($Scope -eq 'AllResourcesInScope')
            {

                "[{0}] Processing AllResourcesInScope." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

                $_Scopes = $_Connection.ActivePermissions | Where-Object Active

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

			switch ($PSCmdlet.ParameterSetName) 
			{
				
				"BaselineName" 
				{
				
					"[{0}] SppName Parameter provided: $($SppName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					if ($SppName.Contains('*'))
					{

						[Void]$_Query.Add(("fwbaseline_name%3A{0}" -f $SppName.Replace("*", "%2A")))

					}

					else
					{

						[Void]$_Query.Add(("fwbaseline_name:'{0}'" -f $SppName))

					} 

					if ($Version) 
					{

						"[{0}] Version Parameter provided: $($version)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						
						[Void]$_Query.Add(("fwbaseline_version:'{0}'" -f $Version))
					
					}				
			
				}
			
				"ISOFileName" 
				{

					if ($File) 
					{ 

						if ($File.EndsWith('.exe') -or $File.EndsWith('.scexe') -or $File.EndsWith('.rpm'))
						{

							"[{0}] Looking for hotfix file" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							if ($File.Contains('*'))
							{

								[Void]$_Query.Add(("fwbaseline_fileName%3A{0}" -f $File.Replace("*", "%2A")))

							}

							else
							{

								[Void]$_Query.Add(("fwbaseline_fileName:'{0}'" -f $File))

							}

						}

						else
						{

							"[{0}] Looking for Baseline ISO file" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							if (-not $File.EndsWith('iso'))
							{

                                $File += '.iso'
								
							}

							if ($File.Contains('*'))
							{

								[Void]$_Query.Add(("fwbaseline_isoFileName%3A{0}" -f $File.Replace("*", "%2A")))

							}

							else
							{

								[Void]$_Query.Add(("fwbaseline_isoFileName:'{0}'" -f $File))

							}						

						}
					
					}

				}

				'HotfixesOnly'
				{

					[Void]$_Query.Add("fwbaseline_bundleType:Hotfix")

				}
			
				default 
				{
			
					"[{0}] No Parameter provided. Looking for all SPP Baselines." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}
			
			}

			# Build the final URI
			$_uri = '{0}?category=firmware-drivers&sort=name:asc&query={1}' -f $IndexUri, [String]::Join(' AND ', $_Query.ToArray())

			Try
			{

				$_BundlesFromIndexCol = Get-AllIndexResources -Uri $_uri -ApplianceConnection $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if (-not $_BundlesFromIndexCol)
			{

				if ($PSBoundParameters['File']) 
				{

					$ExceptionMessage = "The Baseline resource name '{0}' was not found on '{1}' appliance." -f $File, $_Connection.Name
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'File' -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)

				}

				elseif ($PSBoundParameters['SppName'] -and -not $PSBoundParameters['Version']) 
				{

					$ExceptionMessage = "The Baseline name '{0}' was not found on '{1}' appliance." -f $SppName, $_Connection.Name
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'SppName' -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)

				}

				elseif ($PSBoundParameters['Version']) 
				{

					$ExceptionMessage = "The Baseline name '{0}' version '{1}' was not found on '{2}' appliance." -f $SppName, $Version, $_Connection.Name
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'SppName' -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)

				}

			}			

			# foreach ($_baseline in $_baselines.members)
            foreach ($_baseline in $_BundlesFromIndexCol)
			{
			
				# Inject repository location as a property, should not cause issues with other API calls with the resource
				# $_Locations = New-Object System.Collections.Arraylist
				$_Locations = New-Object "System.Collections.Generic.List[String]"

				ForEach ($_Location in ($_baseline.locations.PSObject.Members | Where-Object { $_.MemberType -eq 'NoteProperty'}))
				{

					[void]$_Locations.Add($_Location.Value)

				}

				# $_baseline.locations = [String]::Join(', ', $_Locations.ToArray())

				$_FwComponentsList = New-Object "System.Collections.Generic.List[HPOneView.Appliance.Baseline+FwComponent]"

				ForEach ($_Component in $_baseline.fwComponents)
				{

					$_FwComponentsList.Add((New-Object HPOneView.Appliance.Baseline+FwComponent($_Component.name,
																								$_Component.componentVersion,
																								$_Component.fileName,
																								$_Component.swKeyNameList)))

				}

				$_HotFixes = New-Object "System.Collections.Generic.List[HPOneView.Appliance.Baseline+Hotfix]"

				ForEach ($_Hotfix in $_baseline.hotfixes)
				{

					$_HotFixes.Add((New-Object HPOneView.Appliance.Baseline+HotFix($_Hotfix.hotfixName,
																				   $_Hotfix.releaseDate,
																				   $_Hotfix.resourceId)))
				}

				$_ParentBundle = $null
				
				if ($null -ne $_baseline.parentBundle)
				{

					$_ParentBundle = New-Object HPOneView.Appliance.Baseline+ParentBaseline($_baseline.parentBundle.parentBundleName, 
																							$_baseline.parentBundle.releaseDate, 
																							$_baseline.parentBundle.version)

				}

				$_SupportedOsList = New-Object "System.Collections.Generic.List[String]"

				ForEach ($_SupportedOS in $_baseline.supportedOSList)
				{

					$_SupportedOsList.Add($_SupportedOS)

				}

				switch ($_baseline.bundleType)
				{

					{'Custom', 'SPP' -contains $_}
					{

						New-Object HPOneView.Appliance.Baseline($_baseline.name,
																$_baseline.description,
																$_baseline.status,
																$_baseline.version,
																$_baseline.releaseDate,
																$_baseline.bundleType,
																$_baseline.bundleSize,
																$_baseline.resourceId,
																$_baseline.uuid,
																$_baseline.xmlKeyName,
																$_baseline.isoFileName,
																$_baseline.baselineShortName,
																$_SupportedOsList,
																$_baseline.supportedLanguages,
																$_FwComponentsList,
																$_baseline.state,
																$_baseline.hpsumVersion,
																$_ParentBundle,
																$_HotFixes,
																$_Locations,
																$null,
																$_baseline.uri,
																$_baseline.eTag,
																$_baseline.created,
																$_baseline.modified,
																$_baseline.resourceState,
																$_baseline.scopesUri,
																$_baseline.applianceConnection)

					}

					'Hotfix'
					{

						New-Object HPOneView.Appliance.BaselineHotfix($_baseline.name,
																	  $_baseline.description,
																	  $_baseline.status,
																	  $_baseline.version,
																	  $_baseline.releaseDate,
																	  $_baseline.bundleType,
																	  $_baseline.bundleSize,
																	  $_baseline.resourceId,
																	  $_baseline.uuid,
																	  $_baseline.xmlKeyName,
																	  $_baseline.isoFileName,
																	  $_baseline.baselineShortName,
																	  $_SupportedOsList,
																	  $_baseline.supportedLanguages,
																	  $_FwComponentsList,
																	  $_baseline.state,
																	  $_baseline.hpsumVersion,
																	  $_ParentBundle,
																	  $_HotFixes,
																	  $_Locations,
																	  $null,
																	  $_baseline.uri,
																	  $_baseline.eTag,
																	  $_baseline.created,
																	  $_baseline.modified,
																	  $_baseline.resourceState,
																	  $_baseline.scopesUri,
																	  $_baseline.applianceConnection)

					}

				}

			}

		}

	}

	End 
	{
		
		 "[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
