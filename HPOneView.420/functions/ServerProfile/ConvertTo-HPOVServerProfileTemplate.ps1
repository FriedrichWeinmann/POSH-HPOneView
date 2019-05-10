function ConvertTo-HPOVServerProfileTemplate
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(
	
		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ("source",'ServerProfile')]
		[Object]$InputObject,

		[Parameter (Mandatory = $False)] 
		[String]$Name,

		[Parameter (Mandatory = $False)] 
		[String]$Description,

		[Parameter (Mandatory = $False)] 
		[Switch]$Async,

		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName)]
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

		# Process Pipeline Input here
		if ($InputObject -is [PSCustomObject])
		{

			"[{0}] Received Server Profile object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

			$_ProfileToConvert = $InputObject.PSObject.Copy()
			$_SourceName       = $InputObject.name.Clone()

		}

		# Process everything else
		else
		{

			"[{0}] Received Server Profile name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

			Try
			{

				$_ProfileToConvert = Get-HPOVServerProfile -Name $InputObject -ErrorAction Stop
				$_SourceName       = $InputObject.Clone()

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
		}

		# Generate SPT from API
		try
		{

			$_uri = '{0}/new-profile-template' -f $_ProfileToConvert.uri

			$_ConvertedSPT = Send-HPOVRequest -Uri $_uri -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if ($PSBoundParameters['Name'])
		{

			$_ConvertedSPT.name = $Name

		}

		else
		{

			$_ConvertedSPT.name = "Temporary Name - {0}" -f $_SourceName
		
		}

		if ($PSBoundParameters['Description'])
		{

			$_ConvertedSPT.description = $Description

		}

		else
		{

			$_ConvertedSPT.description = "Created from '{0}' source Server Profile." -f $_SourceName

		}

		try
		{

			$_uri = '{0}/new-profile-template' -f $_ProfileToConvert.uri

			$_result = Send-HPOVRequest -Uri $ServerProfileTemplatesUri -Method POST -Body $_ConvertedSPT -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not $PSBoundParameters['Async'])
		{

			$_result | Wait-HPOVTaskComplete

		}

		else
		{

			$_result

		}				

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
