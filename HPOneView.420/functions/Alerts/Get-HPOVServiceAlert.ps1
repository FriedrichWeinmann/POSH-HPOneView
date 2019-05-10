function Get-HPOVServiceAlert
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param
	(

		[Parameter (Mandatory = $False, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[ValidateSet ('Open', 'Closed', 'Pending', 'Received', 'Submitted', 'Error')]
		[String]$State,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Int]$Count = 0,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[TimeSpan]$TimeSpan,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[DateTime]$Start,
		
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[DateTime]$End = [DateTime]::Now,
		
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($PSCmdlet.ParameterSetName -eq 'ResourcePipeline') 
		{ 
			
			$Pipelineinput = $True 
		
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
		
		$_AlertResources = New-Object System.Collections.ArrayList

		if (-not $Count)
		{

			$Count = -1

		}

	}
	
	Process 
	{

		$_uri = "{0}?sort:asc" -f $IndexUri

		$_Query = New-Object System.Collections.ArrayList
		[void]$_Query.Add("category:alerts AND healthCategory:RemoteSupport AND ServiceEventSource:True AND NOT description:'Service Test Event'")

		If ($Pipelineinput -or $InputObject -is [PSCustomObject])
		{

			"[{0}] Processing InputObject from pipeline: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Pipelineinput | Write-Verbose

			# Check what type of resource is being provided
			switch ($InputObject.category)
			{

				{ $ResourceCategoryEnum.ServerHardware, $ResourceCategoryEnum.Enclosure -contains $_ }
				{

					"[{0}] Processing '{1}' resource." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ | Write-Verbose

					if (-not (ValidateRemoteSupport -InputObject $InputObject))
					{

						$ExceptionMessage = "The resource {0} is not configured for Remote Support or does not support Remote Support." -f $InputObject.Name
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.RemoteSupportResourceException InvalidResourceObject InvalidArgument "InputObject" -TargetType 'PSObject' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					else
					{

						"[{0}] Remote Support is enabled." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ | Write-Verbose

					}

					[void]$_Query.Add(("resourceUri:'{0}'" -f $InputObject.uri))

				}

				$ResourceCategoryEnum.ServerProfile
				{

					"[{0}] Processing '{1}' resource." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ | Write-Verbose

					if (-not (ValidateRemoteSupport -InputObject $InputObject))
					{

						$ExceptionMessage = "The resource {0} is not configured for Remote Support or does not support Remote Support." -f $InputObject.Name
						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.RemoteSupportResourceException InvalidResourceObject InvalidArgument "InputObject" -TargetType 'PSObject' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					else
					{

						"[{0}] Remote Support is enabled." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ | Write-Verbose

					}

					if ($null -eq $InputObject.serverHardwareUri)
					{

						$ExceptionMessage = 'The provided server profile object {0} is not assigned to a server hardware resource.' -f $InputObject.name
						$ErrorRecord = New-ErrorRecord HPOneview.InputObjectResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType 'PSObject' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					[void]$_Query.Add(("resourceUri:'{0}'" -f $InputObject.serverHardwareUri))

				}

				default
				{

					$ExceptionMessage = 'The provided object {0} is not supported.  Only Server Hardware, Server Profile and Enclosure are supported resources.' -f $InputObject.name
					$ErrorRecord = New-ErrorRecord HPOneview.InputObjectResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			# Generate error if ApplianceConnection properties do not match
			if ($InputObject -and $InputObject.ApplianceConnection.Name -ne $ApplianceConnection.Name)
			{

				$ExceptionMessage = "The provided input object '{0}' 'ApplianceConnection' NoteProperty ({1}) does notmatch the Appliance Connection." -f $InputObject.ApplianceConnection, $ApplianceConnection
				$ErrorRecord = New-ErrorRecord HPOneView.InputObjectResourceException ApplianceConnetionDoesNotMatchObject InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		if ($PSBoundParameters['Count'])
		{

			$_uri = "{0}&count={1}" -f $_uri, $Count

		}

		# Needs to be a filter statement in URI.  NEED TO ADD TO GET-HPOVALERT FOR ITS TIMESPAN PARAMETER
		if ($TimeSpan)
		{

			$_uri = '{0}&filter="created > {1}"' -f $_uri, ([DateTime]::Now - $timespan).ToString("yyyy-MM-ddTHH:mm:ss:ff.fffZ")

		}

		elseif ($Start)
		{

			$_uri = '{0}&filter="created > {1}"&filter="created < {2}"' -f $_uri, $Start.ToString("yyyy-MM-ddTHH:mm:ss:ff.fffZ"), $End.ToString("yyyy-MM-ddTHH:mm:ss:ff.fffZ")

		}
	
		if ($PSBoundParameters['State']) 
		{ 

			[void]$_Query.Add(("remoteSupportState:{0}" -f $State))

		}

		$_uri = '{0}&query="{1}"' -f $_uri, [String]::Join(' AND ',$_Query.ToArray())

		"[{0}] URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_uri | Write-Verbose

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			# Check if the appliance has remote support enabled. Exception if not.
			$_RemoteSupportStatus = $null

			"[{0}] Validate Remote Support is configured on the appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_RemoteSupportStatus = Send-HPOVRequest -Uri $RemoteSupportConfigUri -Hostname $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if (-not $_RemoteSupportStatus.enableRemoteSupport)
			{

				"[{0}] Remote Support is not enabled and configured on the appliance. Generate non-terminating error." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ExceptionMessage = 'Remote Support is not configured on the appliance, {0}.  In order to set the Remote Support location for the DataCenter, Remote SUpport must be enabledon the appliance.  Either enable Remote Support or do not attempt to set the Data Center location until Remote Support has been anabled on the appliance.' -f $ApplianceConnection.Name
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportException RemoteSupportNotEnabled InvalidOperation 'ApplianceConnect' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Try
			{

				$_ResourceAlerts = Get-AllIndexResources -Uri $_uri -ApplianceConnection $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			ForEach ($_alert in $_ResourceAlerts)
			{

				# Get resource serial number to add to object
				Try
				{

					$_associatedresource = Send-HPOVRequest -Uri $_alert.associatedResource.resourceUri -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				New-Object HPOneView.Appliance.ServiceAlert($_alert.serviceEventDetails.caseID,
															$_alert.associatedResource.resourceName,
															$_associatedresource.serialNumber,
															$_alert.serviceEventDetails.remoteSupportState,
															$_alert.description,
															$_alert.correctiveAction,
															$_alert.created,
															$_alert.modified,
															$_alert.resourceUri,
															$_alert.uri,
															$_alert.ApplianceConnection)

			}

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
