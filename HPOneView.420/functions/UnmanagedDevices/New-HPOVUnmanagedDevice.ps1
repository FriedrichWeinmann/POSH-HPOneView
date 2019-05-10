function New-HPOVUnmanagedDevice 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName='Default')]

	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[string]$Model,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[int]$Height = 1,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[int]$MaxPower,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[string]$MacAddress,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateScript({if (-not([Net.IPAddress]::TryParse($_,[ref]$null))) { Throw 'The provided IPv4Address value does not appear to be a valid IPv4 Address.' } else { $True }})]
		[string]$IPv4Address,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateScript({if (-not([Net.IPAddress]::TryParse($_,[ref]$null))) { Throw 'The provided IPv6Address value does not appear to be a valid IPv6 Address.' } else { $True }})]
		[string]$IPv6Address,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
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

		$_UnmanagedDeviceCreateResults = New-Object System.Collections.ArrayList
	}

	Process 
	{
		
		$_NewDevice = NewObject -UnmanagedDevice

		[string]$_NewDevice.name        = $Name
		[string]$_NewDevice.model       = $Model
		[int]$_NewDevice.height         = $Height
		[string]$_NewDevice.mac         = $MacAddress
		[string]$_NewDevice.IPv4Address = $IPv4Address
		[string]$_NewDevice.IPv6Address = $IPv6Address
		[int]$_NewDevice.maxPwrConsumed = $MaxPower

		# "[{0}] New Unmanaged Device:  $($newDevice)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		"[{0}] Sending request"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Try
		{

			$_resp = Send-HPOVRequest $unmanagedDevicesUri POST $_NewDevice -Hostname $ApplianceConnection.Name

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$_resp | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.UnmanagedResource") }

		[void]$_UnmanagedDeviceCreateResults.Add($_resp)

	}

	End
	{

		Return $_UnmanagedDeviceCreateResults

	}

}
