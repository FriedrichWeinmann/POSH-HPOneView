function Set-HPOVDataCenterRemoteSupport
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Object]$PrimaryContact,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Object]$SecondaryContact,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Address1,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Address2,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$City,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$State,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$PostCode,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Country,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$TimeZone,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
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

		$_ApplianceRemoteSupportCol = New-Object System.Collections.ArrayList

	}

	Process
	{

		if ($InputObject -is [PSCustomObject]) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Remote Support Contact Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

			If ('datacenters' -contains $InputObject.category)
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord HPOneView.DataCenterResourceException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message "The InputObject object resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			else
			{

				$ErrorRecord = New-ErrorRecord HPOneView.DataCenterResourceException InvalidArgumentValue InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message "The InputObject object resource is not an expected type.  The allowed resource category type is 'DataCenters'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else
		{

			Try
			{

				$InputObject = Get-HPOVDataCenter -Name $InputObject -ApplianceConnection $ApplianceConnection -ErrorAction Stop

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		$RemoteSupportStatus = $null

		"[{0}] Validate Remote Support is configured on the appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Try
		{

			$RemoteSupportStatus = Send-HPOVRequest -Uri $RemoteSupportConfigUri -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not $RemoteSupportStatus.enableRemoteSupport)
		{

			"[{0}] Remote Support is not enabled and configured on the appliance. Generate non-terminating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$ExceptionMessage = 'Remote Support is not configured on the appliance, {0}.  In order to set the Remote Support location for the DataCenter, Remote SUpport must be enabledon the appliance.  Either enable Remote Support or do not attempt to set the Data Center location until Remote Support has been anabled on the appliance.' -f $ApplianceConnection.Name
			$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportException RemoteSupportNotEnabled InvalidOperation 'ApplianceConnect' -Message $ExceptionMessage
			$PSCmdlet.WriteError($ErrorRecord)

		}

		else
		{

			"[{0}] Remote Support is enabled and configured on the appliance. Will set Data Center RS location." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_DataCenterAddressPatchOp = New-Object System.Collections.ArrayList

			switch ($PSBoundParameters.Keys)
			{

				'Address1'
				{

					$_PatchOperation = NewObject -PatchOperation
					$_PatchOperation.op    = 'replace'
					$_PatchOperation.path  = '/streetAddress1'
					$_PatchOperation.value = $Address1

					[void]$_DataCenterAddressPatchOp.Add($_PatchOperation)

				}

				'Address2'
				{

					$_PatchOperation = NewObject -PatchOperation
					$_PatchOperation.op    = 'replace'
					$_PatchOperation.path  = '/streetAddress2'
					$_PatchOperation.value = $Address2

					[void]$_DataCenterAddressPatchOp.Add($_PatchOperation)

				}

				'City'
				{

					$_PatchOperation = NewObject -PatchOperation
					$_PatchOperation.op    = 'replace'
					$_PatchOperation.path  = '/city'
					$_PatchOperation.value = $City

					[void]$_DataCenterAddressPatchOp.Add($_PatchOperation)

				}

				'State'
				{

					$_PatchOperation = NewObject -PatchOperation
					$_PatchOperation.op    = 'replace'
					$_PatchOperation.path  = '/provinceState'
					$_PatchOperation.value = $State

					[void]$_DataCenterAddressPatchOp.Add($_PatchOperation)

				}

				'PostCode'
				{

					$_PatchOperation = NewObject -PatchOperation
					$_PatchOperation.op    = 'replace'
					$_PatchOperation.path  = '/postalCode'
					$_PatchOperation.value = $PostCode

					[void]$_DataCenterAddressPatchOp.Add($_PatchOperation)

				}

				'Country'
				{

					$_PatchOperation = NewObject -PatchOperation
					$_PatchOperation.op    = 'replace'
					$_PatchOperation.path  = '/countryCode'
					$_PatchOperation.value = $Country

					[void]$_DataCenterAddressPatchOp.Add($_PatchOperation)

				}

				'TimeZone'
				{

					$_PatchOperation = NewObject -PatchOperation
					$_PatchOperation.op    = 'replace'
					$_PatchOperation.path  = '/timeZone'
					$_PatchOperation.value = $TimeZone

					[void]$_DataCenterAddressPatchOp.Add($_PatchOperation)

				}

				'PrimaryContact'
				{

					if ($PrimaryContact.Type -ne 'Contact')
					{

						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportContactException InvalidArgumentValue InvalidArgument "PrimaryContact" -TargetType PSObject -Message "The PrimaryContact object resource provided is not a Remote Support Contact.  Please use the Get-HPOVRemoteSupportContact Cmdlet to get a valid contact object."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					$_PatchOperation = NewObject -PatchOperation
					$_PatchOperation.op    = 'replace'
					$_PatchOperation.path  = '/primaryContactUri'
					$_PatchOperation.value = $PrimaryContact.uri

					[void]$_DataCenterAddressPatchOp.Add($_PatchOperation)

				}

				'SecondaryContact'
				{

					if ($SecondaryContact.Type -ne 'Contact')
					{

						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportContactException InvalidArgumentValue InvalidArgument "SecondaryContact" -TargetType PSObject -Message "The SecondaryContact object resource provided is not a Remote Support Contact.  Please use the Get-HPOVRemoteSupportContact Cmdlet to get a valid contact object."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					$_PatchOperation = NewObject -PatchOperation
					$_PatchOperation.op    = 'replace'
					$_PatchOperation.path  = '/secondaryContactUri'
					$_PatchOperation.value = $SecondaryContact.uri

					[void]$_DataCenterAddressPatchOp.Add($_PatchOperation)

				}

			}

			if (($PSBoundParameters['PrimaryContact'] -or $PSBoundParameters['SecondaryContact']) -and $PrimaryContact.uri -eq $SecondaryContact.uri)
			{

				"[{0}] Primary and Secondary Contact are the same.  Must be unique; generating terminating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ExceptionMessage =  "Both the PrimaryContact and SecondaryContact objects are the same.  Please specify unique Primary and Secondary contacts." 
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportContactException InvalidArgumentValue InvalidArgument "PrimaryContact" -TargetType PSObject -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		# Update Remote Support DC if needed
		if ($_DataCenterAddressPatchOp.Count -gt 0)
		{

			"[{0}] Modifying datacenter Remote Support location to the specified value." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_UpdateDCLocationResults = Send-HPOVRequest -Uri $InputObject.remoteSupportUri -Method PATCH -Body $_DataCenterAddressPatchOp -Hostname $ApplianceConnection

				if (-not $Async.IsPresent)
				{

					$_UpdateDCLocationResults = $_UpdateDCLocationResults | Wait-HPOVTaskComplete

					if ($_UpdateDCLocationResults.taskState -ne 'Completed')
					{

						$ExceptionMessage = 'Updating the datacenter with the specified location did not complete successfully with: {0}' -f [String]::Join(' ', $_UpdateDCLocationResults.taskErrors)
						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportException InvalidOperation InvalidOperation 'ApplianceConnect' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				$_UpdateDCLocationResults

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		else
		{

			"[{0}] Nothing to do." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
