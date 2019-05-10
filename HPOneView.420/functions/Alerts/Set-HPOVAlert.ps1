function Set-HPOVAlert
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Cleared')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Active')]
		[ValidateNotNullOrEmpty()]
		[Alias ('alertUri','Alert')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[string]$AssignToUser,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Notes,

		[Parameter (Mandatory, ParameterSetName = 'Cleared')]
		[switch]$Cleared,

		[Parameter (Mandatory, ParameterSetName = 'Active')]
		[switch]$Active,

		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = 'Cleared')]
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = 'Active')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject'])) 
		{ 
			
			"[{0}] Alert Object via pipeline" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

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

	}

	Process 
	{

		# Validate input object is correct
		if ($InputObject.category -ne 'alerts')
		{

			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidAlertObject InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message 'The Alert Parameter value is not a PSCustomObject or contains a valid resource category.  Please check the value and try again.'
			$PSCmdlet.WriteError($ErrorRecord)

		}

		else
		{

			$_AlertUpdateObject = NewObject -UpdateAlert

			if (-not $PSBoundParameters['Notes'])
			{

				$_AlertUpdateObject.notes = 'Updated alert with: {0}' -f (($PSBoundParameters.Keys | Where-Object { 'Cleared','Active','AssignToUser' -contains $_ } | ForEach-Object { "{0} ({1})" -f $_,$PSBoundParameters[$_] } )-Join ", ")

			}

			switch ($PSBoundParameters.keys)
			{

				'Cleared'
				{

					$_AlertUpdateObject.alertState = 'Cleared'

				}

				'Active'
				{

					$_AlertUpdateObject.alertState = 'Active'

				}

				'AssignToUser'
				{

					$_AlertUpdateObject.assignedToUser = $AssignToUser

				}

				'Notes'
				{
				
					$_AlertUpdateObject.notes = $Notes
				
				}

			}

			if ((-not $PSboundParameters['Cleared']) -and (-not $PSboundParameters['Active']))
			{

				$_AlertUpdateObject.alertState = $InputObject.alertState

			}

			if (-not($InputObject.ApplianceConnection.Name) -and -not($ApplianceConnection))
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidAlertObject InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message 'The Alert Parameter value does not contain a valid ApplianceConnection property.  Please check the value and try again.'
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if ($InputObject.alertState -eq 'Locked' -and ($PSboundParameters['Cleared'] -or $PSboundParameters['Active']))
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidAlertState InvalidOperation 'InputObject' -TargetType $InputObject.GetType().Name -Message "The Alert provided is a Locked alert and it's state cannot be modified."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Try
			{

				if ($InputObject.eTag)
				{

					$_AlertUpdateObject.eTag = $InputObject.eTag

				}

				$_resp = Send-HPOVRequest $InputObject.uri PUT $_AlertUpdateObject -Hostname $ApplianceConnection.Name
			
				$_resp.PSObject.TypeNames.Insert(0,"HPOneView.Alert")

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}        

			[void]$_AlertResources.Add($_resp)

		}

	}

	End
	{        

		return $_AlertResources

	}

}
