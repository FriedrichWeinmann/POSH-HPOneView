function Start-HPOVEnclosureAppliance
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ("Encl")]
		[Object]$Enclosure,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[ValidateRange(1,2)]
		[int]$BayID,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose
		
		if (-not($PSBoundParameters['Enclosure'])) 
		{ 
			
			$PipelineInput = $True 
		
		}

		else
		{

			if ($Enclosure -isnot [PSCustomObject] -or ($Enclosure -is [PSCustomObject] -and $Enclosure.category -ne 'enclosures') -or ($Enclosure.model -notmatch 'Synergy'))
			{

				$Message = '{0} is an unsupported resource object ({1}).  This Cmdlet only supports Synergy Frame resource objects.' -f $Enclosure.name, $Enclosure.category
				$ErrorRecord = New-ErrorRecord HPOneview.EnclosureResourceException InvalidResoureObject InvalidArgument 'Enclosure' -Message $Message
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

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
		
		$_TaskCollection  = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		"[$($MyInvocation.InvocationName.ToString().ToUpper())] Processing Enclosure: {0}" -f $Enclosure.name | Write-Verbose

		if ($PipelineInput)
		{

			Try 
			{
			
				$ApplianceConnection = Test-HPOVAuth $Enclosure.ApplianceConnection

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

		Try
		{

			# Validate to make sure the Appliance bay is not already powered on.
			$Enclosure = Send-HPOVRequest $Enclosure.uri -ApplianceConnection $ApplianceConnection

			if (($Enclosure.applianceBays | Where-Object bayNumber -eq $BayID).poweredOn)
			{
			
				'Appliance Bay {0} in {1} Enclosure is already powered on.  Not Processing.' -f $BayID, $Enclosure.name | Write-Warning 
			
			}

			else
			{

				'Appliance Bay {0} in {1} Enclosure is already powered off.  Processing.' -f $BayID, $Enclosure.name | Write-Verbose

				$_PatchRequest = NewObject -PatchOperation

				$_PatchRequest.path  = '/applianceBays/{0}/power' -f $BayID
				$_PatchRequest.value = 'on'

				$_resp = Send-HPOVRequest $Enclosure.uri PATCH $_PatchRequest -ApplianceConnection $ApplianceConnection

			}

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}
				
		[void]$_TaskCollection.Add($_resp)

	}

	End
	{

		Return $_TaskCollection

	}

}
