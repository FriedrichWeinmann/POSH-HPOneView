function Disable-HPOVRemoteSupport
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = "default")]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Switch]$Async,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		
		if (-not $PSBoundParameters['InputObject'])
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

				For ([int]$c = 0; $c -gt $ApplianceConnection.Count; $c++) 
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

		$_TaskCollection = New-Object System.Collections.ArrayList
		$_Collection     = New-Object System.Collections.ArrayList
		
	}

	Process
	{

		$_PatchOperation       = NewObject -PatchOperation
		$_PatchOperation.op    = 'replace'
		$_PatchOperation.path  = '/supportEnabled'
		$_PatchOperation.value = $false

		switch ($InputObject.category)
		{

			'server-hardware'
			{

				$_uri = '{0}/{1}' -f $RemoteSupportComputeSettingsUri, $InputObject.uuid

			}

			'enclosures'
			{

				$_uri = '{0}/{1}' -f $RemoteSupportEnclosureSettingsUri,$InputObject.uuid

			}

			default
			{

				# Unsupported
				$ExceptionMessage = 'The {0} input object is an unsupported resource category type, "{1}".  Only "server-hardware" or "enclosure" resources are supported.' -f $InputObject.category, $InputObject.name 
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.RemoteSupportResourceException InvalidResourceObject InvalidArgument "InputObject" -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}
			
		}

		try
		{

			$_Resp = Send-HPOVRequest -Uri $_uri -Method PATCH -Body $_PatchOperation -Hostname $ApplianceConnection

		}

		catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if ($PSBoundParameters['Async'])
		{

			$_Resp

		}

		else
		{

			Try
			{

				$_Resp | Wait-HPOVTaskComplete

			}

			Catch
			{

				$PSCmdlet.ThrowTerninatingError($_)

			}

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
