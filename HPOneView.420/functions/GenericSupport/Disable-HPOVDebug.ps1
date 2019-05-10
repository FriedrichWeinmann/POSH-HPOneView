function Disable-HPOVDebug 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param
	(

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[String]$Scope,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[String]$LoggerName,

		[Parameter (Mandatory = $false, ParameterSetName = "default", ValueFromPipelineByPropertyName)]
		[ValidateNotNullorEmpty()]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		[console]::WriteLine()
		Write-Warning "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		Write-Warning "!!! FOR HP SUPPORT USE ONLY. DO NOT USE UNLESS OTHERWISE INSTRUCTED TO BY HP SUPPORT !!!"
		Write-Warning "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		[console]::WriteLine() 

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

		$_debug = NewObject -ApplianceDebug

		$_debug.scope      = $Scope
		$_debug.loggerName = $LoggerName
		$_debug.level      = 'INFO'

		"[{0}] Setting '{1}' at '{2}:{3}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Level, $Scope, $LoggerName | Write-Verbose

		Try
		{

			$resp = Send-HPOVRequest $script:applianceDebugLogSetting POST $_debug -Hostname $ApplianceConnection

		}

		Catch
		{

			"Unable to set '{0}:{1}' to '{2}' logging level. Error '{3}'" -f $Scope, $LoggerName, $Level, $_.Exception.Message

			$PSCmdlet.ThrowTerminatingError($_)

		}

		"'{0}:{1}' successfully set to '{2}' on Appliance {3}" -f $Scope, $LoggerName, $Level, $ApplianceConnection.Name

	}

	End 
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
