function Update-HPOVServerHardwareLicenseIntent
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(
	
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Alias ("name",'Server')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
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

			"[{0}] Server object provided by pipeline." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

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

	}
	
	Process 
	{

		# Validate input object type
		# Checking if the input is System.String and is NOT a URI
		if (($InputObject -is [string]) -and (-not($InputObject.StartsWith($ServerHardwareUri)))) 
		{
			
			"[{0}] Server is a Server Name: $($InputObject)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Getting Server from Name" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_InputObject = Get-HPOVServer -Name $InputObject -ErrorAction Stop -ApplianceConnection $ApplianceConnection

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		# Checking if the input is System.String and IS a URI
		elseif (($InputObject -is [string]) -and ($InputObject.StartsWith($ServerHardwareUri))) 
		{
			
			"[{0}] Server is a Server device URI: $($InputObject)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_InputObject = Send-HPOVRequest -Uri $InputObject -Hostname $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
		
		}

		# Checking if the input is PSCustomObject, and the category type is server-profiles, which could be passed via pipeline input
		elseif (($InputObject -is [System.Management.Automation.PSCustomObject]) -and ($InputObject.category -ieq $ResourceCategoryEnum.ServerHardware)) 
		{

			"[{0}] Server is a Server Device object: $($InputObject.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_InputObject = $InputObject.PSObject.Copy()
		
		}

		# Checking if the input is PSCustomObject, and the category type is server-hardware, which would be passed via pipeline input
		elseif (($InputObject -is [System.Management.Automation.PSCustomObject]) -and ($InputObject.category -ieq $ResourceCategoryEnum.ServerProfile)) 
		{
			
			"[{0}] Server is a Server Profile object: $($InputObject.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Getting server hardware device assigned to Server Profile." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if (-not($InputObject.serverHardwareUri))
			{

				$ExceptionMessage = "The Server Profile '{0}' is unassigned.  This cmdlet only supports Server Profiles that are assigned to Server Hardware resources. Please check the input object and try again." -f $InputObject.name
				$ErrorRecord = New-ErrorRecord InvalidOperationException ServerProfileUnassigned InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Try
			{

				$_InputObject = Send-HPOVRequest -Uri $InputObject.serverHardwareUri -Hostname $ApplianceConnection.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
		
		}

		else 
		{

			$ExceptionMessage = "The Parameter 'InputObject' value is invalid.  Please validate the 'InputObject' Parameter value you passed and try again."
			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# If server is not Managed, generate error
		if ($_InputObject.state -eq "Monitored")
		{

			$ExceptionMessage = "The provided server hardware resource {0} is a Monitored resource.  This Cmdlet only supports Managed server hardware." -f $_InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneView.ServerHardwareResourceException UnsupportedResourceState InvalidArgument 'InputObject' -TargetType $_InputObject.GetType().Name -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		"[{0}] Checking Server Hardware if it is licensed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

		$_Uri = "/rest/licenses?filter=nodeId EQ '{0}'" -f $_InputObject.uuid

		# The licensing intent of the server is changed, and if a license of the intended type is available, 
		# it is applied to the server. Once licensed, the only permitted change is an upgrade from "OneViewNoiLO" to "OneView".
		# The server must be unlicensed and managed in order to be able to update the licensing intent. 
		# 		[
		#     { "op": "replace", "path": "/licensingIntent", "value": "OneView"}
		# ]


		Try
		{

            $_IsLicensed = Send-HPOVRequest -Uri $_uri -Hostname $_InputObject.ApplianceConnection
		
		}
		
		Catch
		{
		
			$PSCmdlet.ThrowTerminatingError($_)
		
		}

		# server is already licensed. generate an error
		if ($_IsLicensed.members[0].licenseType -ne 'Unlicensedproduct' -and 
		    $_IsLicensed.members[0].product -eq 'HPE OneView Advanced')
		{

			$ExceptionMessage = "The provided server hardware resource {0} is a Monitored resource.  This Cmdlet only supports updating the license allocation policy (intent) from 'HPE OneView Advanced without iLO Advanced' to 'HPE OneView Advanced'." -f $_InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneView.ServerHardwareResourceException UnsupportedLicenseStateChange InvalidOperation 'InputObject' -TargetType $_InputObject.GetType().Name -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}
	
		$_PatchOperation = NewObject -PatchOperation

		$_PatchOperation.op    = "replace"
		$_PatchOperation.path  =  "/licensingIntent"
		$_PatchOperation.value = "OneView"

		$_uri = $_InputObject.uri

		Try
		{

            $_resp = Send-HPOVRequest -Uri $_uri -Method PATCH -Body $_PatchOperation -Hostname $_InputObject.ApplianceConnection
		
		}
		
		Catch
		{
		
			$PSCmdlet.ThrowTerminatingError($_)
		
		}

		if ($PSBoundParameters['Async'])
		{

			$_resp

		}

		else
		{

			$_resp | Wait-HPOVTaskComplete

		}
	
	}

	End
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}
	
}
