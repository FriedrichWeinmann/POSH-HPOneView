function Set-HPOVEnclosure
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param
	(

		[Parameter (ValueFromPipeline, Mandatory, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias('Enclosure', 'Encl')]
		[object]$InputObject,

		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[String]$RackName,

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

		if (-not($PSBoundParameters['InputObject'])) 
		{ 
			
			$PipelineInput = $True 
		
		}

		# Support ApplianceConnection property value via pipeline from Enclosure Object
		else
		{

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

		$_RequestCollection = New-Object System.Collections.ArrayList
		$_TaskCollection    = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		"[{0}] Processing Enclosure: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

		if ($InputObject.enclosureModel -notmatch 'Synergy' -and ($PSBoundParameters['Name'] -or $PSBoundParameters['RackName']))
		{

			$ExceptionMessage = 'The InputObject {0} is not a supported resource to set the Enclosure Name.  For C-Class, you must update the Enclosure or Rack Name within the Onboard Admoinistrator.' -f $InputObject.name
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
			$PSCmdlet.WriteError($ErrorRecord)

		}

		elseif ($PSBoundParameters['Name'])
		{

			"[{0}] Setting Enclosure Name to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

			$_PatchRequest = NewObject -PatchOperation

			$_PatchRequest.op = 'replace'
			$_PatchRequest.path  = '/name'
			$_PatchRequest.value = $Name

			[void]$_RequestCollection.Add($_PatchRequest)

			Try
			{

				$_resp = Send-HPOVRequest $InputObject.uri PATCH $_RequestCollection -AddHeader @{'If-Match' = $InputObject.eTag} -Hostname $InputObject.ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}	
				
		if ($PSBoundParameters['RackName'])
		{

			"[{0}] Setting Enclosure RackName to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $RackName | Write-Verbose

			if ($PSBoundParameters['Name'])
			{

				Try
				{

					$_resp = Wait-HPOVTaskComplete -InputObject $_resp

					[void]$_TaskCollection.Add($_resp)

					"[{0}] Getting updated object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$InputObject = Send-HPOVRequest -Uri $InputObject.uri -Hostname $InputObject.ApplianceConnection.Name

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
			
			}

			$_RequestCollection = New-Object System.Collections.ArrayList

			$_PatchRequest = NewObject -PatchOperation

			$_PatchRequest.op = 'replace'
			$_PatchRequest.path  = '/rackName'
			$_PatchRequest.value = $RackName

			[void]$_RequestCollection.Add($_PatchRequest)

			Try
			{

				$_resp = Send-HPOVRequest $InputObject.uri PATCH $_RequestCollection -AddHeader @{'If-Match' = $InputObject.eTag} -Hostname $InputObject.ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		[void]$_TaskCollection.Add($_resp)

	}

	End
	{

		Return $_TaskCollection

	}

}
