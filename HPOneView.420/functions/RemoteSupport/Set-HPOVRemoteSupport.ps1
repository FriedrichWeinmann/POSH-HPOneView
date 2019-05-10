function Set-HPOVRemoteSupport
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'InsightOnline')]
		[ValidateNotNullorEmpty()]
		[String]$CompanyName,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $False, ParameterSetName = 'InsightOnline')]
		[switch]$OptimizeOptIn,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $False, ParameterSetName = 'InsightOnline')]
		[Bool]$AutoEnableDevices,

		[Parameter (Mandatory, ParameterSetName = 'InsightOnline')]
		[ValidateNotNullorEmpty()]
		[String]$InsighOnlineUsername,

		[Parameter (Mandatory, ParameterSetName = 'InsightOnline')]
		[ValidateNotNullorEmpty()]
		[SecureString]$InsightOnlinePassword,

		[Parameter (Mandatory, ParameterSetName = 'Enable')]
		[Switch]$Enable,

		[Parameter (Mandatory, ParameterSetName = 'Disable')]
		[Switch]$Disable,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'InsightOnline')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Enable')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Disable')]
		[switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'InsightOnline')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Enable')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Disable')]
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

		$_ApplianceRemoteSupportCol = New-Object System.Collections.ArrayList

	}

	Process
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			'[{0}] Processing "{1}" appliance connection.' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			Try
			{
			
				$_CurrentConfiguration = Send-HPOVRequest -Uri $RemoteSupportConfigUri -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($PSBoundParameters['Disable'])
			{

				$_CurrentConfiguration.enableRemoteSupport = $false

			}

			elseif ($PSBoundParameters['Enable'])
			{

				$_CurrentConfiguration.enableRemoteSupport = $true

				# Check to make sure that 1 RS contact is default
				Try
				{

					RemoteSupportDefaultContactExists $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			else
			{

				# Check to make sure that 1 RS contact is default
				Try
				{

					RemoteSupportDefaultContactExists $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				switch ($PSBoundParameters.Keys)
				{

					'CompanyName'
					{

						$_CurrentConfiguration.companyName = $CompanyName

					}

					'OptimizeOptIn'
					{

						$_CurrentConfiguration.marketingOptIn = $OptimizeOptIn

					}

					'AutoEnableDevices'
					{

						$_CurrentConfiguration.autoEnableDevices = $AutoEnableDevices

					}

				}

				$_CurrentConfiguration.enableRemoteSupport = $true

			}

			if ($PSCmdlet.ParameterSetName -eq 'InsightOnline')
			{

				$_PortalRegsitrationObject = NewObject -InsightOnlineRegistration
				$_PortalRegsitrationObject.userName = $InsightOnlineUsername
				$_PortalRegsitrationObject.password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($InsightOnlinePassword))

				Try
				{
				
					$_InsightOnlineConfig = Send-HPOVRequest -uri $InsightOnlinePortalRegistraionUri -Method POST -Body $_PortalRestrationObject -Hostname $_appliance.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}
			
			Try
			{
			
				$_UpdatedConfiguration = Send-HPOVRequest -uri $RemoteSupportConfigUri -Method PUT -Body $_CurrentConfiguration -Hostname $_appliance.Name

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if (-not $Async)
			{

				$_UpdatedConfiguration = $_UpdatedConfiguration | Wait-HPOVTaskComplete

			}

			$_UpdatedConfiguration

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
