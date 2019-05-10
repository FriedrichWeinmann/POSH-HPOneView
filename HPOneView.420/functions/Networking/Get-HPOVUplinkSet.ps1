function Get-HPOVUplinkSet 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Name")]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "Name")]
		[ValidateNotNullorEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "Name")]
		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "Type")]
		[ValidateNotNullorEmpty()]
		[Alias ('liname')]
		[object]$LogicalInterconnect,

		[Parameter (Mandatory = $false, ParameterSetName = "Type")]
		[ValidateSet ('Ethernet','FibreChannel', IgnoreCase=$False)]
		[string]$Type,
	
		[Parameter (Mandatory = $false, ParameterSetName = "Name")]
		[Parameter (Mandatory = $false, ParameterSetName = "Type")]
		[switch]$Report,

		[Parameter (Mandatory = $false, ParameterSetName = "Name")]
		[Parameter (Mandatory = $false, ParameterSetName = "Type")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false, ParameterSetName = "Name")]
		[Parameter (Mandatory = $false, ParameterSetName = "Type")]
		[Alias ("x", "export")]
		[ValidateScript({split-path $_ | Test-Path})]
		[String]$ExportFile

	)
	
	Begin 
	{

		if ($PSBoundParameters['report'])
		{

			Write-Warning "The Report Parameter has been deprecated.  The CMDLET will now display object data in Format-List view."

		}

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

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

		$_UplinkSetCollection = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		if ($LogicalInterconnect -is [PSCustomObject])
		{

			$ApplianceConnection = $ApplianceConnection | Where-Object { $_.Name -eq $LogicalInterconnect.ApplianceConnection.Name }

		}

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '$($_appliance.Name)' Appliance" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Looking for UplinkSet Name without LI Object/Resource
			if ($PSCmdlet.ParameterSetName -eq 'Name' -and (-not($PSBoundParameters['LogicalInterconnect']))) 
			{

				if ($PSboundParameters['Name'])
				{

					"[{0}] Uplink Set name provided: '$name'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$name = $name -replace ("[*]","%25") -replace ("[&]","%26")

					# We will crate a URI that uses filter at the resource URI
					$uri = $uplinkSetsUri + "?filter=name matches '$name'"

				}

				else
				{

					"[{0}] Looking for all Uplink Sets." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$uri = $uplinkSetsUri

				}

				Try
				{

					$_uplinksets = Send-HPOVRequest -Uri $uri -Method GET -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}				

				if ($_uplinksets.count -eq 0 -and $Name)
				{

					# Generate Error if no name was found
					$ExceptionMessage = "Specified Uplink Set '{0}' was not found on '{1}'.  Please check the name and try again." -f $Name, $_appliance.Name
					$ErrorRecord = New-ErrorRecord InvalidOperationException UplinkSetResourceNameNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)  

				}

				elseif ($_uplinksets.count -eq 0)
				{

					"[{0}] No Uplink Sets found for {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

				}

				else
				{

					$_uplinksets = $_uplinksets.members

				}

			}

			# Looking for LI Object and associated Uplink Sets
			elseif ($PSboundParameters['LogicalInterconnect']) # -and (-not($PSBoundParameters['Name']))) 
			{

				# Check the LogicalInterconnect Parameter value type
				switch ($LogicalInterconnect.GetType().Name)
				{
				
					'PSCustomObject'
					{

						"[{0}] Received PSCustomObject for LogicalInterconnect Parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						if ($LogicalInterconnect.category -eq 'logical-interconnects')
						{

							"[{0}] Logical Interconnect Object provided: $($LogicalInterconnect )." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						}
						
						else
						{

							"[{0}] Invalid Logical Interconnect Object provided: $($LogicalInterconnect | Out-String)." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$ErrorRecord = New-ErrorRecord InvalidOperationException LogicalInterconnectInvalidCategroy InvalidArgument 'LogicalInterconnect' -TargetType 'PSObject' -Message "The provided LogicalInterconnect resource category '$($LogicalInterconnect.category)' does not match the required 'logical-interconnects' value.  Please check the Parameter value and try again."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

						}

					}

					'String'
					{

						# User provided Logical Interconnect Name, look for it on the appliance
						if (-not($LogicalInterconnect.StartsWith('/rest/')) -or (-not($LogicalInterconnect.StartsWith($logicalInterconnectsUri))))
						{

							"[{0}] Logical Interconnect name provided: 'LogicalInterconnect'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							Try
							{

								"[{0}] Getting Logical Interconnect '$liName'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

								$LogicalInterconnect = Get-HPOVLogicalInterconnect -Name $LogicalInterconnect -ApplianceConnection $_appliance

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

						}

						# User didn't provide a Logical Interconnect Resource Name, generate error as URI's are not supported
						else
						{

							"[{0}] Invalid Logical Interconnect Parameter value provided: $($LogicalInterconnect | Out-String)." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidLogicalInterconnectParameterValue InvalidArgument 'LogicalInterconnect' -TargetType 'PSObject' -Message "The provided LogicalInterconnect resource category '$($LogicalInterconnect.category)' does not match the required 'logical-interconnects' value.  Please check the Parameter value and try again."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord) 

						}
						
					}
				
				}

				# Use Index to find associations
				try 
				{ 
				
					$_uplinksets = New-Object System.Collections.ArrayList

					"[{0}] Looking for associated Uplink Sets to Logical Interconnects via Index." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_uri = '{0}?parentUri={1}&name=LOGICAL_INTERCONNECT_TO_UPLINK_SET' -f $AssociationsUri, $LogicalInterconnect.uri
						$_indexassociatedulinksets = Send-HPOVRequest -Uri $_uri -Hostname $_appliance

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
					if ($_indexassociatedulinksets.count -gt 0)
					{

						ForEach ($child in $_indexassociatedulinksets.members)
						{

							$_uplinksetobject = Send-HPOVRequest $child.childUri -Hostname $_appliance

							if ($Name)
							{

								"[{0}] Filtering Uplink Sets for '$Name'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
						
								if ($Name -match "\*" -or $Name -match "\?")
								{

									if ($_uplinksetobject.name -match $Name)
									{

										[void]$_uplinksets.Add($_uplinksetobject)

									}

								}

								else
								{

									if ($_uplinksetobject.name -eq $Name)
									{

										[void]$_uplinksets.Add($_uplinksetobject)

									}

								}

							}

							elseif ($type) 
							{

								"[{0}] Filtering Uplink Sets for '$type' type." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
								if ($_uplinksetobject.networkType -eq $type)
								{

									[void]$_uplinksets.Add($_uplinksetobject)

								}

							}
							
						}
						
					}
					
					
					if ($Name -and $_uplinksets.count -eq 0)
					{
						
						# Generate Error if no name was found
						$ErrorRecord = New-ErrorRecord InvalidOperationException UplinkSetResourceNameNotFound ObjectNotFound 'Name' -Message "Specified Uplink Set '$name' was not found associated with '$($LogicalInterconnect.name)' on '$($_appliance.Name)'.  Please check the name and try again."
						$PSCmdlet.WriteError($ErrorRecord)  

					}

					elseif ($type -and $_uplinksets.count -eq 0)
					{

						$ErrorRecord = New-ErrorRecord InvalidOperationException UplinkSetResourceTypeNotFound ObjectNotFound 'Type' -Message "Specified Uplink Set Type '$type' was not found associated with '$($LogicalInterconnect.name)' on '$($_appliance.Name)'.  Please check the name and try again."
						$PSCmdlet.WriteError($ErrorRecord)  
					
					}

				}

				catch 
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			# Update TypeNames
			if ($_uplinksets.count -gt 0)
			{

				foreach ($_object in $_uplinksets)
				{

					switch ($_object.networkType)
					{

						'Ethernet'     
						{ 

							$_object.PSObject.TypeNames.Insert(0,'HPOneView.Networking.LogicalInterconnect.UplinkSet.Ethernet') 
							$_object.portConfigInfos | ForEach-Object {
								
								Add-Member -InputObject $_ -NotePropertyName ApplianceConnection -NotePropertyValue $_object.ApplianceConnection

								$_.PSObject.TypeNames.Insert(0,'HPOneView.Networking.LogicalInterconnect.UplinkSet.Ethernet.UplinkPort') 

							}
							
						}

						'FibreChannel' 
						{ 
						
							$_object.PSObject.TypeNames.Insert(0,'HPOneView.Networking.LogicalInterconnect.UplinkSet.FibreChannel') 
							$_object.portConfigInfos | ForEach-Object {
								
								Add-Member -InputObject $_ -NotePropertyName ApplianceConnection -NotePropertyValue $_object.ApplianceConnection

								$_.PSObject.TypeNames.Insert(0,'HPOneView.Networking.LogicalInterconnect.UplinkSet.FibreChannel.UplinkPort') 

							}
						
						}

					}

					"[{0}] Adding '$($_object.name)' to final collection." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					[void]$_UplinkSetCollection.Add($_object)

				}

			}

		}

	}

	End 
	{
							
		$_UplinkSetCollection | sort-object -Property networkType,name

		"[{0}] Done. $($_UplinkSetCollection.count) uplink set(s) found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
