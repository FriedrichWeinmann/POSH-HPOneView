function Install-HPOVLogicalInterconnectFirmware 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(
		
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[Alias ('name','uri', 'li')]
		[ValidateNotNullorEmpty()]
		[object]$LogicalInterconnect,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateSet ('Update','Activate','Stage')]
		[string]$Method = "Update",

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateSet ('OddEven','Parallel','Serial')]
		[Alias ('Order','ActivateOrder')]
		[string]$EthernetActivateOrder = 'OddEven',

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[int]$EthernetActivateDelay = 5,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateSet ('OddEven','Parallel','Serial')]
		[String]$FCActivateOrder = 'Serial',

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[int]$FCActivateDelay = 5,

		[Parameter (Mandatory, ParameterSetName = "default")]
		[Alias ('spp')]
		[object]$Baseline,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[switch]$Force,

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

		if (-not($LogicalInterconnect))
		{

			$PipelineInput = $True

		}
		
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

		$TaskCollection = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		if ($PipelineInput -or $LogicalInterconnect -is [PSCustomObject])
		{

			# Validate Logical Interconnect Object Type
			if (-not($LogicalInterconnect -is [PSCustomObject]) -and $LogicalInterconnect.category -ne 'local-interconnects') 
			{

				"[{0}] invalid LogicalInterconnect passed: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect | Write-Verbose

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'INSTALL-HPOVLOGICALINTERCONNECTFIRMWARE' -Message "The 'LogicalInterconnect' Parameter value '$($LogicalInterconnect)' is invalid.  Please check the Parameter value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
		
			}

		}

		else
		{

			if ($null -eq $ApplianceConnection)
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError $ApplianceConnection[$c].Name -Message 'No Appliance Connection was provided.  Please provide a valid ApplianceConnection Object.'
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

			"[{0}] Looking for Logical Interconnect '{1}' from Get-HPOVLogicalInterconnect." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect | Write-Verbose

			Try
			{
				
				$LogicalInterconnect = Get-HPOVLogicalInterconnect -Name $LogicalInterconnect -ApplianceConnection $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		"[{0}] Validating Baseline input value." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		switch ($Baseline.GetType().Name)
		{

			'String'
			{

				Try
				{

					"[{0}] Firmware Baseline name passed:  {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline | Write-Verbose

					$FirmwareBaslineName = $Baseline.Clone()

					$Baseline = Get-HPOVBaseline -name $Baseline -ApplianceConnection $LogicalInterconnect.ApplianceConnection.Name -ErrorAction SilentlyContinue

					If (-not $_BaseLinePolicy)
					{

						$ExceptionMessage = "The provided Baseline '{0}' was not found." -f $FirmwareBaslineName
						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'Baseline' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			'PSCustomObject'
			{

				"[{0}] Firmware Baseline object passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline.name | Write-Verbose
				"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline.uri | Write-Verbose
				"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline.ApplianceConnection.Name | Write-Verbose
				"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline.category | Write-Verbose

				if ($Baseline.category -ne 'firmware-drivers')
				{
					
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException InvalidBaselineObject InvalidArgument 'Baseline' -TargetType 'PSObject' -Message "The Baseline provided in an invalid object.  Baseline category value '$($Baseline.caetegory)', expected 'firmware-drivers'.  Please check the Parameter value and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)
					
				}

			}

		}

		$Staging    = $False
		$Activating = $False

		"[{0}] Processing '{1}' Logical Interconnect." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect.name | Write-Verbose

		$_Request = NewObject -LogicalInterconnectBaseline

		$_Request.command                 = $Method
		$_Request.ethernetActivationType  = [String]$EthernetActivateOrder
		$_Request.ethernetActivationDelay = [int]$EthernetActivateDelay
		$_Request.fcActivationType        = [String]$FCActivateOrder
		$_Request.fcActivationDelay       = [int]$FCActivateDelay
		$_Request.sppUri                  = $Baseline.uri
		$_Request.force                   = [bool]$PSBoundParameters['Force']

		switch ($Method) 
		{

			{'Update', 'Stage' -match $_}
			{ 

				"[{0}] '{1}' Method called." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Method | Write-Verbose
				
				$_Request.command = $Method
				
				
			}

			"Activate" 
			{

				"[{0}] 'Activate' Method called." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				"[{0}] Verifying '{1}' LI is in a Staged state." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect.name | Write-Verbose
				
				Try
				{

					$_FirmwareStatus = Send-HPOVRequest ($LogicalInterconnect.uri + "/firmware") -Hostname $LogicalInterconnect.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				# Validate interconnect firmware update state
				switch ($_FirmwareStatus.state) 
				{
					 
					'STAGED' 
					{ 
						
						"[{0}] '{1}' LI is in the proper '{2}' state." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect.name, $_FirmwareStatus.state | Write-Verbose

						#$baselineObj = [pscustomobject] @{ uri = $_FirmwareStatus.sppUri }

						$_Request.command = 'ACTIVATE'
						$_Request.sppUri  = $_FirmwareStatus.sppUri

					}
						
					'STAGING'
					 { 
						
						"[{0}] '{1}' is currently being staged with firmware. Please wait until the task completes." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect.name | Write-Verbose
							
						# Locate and return running task.
						$_task = Get-HPOVTask -State Running -resource $LogicalInterconnect.name -ApplianceConnection $LogicalInterconnect.ApplianceConnection.Name

						$_task | Where-Object { $_.taskStatus.StartsWith('Staging') } | ForEach-Object {

							[void]$TaskCollection.Add($_)

						}

						# Flag to skip the command Processing IF block below
						$Staging = $true
							
					}

					'STAGING_FAILED' 
					{ 
						
						$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidLogicalInterconnectState InvalidResult 'LogicalInterconnect' -Message "The $($LogicalInterconnect.name) Logical Interconnect is in an invalid state ($($_FirmwareStatus.state))in order to issue the Activate command."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
						
					}

					'ACTIVATED' 
					{ 
						
						"[{0}] '{1}' is already activated." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect.name | Write-Verbose
						
						Write-Warning ("'{0}' is already activated." -f $LogicalInterconnect.name)
						
						Return 
					
					}

					'ACTIVATING' 
					{
							
						# Logical Interconnect is already Processing the Activate command.
						"[{0}] '{1}' is already activating. Returning task resource." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect.name | Write-Verbose

						# Flag to skip the command Processing IF block below
						$activating = $True
							
						# Locate and return running task.
						Try
						{

							$_task = Get-HPOVTask -State Running -resource $LogicalInterconnect.name -ApplianceConnection $LogicalInterconnect.ApplianceConnection.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}						

						$_task | Where-Object { $_.taskStatus.StartsWith('Activating') } | ForEach-Object {

							[void]$TaskCollection.Add($_)

						}

					}

					'ACTIVATION_FAILED' 
					{ 
						
						"[{0}] '{1}' failed a prior activation request.  LI is in a valid state to attempt Activation command." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect.name | Write-Verbose

						#$baselineObj = [pscustomobject] @{ uri = $_FirmwareStatus.sppUri }

						$_Request.command = 'ACTIVATE'
						$_Request.sppUri  = $_FirmwareStatus.sppUri
							
					}

					'PARTIALLY_ACTIVATED' 
					{ 
						
						"[{0}] '{1}' is Partially Activated.  LI is in a valid state to attempt Activation command." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect.name | Write-Verbose
						$baselineObj = [pscustomobject] @{ uri = $_FirmwareStatus.sppUri }
						
					}

					'PARTIALLY_STAGED' 
					{
						
						$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidLogicalInterconnectState InvalidResult 'LogicalInterconnect' -Message "The $($LogicalInterconnect.name) Logical Interconnect is in an invalid state ($($_FirmwareStatus.state)) in order to issue the Activate command."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
						
					}

					'UNINITIALIZED' 
					{ 
						
						<# Generate Error that firmware has not been staged #> 
						$ErrorRecord = New-ErrorRecord InvalidOperationException NoStagedFirmwareFound ObjectNotFound 'LogicalInterconnect' -Message "No staged firmware found for '$($LogicalInterconnect.name)' Logical Interconnect.  Use Install-HPOVLogicalInterconnectFirmware -method Stage to first stage the firmware before attempting to Activate."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
					}

				}
				
			}

		}

		$_uri = $LogicalInterconnect.uri + "/firmware"

		# Need to prompt user to update or activate firmware, which could cause an outage.
		if ($Method -eq 'Update' -and -not $Activating -and -not $Staging)
		{

			Write-Warning 'Module activation may cause a network outage if Activation Order is Parallel.'

			if ($PSCmdlet.ShouldProcess($LogicalInterconnect.name, 'update Interconnect modules')) 
			{

				"[{0}] User was prompted warning and accepted. Sending request." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_taskResults = Send-HPOVRequest -method PUT -uri $_uri -body $_Request -Hostname $LogicalInterconnect.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
					
			}

			else 
			{ 
				
				"[{0}] User was prompted and selected No, will not update {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect.name | Write-Verbose
			
			}

		}

		# User is staging firmware, no need to prompt.
		elseif (-not($Activating) -and (-not($Staging)))
		{

			"[{0}] Beginning to stage firmware to '{1}'." -f $MyInvocation.InvocationName.ToString().ToUpper(), $LogicalInterconnect.name | Write-Verbose

			Try
			{

				$_taskResults = Send-HPOVRequest -method PUT -uri $_uri -body $_Request -Hostname $LogicalInterconnect.ApplianceConnection

			}

			Catch
			{

			  $PSCmdlet.ThrowTerminatingError($_)

			}

		}

		if (-not($PSBoundParameters['Async']) -and $_taskResults)
		{

			Try
			{

				$_taskResults = Wait-HPOVTaskComplete $_taskResults -ApplianceConnection $_taskResults.ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		[void]$TaskCollection.Add($_taskResults)

	}

	End 
	{

		"[{0}] Finished, returning results." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		return $TaskCollection

	}


}
