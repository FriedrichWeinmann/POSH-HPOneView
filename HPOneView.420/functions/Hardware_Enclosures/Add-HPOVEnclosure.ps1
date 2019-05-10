function Add-HPOVEnclosure 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Managed", SupportsShouldProcess, ConfirmImpact = "High")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Monitored")]
		[Parameter (Mandatory, ParameterSetName = "Managed")]
		[Parameter (Mandatory, ParameterSetName = "MonitoredCredential")]
		[Parameter (Mandatory, ParameterSetName = "ManagedCredential")]
		[ValidateNotNullOrEmpty()]
		[Alias ("oa")]
		[string]$Hostname,
		 
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Managed")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "ManagedCredential")]
		[ValidateNotNullOrEmpty()]
		[Alias ("eg",'EnclGroupName')]
		[object]$EnclosureGroup,

		[Parameter (Mandatory, ParameterSetName = "Monitored")]
		[Parameter (Mandatory, ParameterSetName = "Managed")]
		[ValidateNotNullOrEmpty()]
		[Alias ("u", "user")]
		[string]$Username,

		[Parameter (Mandatory, ParameterSetName = "Monitored")]
		[Parameter (Mandatory, ParameterSetName = "Managed")]
		[ValidateNotNullOrEmpty()]
		[Alias ("p", "pw")]
		[Object]$Password,

		[Parameter (Mandatory, ParameterSetName = "MonitoredCredential")]
		[Parameter (Mandatory, ParameterSetName = "ManagedCredential")]
		[PSCredential]$Credential,

		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $false, ParameterSetName = "ManagedCredential")]
		[ValidateSet ('OneView', 'OneViewNoiLO', IgnoreCase = $False)]
		[Alias ("license", "l")]
		[string]$LicensingIntent = 'OneView',

		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $false, ParameterSetName = "ManagedCredential")]
		[Alias ("fwIso","fwBaselineIsoFilename")]
		[object]$Baseline,

		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $false, ParameterSetName = "ManagedCredential")]
		[Alias ('forceFw','forceInstall')]
		[switch]$ForceInstallFirmware,

		[Parameter (Mandatory, ParameterSetName = "Monitored")]
		[Parameter (Mandatory, ParameterSetName = "MonitoredCredential")]
		[switch]$Monitored,

		[Parameter (Mandatory = $false, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $false, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $false, ParameterSetName = "MonitoredCredential")]
		[Parameter (Mandatory = $false, ParameterSetName = "ManagedCredential")]
		[ValidateNotNullOrEmpty()]
        [HPOneView.Appliance.ScopeCollection]$Scope,

		[Parameter (Mandatory = $False, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $False, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $False, ParameterSetName = "MonitoredCredential")]
		[Parameter (Mandatory = $False, ParameterSetName = "ManagedCredential")]
		[switch]$Async,

		[Parameter (Mandatory = $False, ParameterSetName = "Monitored")]
		[Parameter (Mandatory = $False, ParameterSetName = "Managed")]
		[Parameter (Mandatory = $False, ParameterSetName = "MonitoredCredential")]
		[Parameter (Mandatory = $False, ParameterSetName = "ManagedCredential")]
		[ValidateNotNullorEmpty()]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['EnclosureGroup']) -and ($PSCmdlet.ParameterSetName -ne 'Monitored'))
		{

			$PipelineInput = $True

		}

		else
		{

			"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if (-not($ApplianceConnection -is [HPOneView.Appliance.Connection]) -and (-not($ApplianceConnection -is [System.String])))
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException InvalidApplianceConnectionDataType InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter is not type [HPOneView.Appliance.Connection] or [System.String].  Please correct this value and try again.'
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			elseif  ($ApplianceConnection.Count -gt 1)
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException MultipleApplianceConnections InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter contains multiple Appliance Connections.  This CMDLET only supports 1 Appliance Connection in the ApplianceConnect Parameter value.  Please correct this and try again.'
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			else
			{

				Try 
				{
	
					$ApplianceConnection = Test-HPOVAuth $ApplianceConnection

				}

				Catch [HPOneview.Appliance.AuthSessionException] 
				{

					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError 'ApplianceConnection' -TargetType $ApplianceConnection.GetType().Name -Message $_.Exception.Message -InnerException $_.Exception
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				Catch 
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

		}

		$colStatus = New-Object System.Collections.ArrayList

		if ($PSBoundParameters['Credential'])
		{

			$_Username = $Credential.Username
			$_Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

		}

		elseif ($PSBoundParameters['Username'])
		{

			Write-Warning "The -Username and -Password parameters are being deprecated.  Please transition your scripts to using the -Credential parameter."

			$_Username = $Username.clone()

			if ($Password -is [SecureString])
			{

				$_Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

			}

			else
			{

				$_Password = $Password.Clone()

			}

		}	

		elseif (-not $PSBoundParameters['Credential'] -and -not $PSBoundParameters['Username'])
		{

			$ExceptionMessage = "This Cmdlet requires credentials to the target resource.  Please provide either the -Username and -Password, or -Credential parameters."
			$ErrorRecord = New-ErrorRecord HPOneView.Library.UnsupportedArgumentException MissingRequiredPasswordParameter InvalidOperation 'Authentication' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}	

	}

	Process 
	{

		# Build the import object
		"[{0}] - Starting" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		$_import          = NewObject -EnclosureImport
		$_import.hostname = $hostname
		$_import.username = $_Username
		$_import.password = $_Password

		if ($PSBoundParameters['Scope'])
		{

			ForEach ($_Scope in $Scope)
			{

				"[{0}] Adding resource to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

				[void]$_import.initialScopeUris.Add($_Scope.Uri)

			}

		}

		If ('MonitoredCredential', 'Monitored' -contains $PSCmdlet.ParameterSetName)
		{

			"[{0}] - Building Monitored Enclosure request" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_import.licensingIntent = "OneViewStandard"
			$_import.state           = "Monitored"

		}

		else
		{

			"[{0}] - Building Managed Enclosure request" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			switch ($EnclosureGroup.GetType().Name)
			{

				'PSCustomObject'
				{

					"[{0}] - EnclosureGroup Parameter is 'PSCustomObject'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] - EnclosureGroup object category: '$($EnclosureGroup.category)'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					"[{0}] - EnclosureGroup object name: '$($EnclosureGroup.name)'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					if ($EnclosureGroup.category -ne $ResourceCategoryEnum['EnclosureGroup'])
					{

						$ErrorRecord = New-ErrorRecord HPOneView.EnclosureGroupResourceException InvalidEnclosureGroupObject InvalidArgument 'EnclosureGroup' -TargetType 'PSObject' -Message "The EnclosureGroup Parameter value contains an invalid or unsupported resource category, '$($EnclosureGroup.category)'.  The object category must be 'enclosure-groups'.  Please correct the value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					else
					{

						$_enclosuregroup = $EnclosureGroup.PSObject.Copy()

					}

				}

				'String'
				{

					if ($EnclosureGroup.StartsWith($enclosureGroupsUri))
					{

						Try
						{

							$_enclosuregroup = Get-HPOVEnclosureGroup -Name $EnclosureGroup -ErrorAction Stop -ApplianceConnection $ApplianceConnection

						}

						catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

					else
					{

						Try
						{

							$_enclosuregroup = Get-HPOVEnclosureGroup -Name $EnclosureGroup -ErrorAction Stop -ApplianceConnection $ApplianceConnection

						}
							
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}
						
					"[{0}] - Found Enclosure Group: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_enclosuregroup.name, $_enclosuregroup.uri | Write-Verbose

				}

			}

			$_import.licensingIntent      = $licensingIntent
			$_import.enclosureGroupUri    = $_enclosuregroup.uri
			$_import.forceInstallFirmware = [bool]$forceInstallFirmware
			$_import.updateFirmwareOn     = "EnclosureOnly" 
			
			if ($PSBoundParameters['Baseline']) 
			{
					
				"[{0}] - Firmware Baseline is to be configured" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
				switch ($baseline.Gettype().Name) 
				{

					"String" 
					{
							
						if ($Baseline.StartsWith($ApplianceFwDriversUri)) 
						{
								
							"[{0}] - Firmware Baseline URI Provided '$Baseline'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
								
							Try
							{

								$fwBaseLine = Send-HPOVRequest -Uri $Baseline -Hostname $ApplianceConnection.Name

							}
								
							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}
						
							
						}
							
						elseif ((-not ($baseline.StartsWith($ApplianceFwDriversUri)) -and ($baseline.StartsWith('/rest/')))) 
						{

							"[{0}] - Invalid Firmware Baseline URI Provided '$Baseline'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
								
							$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException InavlideBaselineUri InvalidArgument 'Baseline' -Message "The Baseline URI '$baseline' provided does not Begin with '$ApplianceFwDriversUri'.  Please correct the value and try again."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
						}

						else 
						{

							"[{0}] - Firmware Baseline Name Provided '$Baseline'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
								
							if ($Baseline -match ".iso") 
							{

								"[{0}] - Getting Baseline based on isoFileName." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								Try
								{

									$FirmwareBaslineName = $Baseline.Clone()

									$fwBaseLine = Get-HPOVBaseline -isoFileName $Baseline -ApplianceConnection $ApplianceConnection -ErrorAction SilentlyContinue

									If (-not $fwBaseLine)
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

							else 
							{

								"[{0}] - Getting Baseline based on Baseline Name." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								Try
								{

									$FirmwareBaslineName = $Baseline.Clone()

									$fwBaseLine = Get-HPOVBaseline -SppName $Baseline -ApplianceConnection $ApplianceConnection -ErrorAction SilentlyContinue

									If (-not $fwBaseLine)
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

						}

						$_import.firmwareBaselineUri = $fwBaseLine.uri
						
					}

					"PSCustomObject" 
					{

						if ($Baseline.category -eq $ResourceCategoryEnum['Baseline'] -and $baseline.ApplianceConnection.Name -eq $ApplianceConnection.Name) 
						{

							"[{0}] - Firmware Baseline Object Provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline.FileName, $Baseline.uri | Write-Verbose
								
							$_import.firmwareBaselineUri = $Baseline.uri	

						}

						else 
						{

							"[{0}] - Invalid Firmware Baseline Object Provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Baseline.name, $Baseline.uri | Write-Verbose

							if ($Baseline.category -ne $ResourceCategoryEnum['Baseline'] -and $baseline.ApplianceConnection.Name -eq $ApplianceConnection.Name) 
							{

								$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException InvalideBaselineObject InvalidArgument 'Baseline' -TargetType 'PSObject' -Message "The Baseline Category '$($baseline.category)' provided does not match the required value 'firmware-drivers'.  Please correct the value and try again."

							}
								
							elseif ($Baseline.category -eq $ResourceCategoryEnum['Baseline'] -and $baseline.ApplianceConnection.Name -ne $ApplianceConnection.Name) 
							{

								$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException InvalidBaselineOrigin InvalidArgument 'Baseline' -TargetType 'PSObject' -Message "The Baseline '$($baseline.name)' provided does not originate from the same ApplianceConnection you have specified.  Please correct the value and try again."

							}
								
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

				}

			}       

		}

		"[{0}] - Sending request to claim enclosure" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Try
		{

			$resp = Send-HPOVRequest -uri $EnclosuresUri -Method POST -Body $_import -Hostname $ApplianceConnection.Name | Wait-HPOVTaskStart

		}
		
		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		# "[{0}] - task response: $($resp | Format-List * )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Check to see if the task errored, which should be in the Task Validation stage
		if ($resp.taskState -ne "Running") 
		{

			if ($resp.taskState -eq "Error")
			{

				"[{0}] - Task error found $($resp.taskState) $($resp.stateReason) " -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				if ($resp.taskerrors | Where-Object { ($_.errorCode -eq "ENCLOSURE_ALREADY_MANAGED") -or ($_.errorCode -eq "ENCLOSURE_MANAGED_BY_VCM") }) 
				{
				
					$errorMessage = $resp.taskerrors | Where-Object { ($_.errorCode -eq "ENCLOSURE_ALREADY_MANAGED") -or ($_.errorCode -eq "ENCLOSURE_MANAGED_BY_VCM") }

					$externalManagerType = $errorMessage.data.managementProduct
					$externalManagerIP   = $errorMessage.data.managementUrl.Replace("https://","")
					
					Try
					{

						 $externalManagerFQDN = [System.Net.DNS]::GetHostByAddress($externalManagerIP)

					}

					Catch
					{

						"[{0}] Unable to resolve IP Address to DNS A Record." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						$externalManagerFQDN = [PSCustomObject]@{HostName = 'UnknownFqdn'; Aliases = @(); AddressList = @($externalManagerIP.Clone())}

					}

					"[{0}] - Found enclosure '$hostname' is already being managed by $externalManagerType at $externalManagerIP." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] - $externalManagerIP resolves to $externalManagerFQDN" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
					write-warning "Enclosure '$hostname' is already being managed by $externalManagerType at $externalManagerIP ($($externalManagerFQDN.HostName))."

					if ($PSCmdlet.ShouldProcess($hostname,"Enclosure '$hostname' is already being managed by $externalManagerType at $externalManagerIP ($($externalManagerFQDN.HostName)). Force add?")) 
					{
					
						"[{0}] - Server was claimed and user chose YES to force add." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$_import.force = $true
						
						Try
						{
						
							$resp = Send-HPOVRequest $EnclosuresUri POST $_import -Hostname $ApplianceConnection.Name
						
						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}						

					}

					else 
					{

						if ($PSBoundParameters['whatif'].ispresent) 
						{	 
					
							write-warning "-WhatIf was passed, would have force added '$hostname' enclosure to appliance."

							$resp = $null
					
						}

						else 
						{

							# If here, user chose "No", End Processing
							write-warning "Not importing enclosure, $hostname."

							$resp = $Null

						}

					}

				}

				else 
				{

					$errorMessage = $resp.taskerrors

					if ($errorMessage -is [Array]) 
					{ 
				
						# Loop to find a Message value that is not blank.
						$displayMessage = $errorMessage | Where-Object { $_.message }

						$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException $displayMessage.errorCode InvalidResult 'New-HPOVEnclosure' -Message $displayMessage.message 
					
					}
				
					else 
					{ 
						
						$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException $errorMessage.errorCode InvalidResult 'New-HPOVEnclosure' -Message ($errorMessage.details + " " + $errorMessage.message) 
					
					}

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

		}

		if (-not($PSBoundParameters['Async']))
		{

			Try
			{

				$resp = Wait-HPOVTaskComplete -InputObject $resp

			}

			catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}		

		[void]$colStatus.Add($resp)

	}

	End 
	{
		
		Return $colStatus

	}

}
