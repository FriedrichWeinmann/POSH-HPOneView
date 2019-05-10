function Enable-HPOVDeviceUid
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Server','Enclosure','Frame','Resource')]
		[Object]$InputObject,

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

		if (-not($PSBoundParameters['Resource']))
		{

			$PipelineInput = $True

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

		$_ResourceStatusCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		$_RequestCollection = New-Object System.Collections.ArrayList

		if ($PiplineInput)
		{

			"[{0}] Pipeline Input Received." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		if ($InputObject -isnot [PSCustomObject])
		{

			$Message = 'The -Resource Parameter value is not an Object.  Please use Get-HPOVServer or Get-HPOVEnclosure to provide an allowed resource object.'
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message $Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_PatchRequest = NewObject -PatchOperation

		"[{0}] Turning UID on for: {1} {{2}}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.category | Write-Verbose

		switch ($InputObject.category)
		{

			{'server-hardware', 'enclosures' -contains $_}
			{

				$_PatchRequest.op = 'replace'
				$_PatchRequest.path  = '/uidState'
				$_PatchRequest.value = 'On'

			}

			default
			{

				$Message = "The -Resource Parameter value is not a supported object, {0}.  This Cmdlet only supports 'server-hardware' or 'enclosures'.  Please use Get-HPOVServer or Get-HPOVEnclosure to provide an allowed resource object." -f $InputObject.category
				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message $Message
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		[void]$_RequestCollection.Add($_PatchRequest)

		Try
		{

			$_resp = Send-HPOVRequest $InputObject.uri PATCH $_RequestCollection -ApplianceConnection $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		[void]$_ResourceStatusCollection.Add($_resp)

	}

	End 
	{

		Return $_ResourceStatusCollection

	}

}
