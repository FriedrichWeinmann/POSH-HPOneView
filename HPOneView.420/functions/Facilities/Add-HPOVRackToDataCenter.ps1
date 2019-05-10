function Add-HPOVRackToDataCenter
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
		[Object]$DataCenter,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Int]$X,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Int]$Y,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Switch]$Millimeters,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateRange(0,360)]
		[Int]$Rotate = 0,

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

		if ($InputObject.category -ne 'racks')
		{

			$ExceptionMessage = 'The InputObject is not a valid Rack object.'
			$ErrorRecord = New-ErrorRecord HPOneview.RackResourceException InvalidParameter InvalidArgument 'InputObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($DataCenter.category -ne 'datacenters')
		{

			$ExceptionMessage = 'The DataCenter is not a valid data center object.'
			$ErrorRecord = New-ErrorRecord HPOneview.DatacenterResourceException InvalidParameter InvalidArgument 'DataCenter' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Get the most current version of the object
		Try
		{

			$DataCenter = Send-HPOVRequest -Uri $DataCenter.uri -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$_DataCenterToUpdate = $DataCenter.PSObject.Copy()

		$_UpdatedAssociations = $_DataCenterToUpdate.contents
		
		$_DataCenterToUpdate.contents = New-Object System.Collections.ArrayList
		$_UpdatedAssociations | ForEach-Object { [void]$_DataCenterToUpdate.contents.Add($_) }

		if (-not $Millimeters.IsPresent)
		{

			# Convert from Feet to Millimeters
			$X = [Math]::Round([int]$X * .3048 * 1000, 2)
			$Y = [Math]::Round([int]$Y * .3048 * 1000, 2)

		}		

		$_NewDCItem = NewObject -DataCenterItem
		$_NewDCItem.resourceUri = $InputObject.uri
		$_NewDCItem.rotation    = $Rotate
		$_NewDCItem.x           = $X
		$_NewDCItem.y           = $y

		[void]$_DataCenterToUpdate.contents.Add($_NewDCItem)

		Try
		{

			Send-HPOVRequest -Uri $DataCenter.uri -Method PUT -Body ($_DataCenterToUpdate | Select-Object * -Exclude RemoteSupportLocation) -Hostname $ApplianceConnection

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
