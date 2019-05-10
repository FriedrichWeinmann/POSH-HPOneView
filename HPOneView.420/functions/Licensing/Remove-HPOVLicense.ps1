function Remove-HPOVLicense 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('uri', 'name', 'license','Resource')]
		[HPOneView.Appliance.License]$InputObject,
	
		[Parameter (Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['Resource'])) 
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

		$_ResponseCollection = New-Object System.Collections.ArrayList
		$_LicenseCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput)
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		if ($null -ne $InputObject)
		{

			if ($InputObject -is [HPOneView.Appliance.License])
			{

				if (-not $InputObject.ApplianceConnection)
				{

					$ExceptionMessage = "The License resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				if ($PSCmdlet.ShouldProcess($InputObject.product, ("remove license from appliance {0}" -f $InputObject.ApplianceConnection)))
				{    

					"[{0}] Removing License '{1}' [{2}]; URI: {3}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.Product, $InputObject.Description, $InputObject.Uri | Write-Verbose

					try
					{

						Send-HPOVRequest -Uri $InputObject.uri -Method DELETE -Hostname $InputObject.ApplianceConnection

					}

					catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				elseif ($PSBoundParameters['whatif']) 
				{ 
							
					"[{0}] User provided -WhatIf parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

				else 
				{

					"[{0}] User cancelled." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

			}

			else
			{

				$ExceptionMessage = "The License resource is not an expected category type [{0}].  Allowed resource category types is '[HPOneView.Library.License'.  Please check the object provided and try again." -f $InputObject.Getype().FullName
				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}


	}

	End 
	{

		
	}

}
