function Get-HPOVInterconnect 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Label,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false)]
		[Alias ("x", "exportFile")]
		[ValidateScript({split-path $_ | Test-Path})]
		[String]$Export

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

		$InterconnectCollection   = New-Object System.Collections.ArrayList
		$ApplianceInterconnectCol = New-Object System.Collections.ArrayList
		$NotFound                 = New-Object System.Collections.ArrayList
		
		$InterconnecUris = $SasInterconnectsUri, $InterconnectsUri
		
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

			# Build the final URI
			$_uri = '{0}?category=interconnects&category=sas-interconnects&sort=name:asc&query={1}' -f $IndexUri, [String]::Join(' AND ', $_Query.ToArray())

			Try
			{

				[Array]$_ResourcesFromIndexCol = Get-AllIndexResources -Uri $_uri -ApplianceConnection $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			ForEach ($_member in $_ResourcesFromIndexCol)
			{

				"[{0}] Processing resource {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_member.name, $_ResourcesFromIndexCol.Count | Write-Verbose

				switch ($_member.category)
				{

					'sas-interconnects'
					{

						# Add the Custom TypeName
						$_member.PSObject.TypeNames.Insert(0,"HPOneView.Networking.SasInterconnect") 

					}

					'interconnects'
					{

						# Add the Custom TypeName
						$_member.PSObject.TypeNames.Insert(0,"HPOneView.Networking.Interconnect") 

						# Add the Custom Uplink/Stacking Link TypeName
						$_member.ports | Where-Object { $_.portType -eq "Uplink" -or $_.portType -eq "Stacking" } | ForEach-Object { 
		
							$_.PSObject.TypeNames.Insert(0,"HPOneView.Networking.Interconnect.UplinkPort") 

							$_ | Add-Member -NotePropertyName ApplianceConnection -NotePropertyValue (New-Object HPOneView.Library.ApplianceConnection($_appliance.Name, $_appliance.ConnectionID))

						}
				
						# Add the Custom Downlink Link TypeName
						$_member.ports | Where-Object { $_.portType -eq "Downlink" } | ForEach-Object { 
		
							$_.PSObject.TypeNames.Insert(0,"HPOneView.Networking.Interconnect.DownlinkPort") 

							$_ | Add-Member -NotePropertyName ApplianceConnection -NotePropertyValue (New-Object HPOneView.Library.ApplianceConnection($_appliance.Name, $_appliance.ConnectionID))

						}
					
					}

				}

				[void]$InterconnectCollection.Add($_member)

			}

			# Generate final error if name wasn't found on appliance(s)
			if ($NotFound.count -gt 0 -and $Name -and $ApplianceInterconnectCol.count -eq 0) 
			{

				$ErrorRecord = New-ErrorRecord HPOneView.InterconnectResourceException InterconnectNameResourceNotFound ObjectNotFound 'Name' -Message "No Interconnect resources with '$Name' name were found on appliance $($NotFound -join ", ")."
				$PSCmdlet.WriteError($ErrorRecord)

			}

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if ($Export)
		{ 
				
			"[{0}] Exporting to: $($Export)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$InterconnectCollection | convertto-json -Depth 99 | Set-Content -Path $Export -force -encoding UTF8
				
		}

		else
		{

			Return $InterconnectCollection | Sort type, name

		}

	}
	
}
