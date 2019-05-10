function Get-HPOVRackMember
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
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

			$PipelineInput = $true

		}

		else
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

		$_RackCol        = New-Object System.Collections.ArrayList
		$_TaskCollection = New-Object System.Collections.ArrayList

	}

	Process
	{

		if ($InputObject -is [PSCustomObject]) 
		{

			"[{0}] Rack Object provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

			If ('racks' -contains $InputObject.category)
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord HPOneView.RackResourceException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message "The InputObject object resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			else
			{

				$ErrorRecord = New-ErrorRecord HPOneView.RackResourceException InvalidArgumentValue InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message "The InputObject object resource is not an expected type.  The allowed resource category type is 'racks'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			"[{0}] Get most current Rack object version" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject | Write-Verbose

			Try
			{

				$InputObject = Send-HPOVRequest -Uri $InputObject.uri -Hostname $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		else 
		{

			"[{0}] Processing Rack Name {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject | Write-Verbose

			Try
			{

				$InputObject = Get-HPOVRack -Name $InputObject -ApplianceConnection $ApplianceConnection -ErrorAction Stop

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		# Get list of rack mounted objects to then either return to the caller or search for specific resource name
		ForEach ($_RackItem in $InputObject.rackMounts)
		{

			Try
			{

				$_RackItemObject = Send-HPOVRequest -Uri $_RackItem.mountUri -Hostname $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			switch ($_RackItemObject.category)
			{

				'server-hardware'
				{

					$_Model = $_RackItemObject.model
					[int]$_UHeight = $_RackItemObject.formFactor.Replace('U',$null)

				}

				'unmanaged-devices'
				{

					$_Model = $_RackItemObject.model
					[int]$_UHeight = $_RackItemObject.height

				}

				'enclosures'
				{

					$_Model = $_RackItemObject.enclosureModel
					[int]$_UHeight = 10

				}

			}

			$_RackULocation = $_RackItem.topUSlot - $_UHeight + 1

			Try
			{

				$_RackMember = New-Object HPOneView.Facilities.RackMember($_RackItemObject.name, $_Model, $_UHeight, $_RackULocation, $_RackItemObject.uri, $InputObject.name, $InputObject.uri, $_RackItemObject.ApplianceConnection)

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			[void]$_RackCol.Add($_RackMember)

		}

		if ($Name)
		{

			$_RackCol = $_RackCol | Where-Object { $_.Name -match $Name }

			if (-not $_RackCol)
			{

				$ExceptionMessage = 'The "{0}" rack member was not found in {1}.  Please check the name and try again.' -f $Name, $InputObject.name
				$ErrorRecord = New-ErrorRecord HPOneView.ResourceNotFoundException ObjectNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

		}

		$_RackCol

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
