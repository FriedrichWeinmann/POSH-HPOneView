function Get-HPOVOSDeploymentPlan
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Object]$Scope = "AllResourcesInScope",

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = ($ConnectedSessions | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection) -and -not($ConnectedSessions))
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

		$_OSDeploymentPlanCollection = New-Object System.Collections.ArrayList

	}

	Process
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			If ($_appliance.ApplianceType -ne 'Composer')
			{

				$ExceptionMessage = 'The ApplianceConnection {0} ({1}) is not a Synergy Composer.  This Cmdlet only support Synergy Composer management appliances.' -f $_appliance.Name, $_appliance.ApplianceType
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

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

				# if ($Label)
				# {

				# 	[Void]$_Query.Add(("labels:'{0}'" -f $Label))

				# }

				$_Category = 'category=os-deployment-plans'

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

				if ($Name -and -not $_ResourcesFromIndexCol)
				{

					$ExceptionMessage = 'OS Deployment Plan "{0}" was not found on "{1}" appliance connection.' -f $Name, $_appliance.Name
					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ImageStreamerResourceException ResourceNotFound ObjectNotFound "Name" -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)

				}

				else
				{

					ForEach ($_member in $_ResourcesFromIndexCol)
					{
					
						$_member.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.OSDeploymentPlan')

						[void]$_OSDeploymentPlanCollection.Add($_member)

					}

				}				

			}			

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Return $_OSDeploymentPlanCollection

	}

}
