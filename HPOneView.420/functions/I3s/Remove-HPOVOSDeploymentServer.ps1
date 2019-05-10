function Remove-HPOVOSDeploymentServer
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Switch]$Force,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = ($ConnectedSessions | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $PSBoundParameters['InputObject'])
		{

			$PipelineInput = $true

		}

		else
		{

			"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if (-not($ApplianceConnection) -and -not($ConnectedSessions))
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

		if ($PipelineInput)
		{

			$ApplianceConnection = $ConnectedSessions | Where-Object Name -eq $ApplianceConnection.Name

		}

		If ($ApplianceConnection.ApplianceType -ne 'Composer')
		{

			$ExceptionMessage = 'The ApplianceConnection {0} ({1}) is not a Synergy Composer.  This Cmdlet only support Synergy Composer management appliances.' -f $ApplianceConnection.Name, $ApplianceConnection.ApplianceType
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Validate InputObject
		if ($InputObject.category -ne 'deployment-managers')
		{

			$ExceptionMessage = 'The InputObject is not a valid OS Deployment Server resource.' -f $InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ImageStreamerManagementNetworkException InvalidInputObject InvalidArgument 'InputObject' -Message $ExceptionMessage
			$PSCmdlet.WriteError($ErrorRecord)

		}

		elseif ($PSCmdlet.ShouldProcess($InputObject.ApplianceConnection.Name, ("Remove OS Deployment Server from appliance '{0}'" -f $InputObject.name))) 
		{

			"[{0}] Remove OS Deployment Server '{1}' from appliance '{2}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.ApplianceConnection.Name | Write-Verbose

			$Uri = $InputObject.Uri

			if ($Force)
			{

				$Uri += '?force=true'

			}

			Try
			{

				$_resp = Send-HPOVRequest -Uri $Uri -Method DELETE -Hostname $InputObject.ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if (-not $PSBoundParameters['Async'])
			{

				$_resp | Wait-HPOVTaskComplete

			}

			else
			{

				$_resp

			}

		}

		elseif ($PSBoundParameters['WhatIf'])
		{

			"[{0}] WhatIf Parameter was passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
