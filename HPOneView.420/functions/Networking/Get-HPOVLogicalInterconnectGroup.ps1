function Get-HPOVLogicalInterconnectGroup 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (ValueFromPipeline, Mandatory, ParameterSetName = 'Pipeline')]
		[Alias('Resource')]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateSet ('SAS','VC')]
		[String]$Type,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[String]$Label,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Pipeline')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Alias ("x", "export")]
		[ValidateScript({split-path $_ | Test-Path})]
		[String]$exportFile

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($PSCmdlet.ParameterSetName -eq 'Pipeline')
		{

			$PipelineInput = $True

		}

		Else
		{

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

		$LigCollection = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		if ($PipelineInput -or $InputObject -is [PSCustomObject])
		{

			# Task Resource Object
			if ($InputObject.category -eq 'tasks')
			{

				"[{0}] Task Resource input object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				if ($InputObject.taskState -eq 'Completed')
				{

					Try
					{

						$_LigObject = Send-HPOVRequest $InputObject.associatedResource.resourceUri -Hostname $InputObject.ApplianceConnection.Name

						$_LigObject | ForEach-Object { 
				
							$_.PSObject.TypeNames.Insert(0,'HPOneView.Networking.LogicalInterconnectGroup')	

							[void]$LigCollection.Add($_) 
				
						}

					}

					Catch
					{

						"[{0}] API Error Caught: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_.Exception.Message | Write-Verbose

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				# Generate error
				else
				{

					$InputObject

					$ErrorRecord = New-ErrorRecord HPOneView.LogicalInterconnectGroupResourceException TaskFailure InvalidOperation 'InputObject' -Message "The Task object provided by the pipeline did not complete successfully.  Please validate the task object resource and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

				}

			}

			else
			{

				$ErrorRecord = New-ErrorRecord HPOneView.LogicalInterconnectGroupResourceException LogicalInterconnectGroupNotFound ObjectNotFound 'InputObject' -Message "The Logical Interconnect Group associated with the pipeline input task object was not found on '$($InputObject.ApplianceConnection.Name)'.  Please check the value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

			}

		}

		Else
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

				if (-not $PSBoundParameters['Type'] -and $_appliance.ApplianceType -ne 'Composer')
				{

					$_Category = 'category=logical-interconnect-groups'

				}

				elseif (-not $PSBoundParameters['Type'] -and $_appliance.ApplianceType -eq 'Composer')
				{

					$_Category = 'category=logical-interconnect-groups&category=sas-logical-interconnect-groups'

				}

				else
				{

					$_Category = @()

					switch ($Type)
					{

						'VC'
						{

							$_Category += 'category=logical-interconnect-groups'

						}

						'SAS'
						{

							$_Category += 'category=sas-logical-interconnect-groups'

						}

					}

				}

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

				# Generate non-terminating exception if the name wasn't found
				if ($_ResourcesFromIndexCol.count -eq 0 -and $Name) 
				{ 

					"[{0}] Logical Interconnect Group '$name' resource not found. Generating error" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$ExceptionMessage = "Specified Logical Interconnect Group '{0}' was not found on '{1}' appliance connection.  Please check the name and try again." -f $Name, $_appliance.Name
					$ErrorRecord = New-ErrorRecord InvalidOperationException LogicalInterconnectGroupNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)  

				}

				ForEach ($_member in $_ResourcesFromIndexCol) 
				{

					"[{0}] Processing '{1}' resource (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_member.Name, $_ResourcesFromIndexCol.Count | Write-Verbose

					switch ($_member.category)
					{

						'logical-interconnect-groups'
						{
							
							$_member.PSObject.TypeNames.Insert(0,'HPOneView.Networking.LogicalInterconnectGroup')	

							[void]$LigCollection.Add($_member) 

						}

						'sas-logical-interconnect-groups'
						{

							$_member.PSObject.TypeNames.Insert(0,'HPOneView.Networking.SASLogicalInterconnectGroup')	

							[void]$LigCollection.Add($_member) 

						}

					}

				}

			}		

		}

	}

	End 
	{

		"[{0}] Done. {1} logical interconnect group(s) found." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LigCollection.count | Write-Verbose

		if ($exportFile)
		{
			
			$LigCollection | convertto-json -Depth 99 | Set-Content -Path $exportFile -force -encoding UTF8 
		
		}
				
		else 
		{
			
			Return $LigCollection | Sort-Object category,name
		
		}

	}

}
