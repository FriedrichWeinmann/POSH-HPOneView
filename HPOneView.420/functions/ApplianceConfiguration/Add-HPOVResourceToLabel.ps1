function Add-HPOVResourceToLabel
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param
	(

		[Parameter (Mandatory)]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
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

		ForEach ($_Resource in $InputObject)
		{

			"[{0}] Processing Label: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

			Try
			{

				$ExistingLabels = Send-HPOVRequest -Uri ('{0}/{1}' -f $LabelsResourcesBaseUri, $_Resource.uri) -Hostname $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
			# Label already exists.  Generate non-terminating error?
			if ($Name -contains $ExistingLabels.labels)
			{

				"[{0}] Resource {1} is already associated with {2} label ({3})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Resource.name, $Name, [String]::Join($ExistingLabels.labels, ', ') | Write-Verbose

				Write-Warning "Resource is already associated with label."

			}

			else
			{

				if ($ExistingLabels.labels.count -gt 0)
				{

					"[{0}] Appending {1} label to resource {2} association." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name, $_Resource.name | Write-Verbose				

					[Array]$ExistingLabels.labels += $Name

				}

				else
				{

					"[{0}] Associating {1} label to resource {2}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name, $_Resource.name | Write-Verbose

					[Array]$ExistingLabels.labels = $Name

				}

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

	}

	End
	{

		'[{0}] Done.' | Write-Verbose

	}	

}
