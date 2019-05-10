function Set-HPOVStorageVolumeTemplatePolicy 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding ()]
	Param 
	(
	
		[Parameter (Mandatory, ParameterSetName = "Enable")]
		[switch]$Enable,
			  
		[Parameter (Mandatory, ParameterSetName = "Disable")]
		[switch]$Disable,

		[Parameter (Mandatory = $False, ParameterSetName = "Enable")]
		[Parameter (Mandatory = $False, ParameterSetName = "Disable")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

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

		$_SVTPolicyCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '$($_appliance.Name)' Appliance Connection [of $($ApplianceConnection.Count)]" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_request = NewObject -GlobalSetting

			$_request.name = 'StorageVolumeTemplateRequired'

			switch ($PSCmdlet.ParameterSetName) 
			{

				'Enable' 
				{

					"[{0}] User requested to ENABLE the policy" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_request.value = 'true'

				}

				'Disable' 
				{
					
					"[{0}] User requested to DISABLE the policy" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					$_request.value = 'false'
			
				}

			}

			try
			{

				$_updatedpolicy = Send-HPOVRequest -Uri $applStorageVolumeTemplateRequiredPolicy -Method PUT -Body $_request -Hostname $_appliance 

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_updatedpolicy.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.GlobalSetting')

			[void]$_SVTPolicyCollection.Add($_updatedpolicy)

		}
		
	}

	End 
	{

		Return $_SVTPolicyCollection

	}

}
