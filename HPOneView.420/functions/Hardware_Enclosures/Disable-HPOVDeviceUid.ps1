function Disable-HPOVDeviceUid
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

			Try 
			{
			
				$ApplianceConnection = Test-HPOVAuth $ApplianceConnection

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

		$_ResourceStatusCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($ApplianceConnection.ApplianceType -ne 'Composer')
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message ('The ApplianceConnection {0} is not a Synergy Composer.  This Cmdlet is only supported with Synergy Composers.' -f $ApplianceConnection.Name)
			$PSCmdlet.WriteError($ErrorRecord)

		}

		$_RequestCollection = New-Object System.Collections.ArrayList

		if ($PiplineInput)
		{

			"[{0}] Pipeline Input Received." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		if ($InputObject -isnot [PSCustomObject])
		{

			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgument InvalidArgument 'InputObject' -Message "InputObject is not a PSCustomObject."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_PatchRequest = NewObject -PatchOperation

		"[{0}] Turning UID OFF for: {1} {{2}}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.category | Write-Verbose

		switch ($InputObject.category)
		{

			{'server-hardware', 'enclosures' -contains $_}
			{

				$_PatchRequest.op = 'replace'
				$_PatchRequest.path  = '/uidState'
				$_PatchRequest.value = 'Off'

			}

			default
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidObjectCategory InvalidArgument 'InputObject' -Message "InputObject is not a supported object category.  Only 'server-hardware' or 'enclosures' Synergy resources are supported."
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
