Function Add-HPOVResourceToRack
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	  
	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Object]$Rack,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Int]$ULocation,

		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $InputObject)
		{

			$PipelineInput - $True

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

		$_Collection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($Rack.category -ne 'racks')
		{

			$ExceptionMessage = 'The Rack is not a valid Rack object.'
			$ErrorRecord = New-ErrorRecord HPOneview.RackResourceException InvalidParameter InvalidArgument 'Rack' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Get the most current version of the object
		Try
		{

			$Rack = Send-HPOVRequest -Uri $Rack.uri -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		switch ($InputObject.category)
		{

			'server-hardware'
			{

				$_RelativeOrder = 0
				[int]$_UHeight = $InputObject.formFactor.Replace('U',$null)

			}

			'unmanaged-devices'
			{

				$_RelativeOrder = 0
				[int]$_UHeight = $InputObject.height

			}

			'enclosures'
			{

				$_RelativeOrder = -1
				[int]$_UHeight = 10

			}

			# Unsupported type
			default
			{

				$ExceptionMessage = 'The resource {0} you are attempting to associate with the Rack {1} is not a supported object.' -f $InputObject.name, $Rack.name
				$ErrorRecord = New-ErrorRecord HPOneView.RackResourceException InvalidParameter InvalidArgument 'InputObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		if (($ULocation + $_UHeight - 1) -le 0)
		{

			$ExceptionMessage = 'The resource {0} you are attempting to associate with the Rack {1} at {2} U location is not valid.  The device is {3} Rack Units in size and cannot fit at {2} U rack position.' -f $InputObject.name, $Rack.name, $_UHeight, $ULocation
			$ErrorRecord = New-ErrorRecord HPOneView.RackResourceException InvalidParameter InvalidArgument 'Rack' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_RackItem = NewObject -RackItem
		$_RackItem.mountUri      = $InputObject.uri
		$_RackItem.relativeOrder = $_RelativeOrder
		$_RackItem.topUSlot      = $ULocation + $_UHeight - 1
		$_RackItem.uHeight       = $_UHeight

		$_OriginalRackContents = [Array]$Rack.rackMounts.Clone()
		$Rack.rackMounts = New-Object System.Collections.ArrayList

		$_OriginalRackContents | ForEach-Object { [void]$Rack.rackMounts.Add($_) }
		[void]$Rack.rackMounts.Add($_RackItem)

		Try
		{

			Send-HPOVRequest -Uri $Rack.uri -Method PUT -Body $Rack -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
