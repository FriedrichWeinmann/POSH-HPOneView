function New-HPOVNetworkSet 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory)]
		[String]$Name,

		[Parameter (Mandatory)]
		[Alias ('networkUris')]
		[Object]$Networks,

		[Parameter (Mandatory = $False)]
		[Alias ('untagged','native','untaggedNetworkUri')]
		[Object]$UntaggedNetwork,

		[Parameter (Mandatory = $False)]
		[int32]$TypicalBandwidth = 2500,

		[Parameter (Mandatory = $False)]
		[int32]$MaximumBandwidth = 10000,
	
		[Parameter (Mandatory = $False)]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)
	
	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

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

		$_NetSetStatusCol = New-Object System.Collections.ArrayList	

	}
	
	Process 
	{


		"[{0}] Processing '{1}' Appliance Connection" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ApplianceConnection.Name | Write-Verbose

		"[{0}] Building NetworkSet '{1}' object." -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

		$_NewNetSet = Newobject -NetworkSet

		$_NewNetSet.name = $Name

		# Validate Networks if they are objects, and ApplianceConnection prop matches $_connection.Name value
		ForEach ($_net in $Networks)
		{

			switch ($_net.GetType().Name)
			{

				'String'
				{

					# URI provided
					if ($_net.StartsWith($EthernetNetworksUri))
					{

						"[{0}] Network resource is [String] and URI. Getting resource object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						try
						{

							$_net = Send-HPOVRequest -Uri $_net -Hostname $ApplianceConnection.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

					# Name provided
					else
					{

						"[{0}] Network resource is [String] and Name. Getting resource object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						try
						{

							$_originalnet = $_net.Clone()

							$_net = Get-HPOVNetwork -Name $_net -ApplianceConnection $ApplianceConnection.Name -ErrorAction Stop

							if ($_net.count -gt 1)
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException MultipleNetworkResourcesFound LimitsExceeded 'Networks' -Message "Network '$_originalnet' is not a unique resource name, as multiple Network resources were found.  Please correct the Parameter value and try again."
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

				}

				'PSCustomObject'
				{

					"[{0}] Processing Object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_net.name | Write-Verbose
					"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_net.uri | Write-Verbose
					"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_net.ApplianceConnection.Name | Write-Verbose
					"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_net.category | Write-Verbose

					# Object must have the ApplianceConnection NoteProperty
					if (-not($_net.ApplianceConnection))
					{

						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException MissingApplianceConnectionNoteProperty InvalidArgument 'Networks' -TargetType 'PSObject' -Message "Network '$($_net.name)' does not contain the required 'ApplianceConnection' NoteProperty. Network objects must be retrieved from the appliance either using their unique URI or with Get-HPOVNetwork. Please correct the Parameter value  and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					elseif ($_net.ApplianceConnection.Name -ne $ApplianceConnection.Name)
					{

						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException ApplianceConnetionDoesNotMatchObject InvalidArgument 'Networks' -TargetType 'PSObject' -Message "Network '$($_net.name)' 'ApplianceConnection' NoteProperty {$($_net.ApplianceConnection.Name)}does not match the Appliance Connection currently Processing {$($ApplianceConnection.Name)}. Network objects must be retrieved from the appliance either using their unique URI or with Get-HPOVNetwork. Please correct the Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if ($_net.category -ne 'ethernet-networks')
					{

						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException UnsupportedResourceCategory InvalidArgument 'Networks' -TargetType 'PSObject' -Message "Network '$($_net.name)' category {$($_net.category)} is not the supported type, 'ethernet-networks'. Network objects must be retrieved from the appliance either using their unique URI or with Get-HPOVNetwork using the -Type Ethernet Parameter. Please correct the Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				default
				{

					$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException UnsupportedParameterValueType InvalidType 'Networks' -TargetType $_Net.GetType().Name -Message "The provided Networks Parameter value type '$($_Net.GetType().Name)' is not supported.  Only String (Name or URI) or PSCustomObject types are allowed and supported. Please correct the Parameter value and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			[void]$_NewNetSet.networkUris.Add($_net.uri)

		}

		if ($PSboundParameters['UntaggedNetwork'])
		{

			# Validate UntaggedNetwork if it is an object, and ApplianceConnection prop matches $_connection.Name value
			switch ($UntaggedNetwork.GetType().Name)
			{

				'String'
				{

					# URI provided
					if ($UntaggedNetwork.StartsWith($EthernetNetworksUri))
					{

						"[{0}] UntaggedNetwork resource is [String] and URI. Getting resource object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						try
						{

							$UntaggedNetwork = Send-HPOVRequest -Uri $UntaggedNetwork -Hostname $ApplianceConnection.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

					# Name provided
					else
					{

						"[{0}] UntaggedNetwork resource is [String] and Name. Getting resource object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						try
						{

							$UntaggedNetwork = Get-HPOVNetwork -Name $UntaggedNetwork -ApplianceConnection $ApplianceConnection.Name -ErrorAction Stop

							if ($UntaggedNetwork.count -gt 1)
							{

								$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException MultipleNetworkResourcesFound LimitsExceeded 'UntaggedNetwork' Message "Network '$_originalnet' is not a unique resource name, as multiple Network resources were found.  Please correct theParameter value and try again."
								$PSCmdlet.ThrowTerminatingError($ErrorRecord)

							}

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

				}

				'PSCustomObject'
				{

					"[{0}] Processing Untagged object." -f $MyInvocation.InvocationName.ToString().ToUpper(), $UntaggedNetwork.name | Write-Verbose
					"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $UntaggedNetwork.name | Write-Verbose
					"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $UntaggedNetwork.uri | Write-Verbose
					"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $UntaggedNetwork.ApplianceConnection.Name | Write-Verbose
					"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $UntaggedNetwork.category | Write-Verbose

					# Object must have the ApplianceConnection NoteProperty
					if (-not($UntaggedNetwork.ApplianceConnection))
					{

						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException MissingApplianceConnectionNoteProperty InvalidArgument 'UntaggedNetwork' -TargetType 'PSObject' -Message "Network '$($UntaggedNetwork.name)' does not contain the required 'ApplianceConnection' NoteProperty. Networkobjects must be retrieved from the appliance either using their unique URI or with Get-HPOVNetwork. Please correct the Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					elseif ($UntaggedNetwork.ApplianceConnection.Name -ne $ApplianceConnection.Name)
					{

						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException ApplianceConnetionDoesNotMatchObject InvalidArgument 'UntaggedNetwork' -TargetType 'PSObject' -Message "Network '$($UntaggedNetwork.name)' 'ApplianceConnection' NoteProperty {$($UntaggedNetwork.ApplianceConnection.Name)}does notmatch the Appliance Connection currently Processing {$($ApplianceConnection.Name)}. Network objects must be retrieved from the appliance either using their unique URI or with Get-HPOVNetwork. Please correct the Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if ($UntaggedNetwork.category -ne 'ethernet-networks')
					{

						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException UnsupportedResourceCategory InvalidArgument 'UntaggedNetwork' -TargetType'PSObject' -Message "Network '$($UntaggedNetwork.name)' category {$($UntaggedNetwork.category)} is not the supported type, 'ethernet-networks'. Network objects must be retrieved from the appliance either using their unique URI or with Get-HPOVNetwork using the -Type Ethernet Parameter.Please correct the Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				default
				{

					$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException UnsupportedParameterValueType InvalidType 'UntaggedNetwork' -TargetType	$UntaggedNetwork.GetType().Name -Message "The provided UntaggedNetwork Parameter value type '$($UntaggedNetwork.GetType().Name)' is not	  supported.  Only String (Name or URI) or PSCustomObject types are allowed and supported. Please correct the Parameter value and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			$_NewNetSet.nativeNetworkUri = $UntaggedNetwork.uri

		}

		# Caller is requesting different bandwidth settings.  Need to handle async task to create network set.
		if ($PSBoundParameters['TypicalBandwidth'] -or $PSBoundParameters['MaximumBandwidth']) 
		{

			try 
			{

				$_task = Send-HPOVRequest -Uri $NetworkSetsUri -Method POST -Body $_NewNetSet -Hostname $ApplianceConnection.Name | Wait-HPOVTaskComplete

				if ($_task.taskStatus -eq "Created") 
				{

					"[{0}] Network Set was successfully created" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Updating Network Set bandwidth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Requested Typical bandwidth: $($typicalBandwidth)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Requested Maximum bandwidth: $($maximumBandwidth)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# Get Network Set Object
					Try
					{

						$_NetSetObj = Send-HPOVRequest -Uri $_task.associatedResource.resourceUri -Hostname $ApplianceConnection.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
						
					# Update the associated connection template with max & typical bandwidth settings	            
					Try
					{

						$_ct = Send-HPOVRequest -Uri $_NetSetObj.connectionTemplateUri -Hostname $ApplianceConnection.Name

					}
						
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
						

					if ($PSBoundParameters['typicalBandwidth']) { $_ct.bandwidth.typicalBandwidth = $typicalBandwidth }

					if ($PSBoundParameters['maximumBandwidth']) { $_ct.bandwidth.maximumBandwidth = $maximumBandwidth }
						
					# Update Connection Template Object
					Try
					{

						$_ct = Send-HPOVRequest -Uri $_ct.uri -Method PUT -Body $_ct -Hostname $ApplianceConnection.Name

					}
						
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					# Get Network Set Object after CT has been updated
					Try
					{

						$_NetSetObj = Send-HPOVRequest -Uri $_NetSetObj.uri -Hostname $ApplianceConnection.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
						
				}

			}

			catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			[void]$_NetSetStatusCol.Add($_NetSetObj)

		}

		else 
		{

			"[{0}] Sending request with default bandwidth." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_task = Send-HPOVRequest -Uri $NetworkSetsUri -Method POST -Body $_NewNetSet -Hostname $ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			[void]$_NetSetStatusCol.Add($_task)

		}

	}

	End 
	{

		# Return Network Set collection status/objects
		Return $_NetSetStatusCol

	}

}
