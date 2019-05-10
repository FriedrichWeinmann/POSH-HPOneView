function Add-HPOVRemoteFrame
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[string]$Hostname,
		
		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[switch]$Async,
		
		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{
		
		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose
		
		$Caller = (Get-PSCallStack)[1].Command
		
		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose
		
		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		if (-not($ApplianceConnection -is [HPOneView.Appliance.Connection]) -and (-not($ApplianceConnection -is [System.String])))
		{
			
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException InvalidApplianceConnectionDataType InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter is not type [HPOneView.Appliance.Connection] or [System.String].  Please correct this value and try again.'
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
		
		}

		elseif  ($ApplianceConnection.Count -gt 1)
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException MultipleApplianceConnections InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter contains multiple Appliance Connections.  This CMDLET only supports 1 Appliance Connection in the ApplianceConnect Parameter value.  Please correct this and try again.'
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
		
		}

		else
		{

			Try 
			{

				$ApplianceConnection = Test-HPOVAuth $ApplianceConnection

			}

			Catch [HPOneview.Appliance.AuthSessionException] 
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError 'ApplianceConnection' -TargetType $ApplianceConnection.GetType().Name -Message $_.Exception.Message -InnerException $_.Exception
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

	}

	Process 
	{
		
		# Locate the Enclosure Group specified
		"[{0}] - Starting" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
		if (-not $Hostname.StartsWith('fe80:'))
		{

			$ExceptionMessage = 'The value provided for Hostname, {0}, is not a valid IPv6 Link Local Address.' -f $Hostname
			$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException InvalidIPv6LinkLocalAddress InvalidArgument 'Hostname' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_RemoteFrameAdd = @{hostname = $Hostname}

		"[{0}] - Sending request to claim remote frame: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Hostname | Write-Verbose
		
		Try
		{

			$resp = Send-HPOVRequest -uri $EnclosuresUri -Method POST -Body $_RemoteFrameAdd -Hostname $ApplianceConnection | Wait-HPOVTaskStart

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not $PSBoundParameters['Async'])
		{
			
			Try
			{

				$resp | Wait-HPOVTaskComplete

			}

			catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		else
		{

			$resp

		}	

	}

	End 
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
