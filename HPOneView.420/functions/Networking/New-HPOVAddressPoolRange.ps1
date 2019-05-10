function New-HPOVAddressPoolRange 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "IPv4")]
		[Alias ('Subnet')]
		[ValidateNotNullorEmpty()]
		[Object]$IPv4Subnet,
	
		[Parameter (Mandatory, ParameterSetName = "Default")]
		[Parameter (Mandatory, ParameterSetName = "Custom")]
		[ValidateSet ('vmac', 'vwwn', 'vsn')]
		[String]$PoolType,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory, ParameterSetName = "Custom")]
		[ValidateSet ("Generated", "Custom")]
		[String]$RangeType = "Generated",

		[Parameter (Mandatory, ParameterSetName = "IPv4")]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory, ParameterSetName = "Custom")]
		[Parameter (Mandatory, ParameterSetName = "IPv4")]
		[ValidateNotNullorEmpty()]
		[String]$Start,

		[Parameter (Mandatory, ParameterSetName = "Custom")]
		[Parameter (Mandatory, ParameterSetName = "IPv4")]
		[ValidateNotNullorEmpty()]
		[String]$End,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "Custom")]
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "IPv4")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{ 

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($PSCmdlet.ParameterSetName -eq 'IPv4' -and (-not($PSBoundParameters['IPv4Subnet'])))
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

		$_Collection = New-Object System.Collections.ArrayList

		# Validate Parameter options here
		if ($PSCmdlet.ParameterSetName -eq 'Custom' -and $RangeType -ne 'Custom')
		{

			$ErrorRecord = New-ErrorRecord InvalidOperationException LogicalInterconnectUriNoApplianceConnection InvalidArgument 'RangeType' -Message "Custom Address Range was provided, but the RangeType Parameter value was not set to 'Custom'. Please check to make sure your call is correct, and try again.."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Generate error when defining custom range and not a specific appliance
		if ($PSCmdlet.ParameterSetName -eq 'Custom' -and $ApplianceConnection.count -gt 1)
		{

			$ErrorRecord = New-ErrorRecord InvalidOperationException LogicalInterconnectUriNoApplianceConnection InvalidArgument 'ApplianceConnection' -Message "A Custom Address Range was provided with no Appliance Connection specified.  Custom Address Pool Ranges should be unique per appliance connection.  Please specify an Appliance Connection and try your call again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}
	
	}

	Process 
	{

		if ($PSCmdlet.ParameterSetName -eq 'IPv4')
		{

			# Validate IPv4Subnet value
			if ($IPv4Subnet.category -ne 'id-range-IPv4-subnet')
			{

				"[{0}] Invalid IPv4 Address Pool resource object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolResourceException InvalidIPv4AddressPoolResource InvalidArgument 'IPv4Subnet' -TargetType 'PSObject' -Message "An invalid IPv4 Address Pool resource object was provided.  Please verify the Parameter value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if (-not [HPOneView.Appliance.AddressPool]::IsInSameSubnet($Start,$IPv4Subnet.networkId,$IPv4Subnet.subnetMask))
			{

				"[{0}] The Start address value {1} is not within the Subnet Network ID {2}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Start, $IPv4Subnet.networkId | Write-Verbose

				$Exceptionmessage = "The Start address value {0} is not within the Subnet Network ID {1}\{2}." -f $Start, $IPv4Subnet.networkId, $IPv4Subnet.subnetMask

				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolResourceException InvalidIPv4AddressPoolResource InvalidArgument 'Start' -TargetType 'PSObject' -Message $Exceptionmessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if (-not [HPOneView.Appliance.AddressPool]::IsInSameSubnet($End,$IPv4Subnet.networkId,$IPv4Subnet.subnetMask))
			{

				"[{0}] The End address value {1} is not within the Subnet Network ID {2}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $End, $IPv4Subnet.networkId | Write-Verbose

				$Exceptionmessage = "The End address value {0} is not within the Subnet Network ID {1}\{2}." -f $End, $IPv4Subnet.networkId, $IPv4Subnet.subnetMask

				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolResourceException InvalidIPv4AddressPoolResource InvalidArgument 'End' -TargetType 'PSObject' -Message $Exceptionmessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			# Create Pool Range, then assign to Subnet
			$_newRange = NewObject -IPIDPoolRange
			$_newRange.name         = $Name
			$_newRange.startAddress = $Start
			$_newRange.endAddress   = $End
			$_newRange.subnetUri    = $IPv4Subnet.uri

			"[{0}] Sending request"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_resp = Send-HPOVRequest -Uri $ApplianceIPv4PoolRangesUri -Method POST -Body $_newRange -Hostname $ApplianceConnection.Name

				$_resp.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.AddressPoolRange')

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			
			[void]$_Collection.Add($_resp)

		}

		else
		{
					
			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

				# Get the correct URI to request a new Generated Address Range
				"[{0}] Creating new $($PoolType) type address range" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				switch ($PoolType) 
				{

					"vmac" 
					{ 
			
						$_newGenRangeUri  = $script:ApplianceVmacGenerateUri
						$_newPoolRangeUri = $script:ApplianceVmacPoolRangesUri

					}

					"vwwn" 
					{ 
			
						$_newGenRangeUri  = $script:ApplianceVwwnGenerateUri
						$_newPoolRangeUri = $script:ApplianceVwwnPoolRangesUri
				
					}

					"vsn" 
					{ 
			
						$_newGenRangeUri  = $script:ApplianceVsnPoolGenerateUri
						$_newPoolRangeUri = $script:ApplianceVsnPoolRangesUri
			
					}

				}

				switch ($RangeType) 
				{

					"Generated" 
					{
					
						"[{0}] Generating new address range" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
						# SEnd the request, and remove the fragmentType property as it's not a valid JSON pfield for the request.
						Try
						{

							$_newRange = Send-HPOVRequest $_newGenRangeUri -Hostname $_appliance.Name | Select-Object -Property * -excludeproperty fragmentType

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						$_newRange | add-member -NotePropertyName type -NotePropertyValue "Range"
						$_newRange | add-member -NotePropertyName rangeCategory -NotePropertyValue "GENERATED"

					}
				
					"Custom" 
					{

						"[{0}] Creating custom new address range" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						"[{0}] Starting Address: $($Start)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						"[{0}] End Address: $($End)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						switch ($PoolType) 
						{
						
							"vmac" 
							{
							
								if (-not($Start -match ($macAddressPattern))) 
								{ 
								
									$ExceptionMessage = "The provided Start address {0} does not conform to a valid MAC Address value." -f $Start

									$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolRangeException InvalidMacStartAddress InvalidArgument 'Start' -Message $ExceptionMessage 
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)

								}

								if (-not($End -match ($macAddressPattern))) 
								{ 
								
									$ExceptionMessage = "The provided End address {0} does not conform to a valid MAC Address value." -f $End

									$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolRangeException InvalidMacendAddress InvalidArgument 'End' -Message $ExceptionMessage 
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
								}

							 }
						
							"vwwn" 
							{
						
								if (-not($Start -match ($wwnAddressPattern))) 
								{ 
								
									$ExceptionMessage = "The provided Start address {0} does not conform to a valid WWN Address value." -f $Start

									$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolRangeException InvalidWwnStartAddress InvalidArgument 'Start' -Message $ExceptionMessage 
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
								}

								if (-not($End -match ($wwnAddressPattern))) 
								{ 
								
									$ExceptionMessage = "The provided End address {0} does not conform to a valid WWN Address value." -f $End

									$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolRangeException InvalidWwnendAddress InvalidArgument 'End' -Message $ExceptionMessage 
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
								}
						
							}

							"vsn" 
							{
						
								if (-not $Start.StartsWith('VCU')) 
								{ 
								
									$ExceptionMessage = "The provided Start address {0} does not conform to a valid Serial Number value." -f $Start

									$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolRangeException InvalidSerialNumberStartAddress InvalidArgument 'Start' -Message $ExceptionMessage 
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
								}

								if (-not $End.StartsWith('VCU')) 
								{ 
								
									$ExceptionMessage = "The provided End address {0} does not conform to a valid Serial Number value." -f $End

									$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolRangeException InvalidSerialNumberendAddress InvalidArgument 'End' -Message $ExceptionMessage 
									$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
								}
						
							}

						}
					
						$_newRange = NewObject -IDPoolRange

						$_newRange.startAddress = $Start
						$_newRange.endAddress   = $End
				
					}

				}

				# "[{0}] New Range Object: $($_newRange )" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Sending request"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_resp = Send-HPOVRequest $_newPoolRangeUri POST $_newRange -Hostname $_appliance.Name

					$_resp.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.AddressPoolRange')

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				[void]$_Collection.Add($_resp)

			}

		}

	}

	End
	{

		return $_Collection

	}

}
