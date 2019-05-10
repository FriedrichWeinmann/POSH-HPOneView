function Get-HPOVAlert 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param
	(

		[Parameter (Mandatory = $False, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('resourceUri','Resource')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[ValidateSet ('OK', 'Critical', 'Disabled', 'Warning', 'Unknown')]
		[string]$Severity,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[ValidateSet ('Appliance', 'DeviceBay', 'Enclosure', 'Fan', 'Firmware', 'Host', 'Instance', 'InterconnectBay', 'LogicalSwitch', 'Logs', 'ManagementProcessor', 'Memory', 'Network', 'Operational', 'Power', 'Processor', 'RemoteSupport', 'Storage', 'Thermal', 'Unknown')]
		[string]$HealthCategory,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[String]$AssignedToUser,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('State')]
		[ValidateNotNullOrEmpty()]
		[String]$AlertState,

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
		[void]$_Query.Add("category:alerts")

		If ($Pipelineinput -or $InputObject -is [PSCustomObject])
		{

			"[{0}] Processing InputObject from pipeline: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Pipelineinput | Write-Verbose

			# Check what type of resource is being provided
			switch ($InputObject.category)
			{

				{ $ResourceCategoryEnum.ServerHardware, `
					$ResourceCategoryEnum.Enclosure, `
					$ResourceCategoryEnum.ServerProfile, `
					$ResourceCategoryEnum.Interconnect -contains $_ }
				{

					"[{0}] Processing '{1}' resource." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ | Write-Verbose

					[void]$_Query.Add(("resourceUri:'{0}'" -f $InputObject.uri))

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
	
		if ($PSBoundParameters['Severity']) 
		{ 
			
			[Void]$_Query.Add(("severity='{0}'" -f $Severity))
		
		}
	
		if ($PSBoundParameters['HealthCategory']) 
		{
			
			[Void]$_Query.Add(("healthCategory:'{0}'" -f $HealthCategory))
		
		}
	
		if ($PSBoundParameters['AssignedToUser']) 
		{ 
			
			[Void]$_Query.Add(("Owner:'{0}'" -f $AssignedToUser))
		
		}
	
		if ($PSBoundParameters['AlertState']) 
		{ 
			
			[Void]$_Query.Add(("state='{0}'" -f ($AlertState.SubString(0,1).ToUpper() + $AlertState.SubString(1).tolower())))
		
		}

		$_uri = '{0}&query="{1}"' -f $_uri, [String]::Join(' AND ',$_Query.ToArray())

		"[{0}] URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_uri | Write-Verbose

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Try
			{

				$_ResourceAlerts = Get-AllIndexResources -Uri $_uri -ApplianceConnection $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
		
			$_ResourceAlerts | ForEach-Object { 
				
				$_.PSObject.TypeNames.Insert(0,"HPOneView.Alert")

				[void]$_AlertResources.Add($_)
			
			}

		}

	}

	End 
	{

		Return $_AlertResources

	}

}
