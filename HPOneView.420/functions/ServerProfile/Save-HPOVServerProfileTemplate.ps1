function Save-HPOVServerProfileTemplate
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		# Server Profile resource
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		If (-not $PSBoundParameters['InputObject'])
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

	}

	Process
	{

		if ($InputObject.category -ne $ResourceCategoryEnum.ServerProfileTemplate)
		{

			$ExceptionMessage = 'The provided object {0} is not supported.  Only Server Profile Template are supported resources.' -f $InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneview.InputObjectResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		"[{0}] Attempting to save '{1}' Server Profile Template resource." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

		$_method = "PUT"

		# If eTag property is null, then this profile needs to be created.
		if (-not $InputObject.eTag)
		{

			$_method = "POST"

		}

		Try
		{

			$_Resp = Send-HPOVRequest -Uri $InputObject.uri -Method $_method -Body $InputObject -Hostname $InputObject.ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not $PSBoundParameters['Async'])
		{

			$_Resp | Wait-HPOVTaskComplete

		}

		else
		{

			$_Resp

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
