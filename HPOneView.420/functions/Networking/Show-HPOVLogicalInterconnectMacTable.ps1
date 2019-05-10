function Show-HPOVLogicalInterconnectMacTable 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "MACAddress")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Pipeline")]
		[ValidateNotNullorEmpty()]
		[Alias ("name","li","LogicalInterconnect")]
		[object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "Pipeline")]
		[ValidateNotNullorEmpty()]
		[string]$network,

		[Parameter (Mandatory = $false, ParameterSetName = "MACAddress")]
		[validatescript({if ($_ -match $script:macAddressPattern) {$true} else { throw "The input value '$_' does not match 'aa:bb:cc:dd:ee:ff'. Please correct the value and try again."}})]
		[Alias ("mac")]
		[string]$MacAddress,

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "MACAddress")]
		[Parameter (Mandatory = $false, ParameterSetName = "Pipeline")]
		[Alias ("x", "ExportFile")]
		[ValidateScript({split-path $_ | Test-Path})]
		[String]$Export,
		
		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Parameter (Mandatory = $false, ParameterSetName = "MACAddress")]
		[Parameter (Mandatory = $false, ParameterSetName = "Pipeline", ValueFromPipelineByPropertyName)]
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
		
		if ($PSCmdlet.ParameterSetName -ne 'Pipeline')
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

		$MacTables = New-Object System.Collections.ArrayList

	}

	Process 
	{

		"[{0}] Logical Interconnect via PipeLine: $PipelineInput" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($InputObject))
		{

			"[{0}] No Logical Interconnects provided via Parameter. Getting all LI resources." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$InputObject = Get-HPOVLogicalInterconnect

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		ForEach ($li in $InputObject) 
		{

			if ($li -is [PSCustomObject] -and $li.category -eq "logical-interconnects") 
			{

				"[{0}] Logical Interconnect object provided: $($li.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Logical Interconnect object URI: $($li.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$uri = $li.uri +"/forwarding-information-base"

			}

			else 
			{

				# Unsupported type
				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'LogicalInterconnect' -TargetType $li.GetType().Name -Message "The Parameter -LogicalInterconnect contains an invalid Parameter value type, '$($li.gettype().fullname)' is not supported.  Only [PSCustomObject] type is allowed."
				$PSCmdlet.WriteError($ErrorRecord)

			}

			# Filter the request for a specific Network
			if ($Network) 
			{
				
				"[{0}] Filtering for '$Network' Network Resource" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				
				$_Network = Get-HPOVNetwork $network -ApplianceConnection $li.ApplianceConnection.Name

				$_internalVlanId = $_Nework.internalVlanId

				$uri += "?filter=internalVlan=$_internalVlanId"

				"[{0}] Processing $uri" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$resp = (Send-HPOVRequest $uri -Hostname $li.ApplianceConnection.Name).members

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				

			}

			elseif ($MacAddress) 
			{

				"[{0}] Filtering for MAC Address '$MacAddress'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$uri += "?filter=macAddress='$MacAddress'"

				"[{0}] Processing $uri" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$resp = (Send-HPOVRequest $uri -Hostname $li.ApplianceConnection.Name).members

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}				

			}

			else 
			{

				"[{0}] Generating '{1}' mactable file." -f $MyInvocation.InvocationName.ToString().ToUpper(), $uri | Write-Verbose

				Try
				{

					#$MacTableFile = (Send-HPOVRequest -Uri $uri -Metho POST -Hostname $li.ApplianceConnection.Name).members
					$MacTableFile = Send-HPOVRequest -Uri $uri -Metho POST -Hostname $li.ApplianceConnection.Name

					# "[{0}] MacTable Contents: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($MacTableFile ) | Write-Verbose

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				

				if ("Success","Completed" -match $MacTableFile.state -and -not([System.String]::IsNullOrWhiteSpace($MacTableFile))) 
				{

					"[{0}] Processing '{1}' mactable file." -f $MyInvocation.InvocationName.ToString().ToUpper(), $MacTableFile.uri | Write-Verbose

					Try
					{

						$resp = Download-MacTable $MacTableFile

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				elseif ([System.String]::IsNullOrWhiteSpace($MacTableFile))
				{

					$Message = 'The results returned are null.  This Cmdlet is not supported with the HPE OneView DCS appliance.'
					$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidInterconnectFibDataInfo InvalidOperation 'InputObject' -Message $Message
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				else 
				{

					$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidInterconnectFibDataInfo InvalidResult 'InputObject' -Message ($macTableFile.state + ": " + $macTableFile.status)
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}


			}

			$resp | ForEach-Object {

				"[{0}] Adding $($_.address) to collection" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[void]$MacTables.Add($_)

			} 

		}

	}

	End 
	{

		if ($list) 
		{
			
			"[{0}] Displaying formatted table." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($name -or $MacAddress) 
			{

				$m = @{Expression={($_.interconnectName -split ",")[0]};Label="Enclosure"},
					 @{Expression={($_.interconnectName -split ",")[1]};Label="Interconnect"},		         
					 @{Expression={$_.networkInterface};Label="Interface"},
					 @{Expression={$_.macAddress};Label="Address"},
					 @{Expression={$_.entryType};Label="Type"},
					 @{Expression={$_.networkName};Label="Network"},
					 @{Expression={$_.externalVlan};Label="VLAN"}

			}

			else 
			{

				$m = @{Expression={$_.Enclosure};Label="Enclosure"},
					 @{Expression={$_.Interconnect};Label="Interconnect"},
					 @{Expression={$_.Interface};Label="Interface"},
					 @{Expression={$_.address};Label="Address"},
					 @{Expression={$_.type};Label="Type"},
					 @{Expression={$_.network};Label="Network"},
					 @{Expression={$_.extVlan};Label="VLAN"},
					 @{Expression={$_.LAGPorts};Label="LAG Ports"}

			}

			$MacTables | Sort-Object "Enclosure","Interconnect",macAddress | format-table $m -autosize

		}

		elseif ($PSBoundParameters['Export']) 
		{

			"[{0}] Exporting to CSV file: $Export" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$MacTables | Sort-Object Enclosure,Interconnect,macAddress | Export-CSV $Export -NoTypeInformation

		}
		else 
		{

			"[{0}] Displaying results." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$MacTables | Sort-Object Enclosure,Interconnect,macAddress

		}
		
		"[$($MyInvocation.InvocationName.ToString().ToUpper())] Done. {0} mac table entry(ies) found." -f $MacTables.Count | Write-Verbose

	}

}
