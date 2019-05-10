function Remove-HPOVAlert
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[switch]$Force,
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
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

			$RemoveMessage = "remove '{0}' alert" -f $InputObject.description

			if ($PSCmdlet.ShouldProcess($InputObject.ApplianceConnection.Name, $RemoveMessage))
			{

				"[{0}] Removing alert: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($InputObject | Out-String) | Write-Verbose
				"[{0}] URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.uri | Write-Verbose

				$_Uri = '{0}' -f $InputObject.uri

				if ($Force)
				{

					$_Uri += '?force=true'

				}

				try
				{

					Send-HPOVRequest -Uri $_Uri -Method DELETE -Hostname $InputObject.ApplianceConnection		

				}

				catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($PSBoundParameters['whatif']) 
			{

				"[{0}] -WhatIf was passed" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
		
			}

		}

	}

	End
	{        

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
