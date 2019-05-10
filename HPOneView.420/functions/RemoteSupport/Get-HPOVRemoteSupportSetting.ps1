function Get-HPOVRemoteSupportSetting
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

   	[CmdletBinding (DefaultParameterSetName = "Default" )]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
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

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not $PSBoundParameters['InputObject'])
		{

			$PipelineInput = $true

		}

		else
		{

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

	}

	Process 
	{

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

		Try
		{

			$_ResourceRemoteSupportSettings = Send-HPOVRequest -uri $_uri -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$_ResourceRemoteSupportSettings | Add-Member -NotePropertyName ResourceName -NotePropertyValue $InputObject.name
		$_ResourceRemoteSupportSettings | Add-Member -NotePropertyName ResourceType -NotePropertyValue $InputObject.category

		ForEach ($_EnumKey in $RemoteSupportResourceSettingEnum.GetEnumerator())
		{

			$_Setting    = $null
			$EnumKeyName = $_EnumKey.Name
			$Uri         = $_ResourceRemoteSupportSettings.$EnumKeyName

			if ($Uri)
			{

				'Processing: {0}' -f $Uri, $EnumKeyName | Write-Verbose

				Try
				{

					$_Setting = Send-HPOVRequest -Uri $Uri -Hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			else
			{

				'{0} contains a null value.' -f $EnumKeyName | Write-Verbose

			}		
			
			$_ResourceRemoteSupportSettings | Add-Member -NotePropertyName $_EnumKey.Value -NotePropertyValue $_Setting

		}

		$_ResourceRemoteSupportSettings.PSObject.TypeNames.Insert(0,'HPOneView.RemoteSupport.ResourceSetting')

		$_ResourceRemoteSupportSettings

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
