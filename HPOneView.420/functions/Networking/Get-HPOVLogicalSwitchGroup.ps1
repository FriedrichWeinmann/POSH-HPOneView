function Get-HPOVLogicalSwitchGroup
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (ValueFromPipeline, Mandatory, ParameterSetName = 'Pipeline')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
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

		$_Collection = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		if ($PipelineInput)
		{

			# Task Resource Object
			if ($InputObject -is [PSCustomObject] -and $InputObject.category -eq 'tasks')
			{

				"[{0}] Processig task resource to get created object" -f $MyInvocation.InvocationName.ToString().ToUpper()

				if ($InputObject.taskState -eq 'Completed')
				{

					Try
					{

						$_LogicalSwitchGroup = Send-HPOVRequest $InputObject.associatedResource.resourceUri -Hostname $InputObject.ApplianceConnection.Name

						$_LogicalSwitchGroup | ForEach-Object { 
				
							$_.PSObject.TypeNames.Insert(0,'HPOneView.Networking.LogicalSwitchGroup')	

							[void]$_Collection.Add($_) 
				
						}

					}

					Catch
					{

						"[{0}] API Error Caught: $($_.Exception.Message)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				# Generate error
				else
				{

					$ErrorRecord = New-ErrorRecord HPOneView.LogicalSwitchGroupResourceException TaskFailure InvalidOperation 'InputObject' -Message "The Task object provided by the pipeline did not complete successfully.  Please validate the task object resource and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

				}

			}

			else
			{

				$ErrorRecord = New-ErrorRecord HPOneView.LogicalSwitchGroupResourceException LogicalSwitchGroupNotFound ObjectNotFound 'InputObject' -Message "The Logical Switch Group associated with the pipeline input task object was not found on '$($InputObject.ApplianceConnection.Name)'.  Please check the value and try again."
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

				$_Category = 'category=logical-switch-groups'

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

				if ($_ResourcesFromIndexCol.count -eq 0 -and $Name) 
				{ 

					$ExceptionMessage = "Logical Switch Group '{0}' resource not found on {1} appliance.  Please check the name and try again." -f $Name, $_appliance.Name

					"[{0}] {1} Generating error" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ExceptionMessage | Write-Verbose
				
					$ErrorRecord = New-ErrorRecord InvalidOperationException LogicalSwitchGroupNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)  

				}  
	
				elseif ($_ResourcesFromIndexCol.count -eq 0) 
				{ 

					"[{0}] No Logical Switch Group resources found on {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

				}

				else 
				{

					"[{0}] Found {1} Logical Switch Group resource(s)." -f $MyInvocation.InvocationName.ToString().ToUpper(), $ligs.count | Write-Verbose
		
					ForEach ($_member in $_ResourcesFromIndexCol)
					{			

						$_member.PSObject.TypeNames.Insert(0,'HPOneView.Networking.LogicalSwitchGroup')	

						[void]$_Collection.Add($_member) 

					}

				}

			}

		}

	}

	End 
	{

		"[{0}] Done. $($_Collection.count) logical switch group(s) found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose    

		if ($exportFile)
		{
			
			$_Collection | convertto-json -Depth 99 | Set-Content -Path $exportFile -force -encoding UTF8 
		
		}
				
		else 
		{
			
			Return $_Collection | Sort-Object name
		
		}

	}

}
