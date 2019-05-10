function Set-HPOVAddressPoolSubnet
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'IPv4')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "IPv4")]
		[Alias ('Subnet','IPv4Subnet')]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "IPv4")]
		[ValidateScript({ [string]::IsNullOrEmpty($_) -or
			$_ -match [Net.IPAddress]$_})]
		[Net.IPAddress]$SubnetMask,

		[Parameter (Mandatory = $false, ParameterSetName = "IPv4")]
		[ValidateScript({ [string]::IsNullOrEmpty($_) -or
			$_ -match [Net.IPAddress]$_})]
		[Net.IPAddress]$Gateway,

		[Parameter (Mandatory = $false, ParameterSetName = "IPv4")]
		[ValidateNotNullorEmpty()]
		[String]$Domain,

		[Parameter (Mandatory = $false, ParameterSetName = "IPv4")]
		[ValidateNotNullorEmpty()]
		[Array]$DNSServers,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName , ParameterSetName = "IPv4")]
		[ValidateNotNullorEmpty()]
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

		$_SubnetCollection = New-Object System.Collections.ArrayList
					
	}

	Process
	{

		# Validate IPv4Subnet object
		if ($InputObject.category -ne 'id-range-IPv4-subnet')
		{

			"[{0}] Invalid IPv4 Address Pool resource object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$ErrorRecord = New-ErrorRecord HPOneView.Appliance.AddressPoolResourceException InvalidIPv4AddressPoolResource InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "An invalid IPv4 Address Pool resource object was provided.  Please verify the Parameter value and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}
		
		switch ($PSBoundParameters.keys)
		{

			'SubnetMask'
			{

				$InputObject.subnetMask = $SubnetMask.IPAddressToString

			}

			'Gateway'
			{

				$InputObject.gateway = $Gateway.IPAddressToString

			}

			'Domain'
			{

				$InputObject.domain = $Domain

			}

			'DNSServers'
			{

				$InputObject.DNSServers = New-Object System.Collections.ArrayList

				$DNSServers | ForEach-Object { [void]$InputObject.DNSServers.Add($_) }

			}

		}

		# "[{0}] Defining new IPv4 Subnet object: {0}" -f ($InputObject ) | Write-Verbose 

		"[{0}] Sending request"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Try
		{

			$_resp = Send-HPOVRequest $InputObject.uri PUT $InputObject -Hostname $ApplianceConnection.Name

			$_resp.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.IPv4AddressSubnet")

			[void]$_SubnetCollection.Add($_resp)

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}
	
	}

	End
	{

		Return $_SubnetCollection

	}

}
