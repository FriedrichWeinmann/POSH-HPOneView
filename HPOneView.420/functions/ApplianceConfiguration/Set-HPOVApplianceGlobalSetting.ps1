function Set-HPOVApplianceGlobalSetting 
{

   # .ExternalHelp HPOneView.420.psm1-help.xml
	  
	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Pipeline')]
		[Alias ('Object')]
		[ValidateNotNullorEmpty()]
		[HPOneView.Appliance.GlobalSetting]$InputObject,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[string]$Name,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[string]$Value,

		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName, ParameterSetName = 'Pipeline')]
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

		if ($PSCmdlet.ParameterSetName -eq 'Pipeline')
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

		$_ApplianceGlobalSettingCol = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput)
		{


			"[{0}] Processing object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject | Write-Verbose

			Try
			{

				$_UpdatedGlobalSetting = NewObject -GlobalSetting
				$_UpdatedGlobalSetting.name = $InputObject.Name
				$_UpdatedGlobalSetting.value = $Value

				"[{0}] Updated Global Setting: {1} -> {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.Name, $Value | Write-Verbose

				$_results = Send-HPOVRequest -Uri $Object.Uri -Method PUT -Body $_UpdatedGlobalSetting -Hostname $Object.ApplianceConnection

				New-Object HPOneView.Appliance.GlobalSetting ($_results.name,
															  $_results.value,
															  $_results.etag,
															  $_results.created,
															  $_results.modified,
															  $_results.group,
															  $_results.settingCategory,
															  $_results.uri,
															  $_results.applianceConnection)

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		else
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

				"[{0}] Getting current global setting value for $Name" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_setting = Get-HPOVApplianceGlobalSetting -Name $Name -ApplianceConnection $_appliance -ErrorAction Stop 

					$_UpdatedGlobalSetting = NewObject -GlobalSetting
					$_UpdatedGlobalSetting.name = $Name
					$_UpdatedGlobalSetting.value = $Value

					"[{0}] Updated Global Setting: {1} -> {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name, $Value | Write-Verbose

					$_results = Send-HPOVRequest -Uti $_setting.Uri -Method PUT -Body $_UpdatedGlobalSetting -Hostname $_appliance

					New-Object HPOneView.Appliance.GlobalSetting ($_results.name,
																  $_results.value,
																  $_results.etag,
																  $_results.created,
																  $_results.modified,
																  $_results.group,
																  $_results.settingCategory,
																  $_results.uri,
																  $_results.applianceConnection)

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				
			}

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
