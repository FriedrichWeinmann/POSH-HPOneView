function Add-HPOVResourceToScope
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param
	(

		[Parameter (Mandatory, ParameterSetName = "Default", ValueFromPipeline)]
		[ValidateNotNullorEmpty()]
		[HPOneView.Appliance.ScopeCollection]$Scope,
		
		[Parameter (Mandatory, ParameterSetName = "Default")]
		[Alias('Resource')]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,
		
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = "Default", ValueFromPipelineByPropertyName)]
		[Alias ('Appliance')]
		[ValidateNotNullOrEmpty()]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['Scope'])) 
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

						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError $_connection -Message $_.Exception.Message -InnerException $_.Exception
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

	}

	Process
	{

		#$_UpdateScopeMembers = NewObject -ScopeMemberUpdate
		$_UpdateScopeMembers = NewObject -PatchOperation
		$_UpdateScopeMembers.op = 'add'
		$_UpdateScopeMembers.path = '/addedResourceUris'
		$_UpdateScopeMembers.value = New-Object System.Collections.ArrayList

		ForEach ($_resource in $InputObject)
		{

			# Validate Resource is allowed
			if ($ScopeCategoryEnum[$_resource.category])
			{

				# Generate error that Resource already contains the Scope Uri
				if ($_resource.scopeUris -contains $Scope.Uri)
				{

					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.ScopeResourceException ResourceAlreadyWithinScope ResourceExists -TargetObject 'InputObject' -TargetType 'PSObject' -Message ('{0} is already a member of {1} scope.' -f $_resource.name, $Scope.Name)
					$PSCmdlet.WriteError($ErrorRecord)

				}

				# Add resource URI to collection
				else
				{

					"[{0}] {1} Resource is not a member of {2} Scope, adding to collection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_resource.name, $Scope.Name | Write-Verbose

					[void]$_UpdateScopeMembers.value.Add($_resource.uri)			

				}

			}

		}

		Try
		{

			$_Resp = Send-HPOVRequest -Uri $Scope.Uri -Method PATCH -Body $_UpdateScopeMembers -Hostname $ApplianceConnection #-OverrideContentType 'application/json-patch+json'

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if ($PSboundParameters['Async'])
		{

			$_Resp

		}

		else
		{

			$_resp | Wait-HPOVTaskComplete

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
