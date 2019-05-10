﻿function Get-HPOVServerProfileTemplate 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (ParameterSetName = "Default", Mandatory = $false)]
		[Parameter (ParameterSetName = "Detailed", Mandatory = $false)]
		[Parameter (ParameterSetName = "Export", Mandatory = $false)]
		[Alias ('profile')]
		[ValidateNotNullorEmpty()]
		[string]$Name,		

		[Parameter (ValueFromPipeline, ParameterSetName = "Default", Mandatory = $false)]
		[Parameter (ValueFromPipeline, ParameterSetName = "Detailed", Mandatory = $false)]
		[Parameter (ValueFromPipeline, ParameterSetName = "Export", Mandatory = $false)]
		[object]$ServerHardwareType,

		[Parameter (ParameterSetName = "Default", Mandatory = $false)]
		[Parameter (ParameterSetName = "Detailed", Mandatory = $false)]
		[Parameter (ParameterSetName = "Export", Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Label,

		[Parameter (ParameterSetName = "Default", Mandatory = $false)]
		[Parameter (ParameterSetName = "Detailed", Mandatory = $false)]
		[Parameter (ParameterSetName = "Export", Mandatory = $false)]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (ParameterSetName = "Detailed", Mandatory)]
		[switch]$Detailed,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Detailed")]
		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Export")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),
		
		[Parameter (ParameterSetName = "Export", Mandatory)]
		[Alias ("x")]
		[switch]$Export,

		[Parameter (ParameterSetName = "Export", Mandatory)]
		[ValidateNotNullOrEmpty()]
		[Alias ("save")]
		[string]$Location

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		# Validate the path exists.  If not, create it.
		if (($Export) -and (-not(Test-Path $Location)))
		{ 
		
			"[{0}] Directory does not exist.  Creating directory..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			New-Item -path $Location -ItemType Directory
		
		}

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

		$TemplateCollection = New-Object System.Collections.ArrayList

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

			$_Category = 'category={0}' -f $ResourceCategoryEnum.ServerProfileTemplate

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

			if ($PSBoundParameters['ServerHardwareType'])
			{

				switch ($ServerHardwareType.GetType().Name)
				{

					'String'
					{

						Try
						{

							$ServerHardwareType = Get-HPOVServerHardwareType -Name $ServerHardwareType -ApplianceConnection $ApplianceConnection -ErrorAction Stop

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

					'PSCustomObject'
					{

						if ($ServerHardwareType.category -ne 'server-hardware-types')
						{

							$ExceptionMessage = "The provided ServerHardwareType parameter value, '{0}', is not a supported resource type.  Please check the value, and try again." -f $ServerHardwareType.name
							$ErrorRecord = New-ErrorRecord HPOneView.ServerHardwareTypeResourceException ServerHardwareTypeInvalidObject InvalidParameter 'ServerHardwareType' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

				}

				$_ResourcesFromIndexCol = $_ResourcesFromIndexCol | Where-Object { $_.serverHardwareTypeUri -eq $ServerHardwareType.uri }

			}
			
			if($_ResourcesFromIndexCol.Count -eq 0 -and $Name)
			{

				"[{0}] Profile Template Resource Name '{1}' was not found on appliance {2}.  Generate Error." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name, $_appliance.Name | Write-Verbose
				
				$ExceptionMessage = "The specified Server Profile Template '{0}' was not found on '{1}' appliance connection. Please check the name again, and try again." -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ServerProfileResourceNotFound ObjectNotFound "Name" -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)
				
			}

			else
			{

				foreach ($_member in $_ResourcesFromIndexCol)
				{
				
					$_member.PSObject.TypeNames.Insert(0,'HPOneView.ServerProfileTemplate')
						
					[void]$TemplateCollection.Add($_member)
					
				}

			}

		}

	}

	End 
	{

		"[{0}] Done. {1} server profile template resource(s) found." -f $MyInvocation.InvocationName.ToString().ToUpper(), $TemplateCollection.count | Write-Verbose 

		# If user wants to export the profile configuration
		if ($export) 
		{

			# Get the unique applianceConnection.name properties from the profile collection for grouping the output files
			$ProfileGroupings = $TemplateCollection.ApplianceConnection.name | Select-Object -Unique

			ForEach ($pg in $ProfileGroupings)
			{
				
				$outputProfiles = New-Object System.Collections.ArrayList

				$templates = $TemplateCollection | Where-Object { $_.ApplianceConnection.Name -eq $pg }

				# Loop through all profiles
				foreach ($_profile in $templates) 
				{

					# Trim out appliance unique properties

					$_profile = $_profile | select-object -Property * -excludeproperty uri,etag,created,modified,status,state,inprogress,enclosureUri,enclosureBay,serverHardwareUri,taskUri,ApplianceConnection
					$_profile.serialNumberType = "UserDefined"

					# Loop through the connections to save the assigned address
					$i = 0
					foreach ($connection in $profile.connectionSettings.connections) 
					{

						if ($profile.connectionSettings.connections[$i].mac) { $_profile.connectionSettings.connections[$i].macType = "UserDefined" }
						if ($profile.connectionSettings.connections[$i].wwpn) { $_profile.connectionSettings.connections[$i].wwpnType = "UserDefined" }
						$i++

					}

					[void]$outputProfiles.Add($_profile)
					
				}

				# Save profile to JSON file
				"[{0}] Saving Server Profile Templates to {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($location + '\' + $pg + '_ServerProfileTemplates.json') | Write-Verbose

				convertto-json -InputObject $outputProfiles -depth 99 | new-item ($location + '\' + $pg + '_ServerProfileTemplates.json') -itemtype file

			}

		}

		else 
		{

			Return $TemplateCollection

		}

	}

}
