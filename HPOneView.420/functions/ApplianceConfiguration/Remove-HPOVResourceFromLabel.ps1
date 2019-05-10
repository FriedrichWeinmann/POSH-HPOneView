function Remove-HPOVResourceFromLabel
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default', SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'RemoveAll')]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = 'RemoveAll')]
		[Switch]$RemoveAllLabelsFromResource,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'RemoveAll')]
		[Alias ('Appliance')]
		[ValidateNotNullOrEmpty()]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject'])) 
		{ 
			
			$PipelineInput = $True 
		
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

						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError $_connection -Message $_.Exception.Message -InnerException $_.Exception
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

		if ($InputObject -isnot [HPOneView.Appliance.Label])
		{

			"[{0}] Processing Label {1} for {2} resource." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name, $InputObject.name | Write-Verbose

			if ($PSCmdlet.ParameterSetName -eq 'RemoveAll')
			{

				if ($PSCmdlet.ShouldProcess($InputObject.name, 'remove resource from all associated labels'))
				{

					"[{0}] Removing {1} resource from all labels." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

					Try
					{

						$_Uri = '{0}{1}' -f $LabelsResourcesBaseUri, $InputObject.uri
						Send-HPOVRequest -Uri $_Uri -Method DELETE -Hostname $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				elseif ($PSBoundParameters['WhatIf'])
				{

					"[{0}] User specified -WhatIf" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

			}

			else
			{

				Try
				{

					$ExistingLabels = Send-HPOVRequest -Uri ('{0}/{1}' -f $LabelsResourcesBaseUri, $InputObject.uri) -Hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				"[{0}] Removing {1} label from resource {2} association." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name, $InputObject.name | Write-Verbose				

				[Array]$ExistingLabels.labels = $ExistingLabels.labels | Where-Object name -ne $Name

				Try
				{

					Send-HPOVRequest -Uri $ExistingLabels.uri -Method PUT -Body $ExistingLabels -Hostname $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

		}

		else
		{

			$_Message = "An invalid InputObject argument value type was provided, {0}.  Labels cannot be removed via the appliance API.  Labels are automatically removed when the last association to a resource is removed.  Please provide a resource object to remove the label association." -f $InputObject.name
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidCInputObjectParameterValue InvalidArgument 'InputObject' -TargetType "$($InputObject.GetType().Name)" -Message $_Message
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
