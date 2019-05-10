function Remove-HPOVLdapGroup 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('g','Group','Name')]
		[Object]$InputObject,
	
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject'])) 
		{ 
			
			$PipelineInput = $True 
		
		}

		else
		{

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

		}
		
		$_TaskCollection  = New-Object System.Collections.ArrayList
		$_GroupCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{
 
		if ($PipelineInput -or $InputObject -is [PSCustomObject]) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Group Object provided: {2}\{1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.egroup, $InputObject.logindomain | Write-Verbose

			If ('users' -contains $InputObject.category)
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "Group:$($InputObject.Name)" -TargetType PSObject -Message "The Group object resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_GroupCollection.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message "The Group object resource is not an expected category type [$($Name.category)].  The allowed resource category type is 'users'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing Appliance $($_appliance.Name) (of $($ApplianceConnection.Count))" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Processing Group Name $($InputObject)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_Group = Get-HPOVLdapGroup -Name $InputObject -ApplianceConnection $_appliance

					$_Group | ForEach-Object {

						[void]$_GroupCollection.Add($_)

					}

				}

				Catch
				{

					if ($_.FullyQualifiedErrorId -match 'AuthDirectoryGroupResourceNotFound')
					{

						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.LdapDirectoryGroupException AuthDirectoryGroupResourceNotFound ObjectNotFound 'InputObject' -Message "The Directory Group '$InputObject' was not found on Appliance '$($_appliance.Name)'."
						$PSCmdlet.WriteError($ErrorRecord)

					}

					else
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}				

			}

		}

	}

	End
	{

		"[{0}] Processing $($_GroupCollection.count) Directory Group resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Process Network Resources
		ForEach ($_Group in $_GroupCollection)
		{

			if ($PSCmdlet.ShouldProcess($_Group.ApplianceConnection.Name,"remove directory group '$($_Group.egroup)'")) 
			{

				"[{0}] Removing Directory Group '$($_Group.egroup)' from appliance '$($_Group.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					
					$_resp = Send-HPOVRequest $_Group.Uri DELETE -Hostname $_Group.ApplianceConnection.Name

					$_resp | Add-Member -NotePropertyName name -NotePropertyValue $_Group.egroup

					[void]$_TaskCollection.Add($_resp)

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($PSBoundParameters['WhatIf'])
			{

				"[{0}] WhatIf Parameter was passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

		}

		Return $_TaskCollection

	}

}
