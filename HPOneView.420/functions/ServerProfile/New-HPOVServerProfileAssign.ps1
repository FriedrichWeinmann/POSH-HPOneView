function New-HPOVServerProfileAssign
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Unassigned")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Profile')]
		[Object]$ServerProfile,
		
		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$Server,
		
		[Parameter (Mandatory = $false, ParameterSetName = "Unassigned")]
		[switch]$Unassigned,

		[Parameter (Mandatory = $false, ParameterSetName = "Unassigned")]
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[switch]$Force,

		[Parameter (Mandatory = $false, ParameterSetName = "Unassigned")]
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Unassigned")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['ServerProfile']))
		{

			$PipelineInput = $True

		}

		else
		{

			"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

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

		$_taskCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		# Look at Profile and Server if they are objects, and make sure ApplianceConnection.Name match
		if ($ServerProfile -is [PSCustomObject] -and $Server -is [PSCustomObject])
		{

			if ($ServerProfile.ApplianceConnection.Name -ne $Server.ApplianceConnection.Name)
			{

				"[{0}] Server Profile '{1}' and Server Hardware '{2}' ApplianceConnection do not match." -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerProfile.ApplianceConnection.Name, $Server.ApplianceConnection.Name | Write-Verbose

				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ProfileAndServerApplianceConnectionMismatch InvalidArgument 'Profile' -TargetType 'PSObject' -Message "The Server Profile ($($ServerProfile.ApplianceConnection.Name)) and Server Hardware ($($Server.ApplianceConnection.Name)) ApplianceConnection NoteProperty do not match.  Please correct the value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		# Looking for the $server DTO to be string
		if ($ServerProfile -is [string]) 
		{

			try 
			{ 
				
				$ServerProfile = Get-HPOVServerProfile -name $ServerProfile -ApplianceConnection $ApplianceConnection -ErrorAction Stop
			
			}
			
			catch
			{

				$PSCmdlet.ThrowTerminatingError($_)
				
			}

		}

		elseif ($ServerProfile -is [PSCustomObject] -and $ServerProfile.category -ne $ResourceCategoryEnum.ServerProfile)
		{

			$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException ProfileObjectInvalidCategory InvalidArgument 'Profile' -TargetType 'PSObject' -Message "The Server Profile ({0}) is an unsupported resource category type, '{1}'.  Only '{2}' are supported.  Please correct the value and try again." -f $ServerProfile.name, $ServerProfile.category, $ResourceCategoryEnum.ServerProfile
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		"[{0}] Server Profile Object: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerProfile.name, $ServerProfile.uri | Write-Verbose
		
		# Check to make sure the server hardware the profile is assigned to is powered off
		if ($ServerProfile.serverHardwareUri) 
		{

			Try
			{

				$_ServerResource = Send-HPOVRequest $ServerProfile.serverHardwareUri -Hostname $ServerProfile.ApplianceConnection.Name

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($_ServerResource.powerState -ne "Off") 
			{

				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidServerPowerState InvalidResult 'Profile' -Message "The Server '$($_ServerResource.name)' is currently powered On.  Please power off the server and then perform the operation again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		# Looking for the $server DTO to be string
		if ($Server -is [string]) 
		{

			try 
			{ 

				$Server = Get-HPOVServer -name $Server -ErrorAction Stop -ApplianceConnection $ApplianceConnection

			}

			catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		elseif ($Server -is [PSCustomObject] -and $Server.category -ne 'server-hardware')
		{

			$ErrorRecord = New-ErrorRecord HPOneView.ServerHardwareResourceException ServerObjectInvalidCategory InvalidArgument 'Server' -TargetType 'PSObject' -Message "The Server ($($Server.name)) is an unsupported resource category type, '$($Server.category)'.  Only 'server-hardware' are supported.  Please correct the value and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# "[{0}] Server Object: $($Server | Format-List * )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		if ($PSBoundParameters['Unassigned'])
		{

			$ServerProfile.serverHardwareUri = $Null
			
			if ($ServerProfile.enclosureUri) 
			{

				$ServerProfile.enclosureUri      = $Null
				$ServerProfile.enclosureBay      = $Null	

			}

		}

		else 
		{

			if ($Server.serverHardwareTypeUri -ne $ServerProfile.serverHardwareTypeUri) 
			{

				"[{0}] Server Profile assigned serverHardwareTypeUri does not match the destination Server resource.  Updating Server Profile with new serverHardwareTypeUri value." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ServerProfile.serverHardwareTypeUri = $Server.serverHardwareTypeUri
			
			}

			$ServerProfile.serverHardwareUri = $server.uri

			if ($server.locationUri) 
			{

				$ServerProfile.enclosureUri = $server.locationUri
				$ServerProfile.enclosureBay = $server.position	

			}			

		}

		$_Uri = $ServerProfile.uri

		if ($Force)
		{

			$_Uri += "?force=all"

		}

		try 
		{ 

			$_resp = Send-HPOVRequest -Uri $_Uri -Method PUT -Body $ServerProfile -Hostname $ApplianceConnection.Name

		}

		catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		Try
		{

			$_resp = $_resp | Wait-HPOVTaskStart

			if ($_resp.taskState -eq 'Error')
			{

				if ($_resp.taskErrors.message -match 'The selected server hardware has health status other than "OK"' -and 
					$PSCmdlet.ShouldProcess($Server.name, 'The selected server hardware has health status other than "OK". Do you wish to override and assign the Server Profile'))
				{

					Try
					{
					
						$_Uri = '{0}?force=all' -f $ServerProfilesUri

						$_resp = Send-HPOVRequest -Uri $_Uri -Method PUT -Body $ServerProfile -Hostname $ApplianceConnection
			
					}
			
					Catch
					{
			
						$PSCmdlet.ThrowTerminatingError($_)
			
					}

				}

				else
				{

					$ExceptionMessage = $_resp.taskErrors.message
					$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidOperation InvalidOperation 'AsyncronousTask' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

				}				

			}				

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not $PSBoundParameters['Async'])
		{
		
			$_resp = Wait-HPOVTaskComplete -InputObject $_resp -ApplianceConnection $_resp.ApplianceConnection.Name
	
		}

		$_resp	

	}

	End 
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
