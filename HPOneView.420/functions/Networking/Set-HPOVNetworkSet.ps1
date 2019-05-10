function Set-HPOVNetworkSet 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullorEmpty()]
		[Alias ('NetSet')]
		[Object]$NetworkSet,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Object]$Networks,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[PSObject[]]$AddNetwork,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[PSObject[]]$RemoveNetwork,

		[Parameter (Mandatory = $False)]
		[Alias ('untagged','native','untaggedNetworkUri')]
		[ValidateNotNullorEmpty()]
		[Object]$UntaggedNetwork,

		[Parameter (Mandatory = $false)]
		[validaterange(2,20000)]
		[int32]$TypicalBandwidth, 
		
		[Parameter (Mandatory = $false)]
		[validaterange(100,20000)]
		[int32]$MaximumBandwidth,

		[Parameter (Mandatory = $false, ValueFromPipelinebyPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose
		
		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['NetworkSet']))
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

				# Check for URI Parameters with multiple appliance connections
				if($ApplianceConnection.Count -gt 1)
				{

					if ($NetworkSet -is [String] -and ($NetworkSet.StartsWith($NetworkSetsUri))) 
					{
					
						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'NetworkSet' -Message "The NetworkSet Parameter as URI is unsupported with multiple appliance connections.  Please check the -NetworkSet Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
					}

					if (($Networks -is [string] -and $Networks.startswith($EthernetNetworksUri)) -or ($Networks -is [Array] -and ($Networks | ForEach-Object { $_.startswith($EthernetNetworksUri) })))
					{

						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'Networks' -TargetType $Networks.GetType().Name -Message "Networks Parameter contains 1 or more URIs that are unsupported with multiple appliance connections.  Please check the -networks Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					if ($UntaggedNetwork -is [string] -and $UntaggedNetwork.startswith($EthernetNetworksUri)) 
					{

						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'Set-HPOVNetworkSet' -Message "Untaggednetwork Parameter as URI is unsupported with multiple appliance connections.  Please check the -untaggednetwork Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}


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
		
		$_TaskCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{
		
		# Process Network Set input object is the correct resource and data type.
		switch ($NetworkSet.Gettype().Name) 
		{

			"PSCustomObject" 
			{ 
	
				if ($NetworkSet.category -eq "network-sets")
				{

					"[{0}] Processing $($NetworkSet.type) $($NetworkSet.name) resource." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

				else 
				{

					$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'NetworkSet' -TargetType 'PSObject' -Message "The provided NetworkSet resource contains an unsupported category type, '$($NetworkSet.category)'.  Only 'network-sets' resources are allowed.  Please check the -NetworkSet Parameter value and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}
				
			}

			"String" 
			{ 
				
				if (-not ($NetworkSet.StartsWith($NetworkSetsUri)))
				{
					
					"[{0}] Getting '$($NetworkSet)' resource from appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$NetworkSet = Get-HPOVNetworkSet $NetworkSet -appliance $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
						

				}

				elseif ($netSet.StartsWith($NetworkSetsUri))
				{
					
					"[{0}] Getting '$($netSet)' resource from appliance." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$NetworkSet = Send-HPOVRequest $NetworkSet -appliance $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
				}
				
			}

			default
			{
					
				$ErrorRecord = New-ErrorRecord HPOneView.NetworkSetResourceException InvalidArgumentValue InvalidArgument 'NetworkSet' -TargetType $NetworkSet.GetType().Name -Message "[$($netSet.gettype().name)] is an unsupported data type.  Only [System.String] or [PSCustomObject] Network Set resources are allowed.  Please check the -NetworkSet Parameter value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		$_UpdatedNetSet = $NetworkSet.PSObject.Copy()

		$_UpdatedNetSet.networkUris = New-Object System.Collections.ArrayList

		# Rebuild the list of URIs
		ForEach ($_OriginalNetUri in $NetworkSet.networkUris)
		{

			[void]$_UpdatedNetSet.networkUris.Add($_OriginalNetUri)

		}

		# Process Network Set Name change
		if ($PSBoundParameters["Name"]) 
		{
			
			"[{0}] Updating Network Set name to '$name'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_UpdatedNetSet.name = $name
			
		}

		if ($PSBoundParameters["Networks"]) 
		{

			"[{0}] Processing $($Networks.count) network resources" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$i = 1

			"[{0}] Clearing out existing networkUris." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_UpdatedNetSet.networkUris = New-Object System.Collections.ArrayList

			foreach ($_net in $Networks) 
			{

				switch ($_net.GetType().Name)
				{

					'String'
					{

						if ($_net.startswith($EthernetNetworksUri)) 
						{

							"[{0}] Network [$i] is a URI: $_net" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							Try
							{

								[void]$_UpdatedNetSet.networkUris.Add($_net)

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

						}

						elseif ($_net -is [string]) 
						{

							"[{0}] Network [$i] is a Name: $_net" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							Try
							{

								$_networkObject = Get-HPOVNetwork $_net -type Ethernet -appliance $ApplianceConnection

								[void]$_UpdatedNetSet.networkUris.Add($_networkObject.uri)

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}
								
						}

					}

					'PSCustomObject'
					{

						if ($_net.category -eq "ethernet-networks") 
						{

							"[{0}] Network [$i] is a type [PsCustomObject]" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							"[{0}] Network [$i] Name: $($_net.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							"[{0}] Network [$i] uri: $($_net.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						}

						else 
						{

							$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'Networks' -TargetType $_Net.GetType().Name -Message "Network '$($_net.name)' is not a supported type '$($_net.gettype().fullname)'.  Network resource must be either [System.String] or [PsCustomObject].  Please correct the Parameter value and try again."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						[void]$_UpdatedNetSet.networkUris.Add($_net.uri)

					}

					default
					{

						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'Networks' -TargetType $_Net.GetType().Name -Message "The provided Network is not a supported type '$($_net.gettype().fullname)'.  Network resource must be either [System.String] or [PsCustomObject].  Please correct the Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				$i++
					
			}

		}

		if ($PSBoundParameters['AddNetwork'])
		{

			$a = 1

			ForEach ($_NetToAdd in $AddNetwork)
			{

				switch ($_NetToAdd.GetType().Name)
				{

					'String'
					{

						if ($_NetToAdd.startswith($EthernetNetworksUri)) 
						{

							"[{0}] Network [$a] is a URI: $_NetToAdd" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							Try
							{

								$_NetToAdd = Send-HPOVRequest -Uri $_NetToAdd -Appliance $ApplianceConnection

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

						}

						elseif ($_NetToAdd -is [string]) 
						{

							"[{0}] Network [$a] is a Name: $_NetToAdd" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							Try
							{

								$_NetToAdd = Get-HPOVNetwork -Name $_NetToAdd -type Ethernet -appliance $ApplianceConnection -ErrorAction Stop

								# [void]$_UpdatedNetSet.networkUris.Add($_networkObject.uri)

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}
								
						}

					}

					'PSCustomObject'
					{

						if ($_NetToAdd.category -eq "ethernet-networks") 
						{

							"[{0}] Network [$a] is a type [PsCustomObject]" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							"[{0}] Network [$a] Name: $($_NetToAdd.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							"[{0}] Network [$a] uri: $($_NetToAdd.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						}

						else 
						{

							$ExceptionMessage = "Network '{0}' is not a supported type '{1}'.  Network resource must be either [System.String] or [PsCustomObject].  Please correct the Parameter value and try again." -f $_NetToAdd.name, $_NetToAdd.gettype().fullname
							$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'AddNetwork' -TargetType $_NetToAdd.GetType().Name -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

					default
					{

						$ExceptionMessage = "The provided Network is not a supported type '$($_NetToAdd.gettype().fullname)'.  Network resource must be either [System.String] or [PsCustomObject].  Please correct the Parameter value and try again."
						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'AddNetwork' -TargetType $_NetToAdd.GetType().Name -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				"[{0}] Adding network '{1}' to Network Set" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_NetToAdd.name | Write-Verbose

				[void]$_UpdatedNetSet.networkUris.Add($_NetToAdd.uri)

				$a++

			}

		}

		if ($PSBoundParameters['RemoveNetwork'])
		{

			$r = 1

			ForEach ($_NetToREmove in $RemoveNetwork)
			{

				switch ($_NetToRemove.GetType().Name)
				{

					'String'
					{

						if ($_NetToRemove.startswith($EthernetNetworksUri)) 
						{

							"[{0}] Network [$r] is a URI: $_NetToRemove" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							Try
							{

								$_NetToRemove = Send-HPOVRequest -Uri $_NetToAdd -Appliance $ApplianceConnection

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

						}

						elseif ($_NetToRemove -is [string]) 
						{

							"[{0}] Network [$r] is a Name: $_NetToRemove" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							Try
							{

								$_NetToRemove = Get-HPOVNetwork -Name $_NetToRemove -type Ethernet -appliance $ApplianceConnection -ErrorAction Stop

								# [void]$_UpdatedNetSet.networkUris.Add($_networkObject.uri)

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}
								
						}

					}

					'PSCustomObject'
					{

						if ($_NetToRemove.category -eq "ethernet-networks") 
						{

							"[{0}] Network [$r] is a type [PsCustomObject]" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							"[{0}] Network [$r] Name: $($_NetToRemove.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							"[{0}] Network [$r] uri: $($_NetToRemove.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						}

						else 
						{

							$ExceptionMessage = "Network '{0}' is not a supported type '{1}'.  Network resource must be either [System.String] or [PsCustomObject].  Please correct the Parameter value and try again." -f $_NetToRemove.name, $_NetToRemove.gettype().fullname
							$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'RemoveNetwork' -TargetType $_NetToRemove.GetType().Name -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

					default
					{

						$ExceptionMessage = "The provided Network is not a supported type '$($_NetToRemove.gettype().fullname)'.  Network resource must be either [System.String] or [PsCustomObject].  Please correct the Parameter value and try again."
						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'RemoveNetwork' -TargetType $_NetToRemove.GetType().Name -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				"[{0}] REmoving network '{1}' from Network Set" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_NetToRemove.name | Write-Verbose

				[void]$_UpdatedNetSet.networkUris.Remove($_NetToRemove.uri)

				$r++
			}

		}

		if ($PSBoundParameters["UntaggedNetwork"])
		{

			switch ($UntaggedNetwork.GetType().Name)
			{

				'String'
				{

					if ($UntaggedNetwork.startswith($EthernetNetworksUri)) 
					{

						"[{0}] Untagged Network is a URI: $UntaggedNetwork" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Try
						{

							$_UpdatedNetSet.nativeNetworkUri = (Send-HPOVRequest $UntaggedNetwork -Hostname $ApplianceConnection).uri

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

					elseif ($UntaggedNetwork -is [string]) 
					{

						"[{0}] Untagged Network is a Name: $UntaggedNetwork" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Try
						{

							$_networkObject = Get-HPOVNetwork $UntaggedNetwork -type Ethernet -appliance $ApplianceConnection

							$_UpdatedNetSet.nativeNetworkUri = $_networkObject.uri

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}
								
					}

				}

				'PSCustomObject'
				{

					if ($UntaggedNetwork.category -eq "ethernet-networks") 
					{

						"[{0}] Native Network is a type [PsCustomObject]" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						"[{0}] Native Network Name: $($UntaggedNetwork.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						"[{0}] Native Network uri: $($UntaggedNetwork.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					}

					else 
					{

						$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'UntaggedNetwork' -TargetType $UntaggedNetwork.GetType().Name -Message "The UntaggedNetwork '$($UntaggedNetwork.name)' is not a supported type '$($UntaggedNetwork.gettype().fullname)'.  Network resource must be either [System.String] or [PsCustomObject].  Please correct the Parameter value and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

					$_UpdatedNetSet.nativeNetworkUri = $UntaggedNetwork.uri

				}

				default
				{

					$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidArgumentValue InvalidArgument 'UntaggedNetwork' -TargetType $UntaggedNetwork.GetType().Name -Message "The provided UntaggedNetwork is not a supported type '$($UntaggedNetwork.gettype().fullname)'.  Network resource must be either [System.String] or [PsCustomObject].  Please correct the Parameter value and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

		}

		# Process Network Set Bandwidth assignment change
		if ($PSBoundParameters["TypicalBandwidth"] -or $PSBoundParameters["MaximumBandwidth"]) 
		{

			"[{0}] Updating Network bandwidth assignment." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Getting Network Set Connection Template." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
			Try
			{

				$_ct = Send-HPOVRequest $_UpdatedNetSet.connectionTemplateUri -appliance $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
				
			if ($PSBoundParameters["MaximumBandwidth"]) 
			{
				
				"[{0}] Original Maximum bandwidth assignment: $($_ct.bandwidth.maximumBandwidth)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] New Maximum bandwidth assignment: $MaximumBandwidth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_ct.bandwidth.maximumBandwidth = $MaximumBandwidth

			}

			if($PSBoundParameters["TypicalBandwidth"]) 
			{

				"[{0}] Original Typical bandwidth assignment: $($_ct.bandwidth.typicalBandwidth)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] New Typical bandwidth assignment: $TypicalBandwidth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_ct.bandwidth.typicalBandwidth = $TypicalBandwidth
					
			}

			Try
			{

				$_ct = Send-HPOVRequest $_UpdatedNetSet.connectionTemplateUri PUT $_ct -appliance $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		$_UpdatedNetSet = $_UpdatedNetSet | Select-Object * -ExcludeProperty typicalBandwidth, maximumBandwidth, created, modified, state, status
			
		Try
		{

			$_results = Send-HPOVRequest $_UpdatedNetSet.Uri PUT $_UpdatedNetSet -appliance $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		[void]$_TaskCollection.Add($_results)

	}

	End 
	{

		Return $_TaskCollection

	}

}
