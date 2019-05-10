function Update-HPOVServer
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(
	
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'RefreshWithCredentials')]
		[ValidateNotNullOrEmpty()]
		[Alias ("name",'Server')]
		[object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "RefreshWithCredentials")]
		[String]$Hostname,

		[Parameter (Mandatory, ParameterSetName = "RefreshWithCredentials")]
		[PSCredential]$Credential,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'RefreshWithCredentials')]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'DefRefreshWithCredentialsault')]
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
		elseif (($InputObject -is [System.Management.Automation.PSCustomObject]) -and ($InputObject.category -ieq "server-hardware")) 
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

		"[{0}] Refreshing Server Hardware device: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_InputObject.name | Write-Verbose 
		
        $_uri = $_InputObject.uri + "/refreshState"

		$_body = @{
			
			refreshState = 'RefreshPending'
			
		}

		# NEED TO VALIDATE THE CORRECT STATEREASON
		if ($_InputObject.state -ieq 'Unmanaged' -and $_InputObject.stateReason -ieq 'Unconfigured')
		{

			if (-not $PSBoundParameters['Credential'])
			{

				$ExceptionMessage = "The appliance can no longer communicate with {0} server hardware, and requires valid Credentials." -f $_InputObject.name
				$ErrorRecord = New-ErrorRecord HPOneView.Library.UnsupportedArgumentException MissingRequiredUsernameParameter InvalidOperation 'Enclosure' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if (-not $PSBoundParameters['Hostname'])
			{

				"[{0}] Caller did not supply Hostname.  Will use server hardware mpHostInfo value: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_InputObject.mpHostInfo.mpHostName | Write-Verbose

				$Hostname = $_InputObject.mpHostInfo.mpHostName

			}

			$_body.Add('hostname', $Hostname)
			$_body.Add('username', $Credential.Username)
			$_body.Add('password', [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)))

		}
		
		Try
		{

            $_resp = Send-HPOVRequest -Uri $_uri -Method PUT -Body $_body -Hostname $_InputObject.ApplianceConnection
		
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
