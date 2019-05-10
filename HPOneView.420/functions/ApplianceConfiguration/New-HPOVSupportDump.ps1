function New-HPOVSupportDump 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "values")]
	Param 
	(

		[Parameter (Mandatory = $false,ValueFromPipeline = $false, ParameterSetName = "values")]
		[Parameter (Mandatory = $false,ValueFromPipeline = $false, ParameterSetName = "Object")]
		[Alias ("save")]
		[string]$Location = (get-location).Path,

		[Parameter (Mandatory,ValueFromPipeline = $false, ParameterSetName = "values")]
		[ValidateSet ("Appliance","LI")]
		[string]$Type,

		[Parameter (Mandatory = $false,ValueFromPipeline = $false, ParameterSetName = "values")]
		[switch]$Encrypted,

		[Parameter (Mandatory,ValueFromPipeline, ParameterSetName = "Object")]
		[Alias ('liobject','li','name')]
		[object]$LogicalInterconnect,
	
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "values")]
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "Object")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters["LogicalInterconnect"]) -and $PSCmdlet.ParameterSetName -eq "Object") 
		{ 
			
			$PipelineInput = $true 
		
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
		
		# Validate the path exists.  If not, create it.
		"[{0}] Validating $($Location) exists" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not(Test-Path $Location)) 
		{ 
			
			"[{0}] $($Location) Directory does not exist.  Creating directory..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			New-Item -ItemType directory -path $Location 
		
		}

	}

	Process
	{

		if ($PipelineInput -and $LogicalInterconnect)
		{

			"[{0}] Pipeline object: $($LogicalInterconnect.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Validate input object is a Logical Interconnect resource
			if ($LogicalInterconnect.category -ne 'logical-interconnects')
			{

				$ErrorRecord = New-ErrorRecord HPOneView.LogicalInterconnectResourceException InvalidLogicalInterconnectResource InvalidArgument 'LogicalInterconnect' -TargetType $LogicalInterconnect.GetType().Name -Message "The LogicalInterconnect Parameter value is invalid.  Resource category provided '$($LogicalInterconnect.category)', expected 'logical-interconnects'.  Please check the value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}
			
			$Request = [PSCustomObject]@{errorCode = $LogicalInterconnect.name}

			$targetURI = $LogicalInterconnect.uri + "/support-dumps"

			"[{0}] Received information from pipeline" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Request : $($request | out-string) " -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] URI: $($targetURI)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Send the request
			Write-Host "Please wait while the Support Dump is generated.  This can take a few minutes..."

			Try
			{

				$resp = Send-HPOVRequest $targetUri POST $Request -Hostname $LogicalInterconnect.ApplianceConnection.Name

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# Now that the Support Dump has been requested, download the file
			Try
			{

				Download-File $resp.uri $LogicalInterconnect.ApplianceConnection.Name $Location

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		else 
		{

			"[{0}] Support Dump Type: $($type)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			switch ($Type)
			{
						
				"appliance" 
				{

					ForEach ($_appliance in $ApplianceConnection)
					{

						#Build the request and specify the target URI. Do not change errorCode value.
						"[{0}] Requesting Appliance Support Dump..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$request = [PSCustomObject]@{
								
							errorCode = "CI";
							encrypt   = [bool]$Encrypted.IsPresent
							
						}

						$targetURI = $ApplianceSupportDumpUri
							
						"[{0}] Request : $($request | out-string) " -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						"[{0}] URI: $($targetURI)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						# Send the request
						Write-Host "Please wait while the Support Dump is generated.  This can take a few minutes..."

						Try
						{

							$resp = Send-HPOVRequest $targetUri POST $Request -Hostname $_appliance

						}
							
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						# Now that the Support Dump has been requested, download the file
						Try
						{

							Download-File $resp.uri $_appliance.Name $Location

						}
							
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}					

				}
							
				"li" 
				{ 

					"[{0}] Requesting $LogicalInterconnect Support Dump..." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
							
					if ($LogicalInterconnect -is [String]) 
					{

						Try
						{

							$resp = Get-HPOVLogicalInterconnect -InputObject $LogicalInterconnect -Hostname $ApplianceConnection

						}
							
						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}
					
						$request = @{errorCode = $resp.name.SubString(0,10)}
						
						$targetURI = $resp.uri + "/support-dumps"
						
						"[{0}] Processing '$($resp.name) Logical Interconnect" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose


					}

					elseif ($LogicalInterconnect -is [PSCustomObject]) 
					{
							
						"[{0}] Logical Interconnect Object provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						"[{0}] Processing '$($LogicalInterconnect.name) Logical Interconnect" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$request = @{errorCode = $LogicalInterconnect.name.SubString(0,10)}

						$targetUri = $LogicalInterconnect.uri

					}

					# Send the request
					Write-Host "Please wait while the Support Dump is generated.  This can take a few minutes..."

					Try
					{

						$resp = Send-HPOVRequest $targetUri POST $Request -Hostname $ApplianceConnection

					}
							
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					# Now that the Support Dump has been requested, download the file
					Try
					{

						Download-File $resp.uri $ApplianceConnection.Name $Location

					}
							
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

			} 
					
		}

	}

	End 
	{
		
		"Done." | Write-Verbose
			
	}

}
