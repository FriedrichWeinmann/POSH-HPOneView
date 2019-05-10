function Set-HPOVSanManager 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'BNA')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "BNA")]
		[Alias ('name','Resource')]
		[ValidateNotNullOrEmpty()]
		[object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory = $false, ParameterSetName = "BNA")]
		[ValidateNotNullOrEmpty()]
		[string]$Hostname,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory = $false, ParameterSetName = "BNA")]
		[ValidateNotNullOrEmpty()]
		[ValidateRange(1,65535)]
		[int]$Port = 0,
		 
		[Parameter (Mandatory, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory, ParameterSetName = "BNA")]
		[ValidateNotNullOrEmpty()]
		[string]$Username,

		[Parameter (Mandatory, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory, ParameterSetName = "BNA")]
		[ValidateNotNullOrEmpty()]
		[Object]$Password,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[string]$SnmpUserName,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[ValidateSet ("None","AuthOnly","AuthAndPriv")]
		[ValidateNotNullOrEmpty()]
		[string]$SnmpAuthLevel = "None",

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[ValidateSet ("sha","md5")]	
		[ValidateNotNullOrEmpty()]
		[string]$SnmpAuthProtocol,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[ValidateNotNullOrEmpty()]
		[Object]$SnmpAuthPassword,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[ValidateSet ("aes-128","des56","3des")]	
		[ValidateNotNullOrEmpty()]
		[string]$SnmpPrivProtocol,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[ValidateNotNullOrEmpty()]
		[Object]$SnmpPrivPassword,

		[Parameter (Mandatory = $false, ParameterSetName = "BNA")]
		[switch]$EnableSsl,

		[Parameter (Mandatory = $false, ParameterSetName = "BNA")]
		[switch]$DisableSsl,

		[Parameter (Mandatory = $false, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory = $false, ParameterSetName = "BNA")]
		[switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "HPCisco")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "BNA")]
		[ValidateNotNullorEmpty()]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject']))
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

		$_ResourceUpdateStatus = New-Object System.Collections.ArrayList

	}

	Process
	{

		switch ($InputObject.GetType().Name)
		{

			'PSCustomObject'
			{

				"[$($MyInvocation.InvocationName.ToString().ToUpper())] Object received: {0}" -f ($InputObject | Out-String) | Write-Verbose

				# Generate error if wrong resource type
				if ($InputObject.category -ne 'fc-device-managers')
				{

					$ErrorRecord = New-ErrorRecord HPOneView.SanManagerResourceException InvalidSanManagerResource InvalidArgument 'InputObject' -TargetType 'PSObject' -Message ("The provided Resource object is not a SAN Manager resource.  Expected resource category 'fc-device-managers'.  Received reource category {0}. Please check the value and try again." -f $InputObject.category)

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				# Generate error if wrong resource type
				if (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord HPOneView.SanManagerResourceException InvalidSanManagerResource InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "The provided Resource object is missing the required ApplianceConnection property. Please check the value and try again."

					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			'String'
			{

				"[$($MyInvocation.InvocationName.ToString().ToUpper())] Getting SAN Manager by resource Name: {0}" -f $InputObject | Write-Verbose

				Try
				{

					$InputObject = Get-HPOVSanManager $InputObject -ApplianceConnection $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				

			}

		}

		$_UpdatedSanManager = [PSCustomObject]@{
			connectionInfo = New-Object System.Collections.ArrayList
		}

		switch ($PSBoundParameters.keys)
		{

			'Hostname'
			{

				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "Host"; value = $Hostname})

			}

			'Port'
			{
			
				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "Port"; value = $Port})
					
			}

			'Username'
			{
			
				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "Username"; value = $Username})
			
			}

			'Password'
			{

				if ($Password -is [SecureString])
				{

					$Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

				}

				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "Password"; value = $Password})

			}

			'SnmpUserName'
			{

				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "SnmpUserName"; value = $SnmpUserName})

			}

			'SnmpAuthLevel'
			{

				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "SnmpAuthLevel"; value = $SnmpAuthLevel})

			}
			
			'SnmpAuthProtocol'
			{

				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "SnmpAuthProtocol"; value = $SnmpAuthProtocol})

			}
			
			'SnmpAuthPassword'
			{

				if ($SnmpAuthPassword -is [SecureString])
				{

					$SnmpAuthPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SnmpAuthPassword))

				}

				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "SnmpAuthPassword"; value = $SnmpAuthPassword})

			}
			
			'SnmpPrivProtocol'
			{

				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "SnmpPrivProtocol"; value = $SnmpPrivProtocol})

			}
			
			'SnmpPrivPassword'
			{

				if ($SnmpPrivPassword -is [SecureString])
				{

					$SnmpPrivPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SnmpPrivPassword))

				}

				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "SnmpPrivPassword"; value = $SnmpPrivPassword})

			}
			
			'DisableSsl'
			{

				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "UseSsl"; value = $false})

			}
			
			'EnableSsl'
			{

				[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "UseSsl"; value = $true})

			}

		}

		# Add missing ConnectionInfo properties to complete request
		if (-not $PSBoundParameters['Hostname'])
		{

			[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "Host"; value = ($InputObject.connectionInfo | Where-Object Name -eq Host).value})

		}

		if (-not $PSBoundParameters['Port'])
		{

			[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "Port"; value = ($InputObject.connectionInfo | Where-Object Name -eq Port).value})
			
		}

		if (-not $PSBoundParameters['EnableSsl'] -and -not $PSBoundParameters['DisableSsl'] -and $InputObject.providerDisplayName -eq 'Brocade Network Advisor')
		{

			[void]$_UpdatedSanManager.connectionInfo.Add(@{name = "UseSsl"; value = ($InputObject.connectionInfo | Where-Object Name -eq UseSsl).value})
			
		}

		"[$($MyInvocation.InvocationName.ToString().ToUpper())] Updated SAN Manager: {0}" -f ($_UpdatedSanManager | out-string) | Write-Verbose 

		"[{0}] Sending request"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Try
		{

			$resp = Send-HPOVRequest $InputObject.uri PUT $_UpdatedSanManager -ApplianceConnection $InputObject.ApplianceConnection.Name

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not $PSBoundParameters['Async'])
		{

			$resp = $resp | Wait-HPOVTaskComplete 

		}
	 
		[void]$_ResourceUpdateStatus.Add($resp)
		   
	}
		
	End
	{
		return $_ResourceUpdateStatus

	}

}
