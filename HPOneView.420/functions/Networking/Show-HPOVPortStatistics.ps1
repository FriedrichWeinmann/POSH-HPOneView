function Show-HPOVPortStatistics 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "InterconnectPort")]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Pipeline")]
		[Parameter (Mandatory = $false, ParameterSetName = "InterconnectPort")]
		[object]$Port,

		[Parameter (Mandatory, ParameterSetName = "InterconnectPort")]
		[object]$Interconnect,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Pipeline")]
		[Parameter (Mandatory = $false, ParameterSetName = "InterconnectPort")]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($PSCmdlet.ParameterSetName -eq 'Pipeline')
		{

			"[{0}] Port object provided by pipeline." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

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

		$_PortStatsCol = New-Object System.Collections.ArrayList
	
	}

	Process 
	{

		Switch ($PSCmdlet.ParameterSetName) 
		{

			"Pipeline" 
			{

				switch ($Port.GetType().Name)
				{

					# Do not support String Port values via pipeline, so generate error
					"String" 
					{

						$ErrorRecord = New-ErrorRecord HPOneView.InterconnectPortResourceException InvalidInterconnectPortParameter InvalidArgument 'Port' -Message "The -Port Parameter only supports Objects via the pipeline.  Please refer to the CMDLET help for proper pipeline syntax."

						$PSCmdlet.ThrowTerminatingError($ErrorRecord)  
						
					}

					"PSCustomObject" 
					{

						"[{0}] Port Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Port.name, $Port.uri | Write-Verbose

						# Validate the Port Object is type Port
						if ($Port.category -ne "ports") 
						{

							$ErrorRecord = New-ErrorRecord HPOneView.InterconnectPortResourceException InvalidInterconnectPortObject InvalidArgument 'Port' -TargetType "PSObject" -Message ("The object for the -Port Parameter is the wrong type: {0}.  Expected category 'ports'.  Please check the object provided and try again." -f $Port.category )
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

						}

						Try
						{

							"[{0}] Getting Interconnect resource from Port Object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$_InterconnectUri = $Port.uri.SubString(0,$Port.uri.IndexOf('/ports/' + $Port.portId))

							$Interconnect = Send-HPOVRequest $_InterconnectUri -ApplianceConnection $Port.ApplianceConnection.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

				}

			}

			"InterconnectPort" 
			{ 

				switch ($Interconnect.GetType().Name)
				{

					"String" 
					{


						"[{0}] Getting Interconnect object '$Interconnect'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Try
						{

							$Interconnect = Get-HPOVInterconnect $Interconnect -ApplianceConnection $ApplianceConnection

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

					"PSCustomObject" 
					{

						"[{0}] Interconnect Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Interconnect.name, $Interconnect.uri | Write-Verbose

						# Validate the Port Object is type Port
						if ($Interconnect.category -ne 'interconnects') 
						{

							$ErrorRecord = New-ErrorRecord HPOneView.InterconnectPortResourceException InvalidInterconnectPortObject InvalidArgument 'Interconnect' -TargetType "PSObject" -Message ("The object for -Interconnect Parameter is the wrong resource category: {0}.  Expected type 'interconnects'.  Please check the object provided and try again." -f  $Interconnect.category)

							$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

						}

					}

				}

				if ($PSBoundParameters['Port'])
				{

					if ($Port -is [String])
					{

						"[$($MyInvocation.InvocationName.ToString().ToUpper())] Filtering for '{0}' within '{1}' Interconnect." -f $Port, $Interconnect.name | Write-Verbose 

						$_originalport = $Port

						$Port = $Interconnect.ports | Where-Object portName -like $Port

						if (-not($Port)) 
						{

							$ErrorRecord = New-ErrorRecord HPOneView.InterconnectPortResourceException InvalidInterconnectPort InvalidArgument 'Port' -Message ("The the port '{0}' was not found within '{1}'.  Available ports within the interconnect are '{2}' Please check the port value and try again." -f $_originalport, $Interconnect.name, ($interconnect.ports.portName -join ",") )

							$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

						}

					}

					elseif ($Port -is [PSCustomObject])
					{

						$_originalport = $Port.PSObject.Copy()

						"[$($MyInvocation.InvocationName.ToString().ToUpper())] Filtering for '{0}' within '{1}' Interconnect." -f $Port.name, $Interconnect.name | Write-Verbose 

						$Port = $Interconnect.ports | Where-Object portName -like $Port.name

						if (-not($Port)) 
						{

							$ErrorRecord = New-ErrorRecord HPOneView.InterconnectPortResourceException InvalidInterconnectPort InvalidArgument 'Port' -TargetType 'PSObject' -Message ("The the port '{0}' was not found within '{1}'.  Available ports within the interconnect are '{2}' Please check the port value and try again." -f $_originalport.name, $Interconnect.name, ($interconnect.ports.portName -join ",") )

							$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

						}

					}

				}

			}

		}

		Try
		{

			$_InterconnectStats = Send-HPOVRequest ($Interconnect.uri + "/statistics") -ApplianceConnection $ApplianceConnection.Name

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}
		
		$_InterconnectStats | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.Networking.InterconnectStatistics") }

		if ($Port) 
		{ 
			
			$_InterconnectStats.portStatistics = $_InterconnectStats.portStatistics | Where-Object { $port.portName -contains $_.portName } 
		
		}

		# Set the specific TypeNames value for Formats to handle
		foreach ($_PortObj in $Interconnect.ports) 
		{

			switch ($_PortObj.configPortTypes) 
			{

				{@("EnetFcoe","Ethernet") -match $_ } 
				{

					$TypeName    = "HPOneView.Networking.PortStatistics.Ethernet"
					$SubTypeName = "Ethernet"
					Break

				}

				"FibreChannel" 
				{

					$TypeName    = "HPOneView.Networking.PortStatistics.FibreChannel"
					$SubTypeName = "FibreChannel"
					Break

				}

			}

			"[$($MyInvocation.InvocationName.ToString().ToUpper())] inserting '{0}' into '{1}' [{2}]" -f $TypeName, $_PortObj.name, ($_PortObj.configPortTypes -join ",") | Write-Verbose 

			($_InterconnectStats.portStatistics | Where-Object portName -eq $_PortObj.portName ).PSObject.TypeNames.Insert(0,$TypeName)
			($_InterconnectStats.portStatistics | Where-Object portName -eq $_PortObj.portName ) | Add-Member -NotePropertyName portConfigType -NotePropertyValue $SubTypeName -force
		}

		# Insert sampleInterval from the Interconnect itself. Otherwise, portStatistics doesn't contain the interval.
		$_InterconnectStats.portStatistics | ForEach-Object { Add-Member -InputObject $_ -NotePropertyName sampleInterval -NotePropertyValue $_InterconnectStats.moduleStatistics.portTelemetryPeriod -force }

		$_InterconnectStats.portStatistics | sort-Object portConfigType,portName | ForEach-Object {

			[void]$_PortStatsCol.Add($_)

		}

	}

	End 
	{

		Return $_PortStatsCol

	}

}
