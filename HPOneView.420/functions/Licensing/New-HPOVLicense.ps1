function New-HPOVLicense 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "licenseKey")]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "licenseKey")]
		[ValidateNotNullOrEmpty()]
		[String]$LicenseKey,
		
		[Parameter (Mandatory, ParameterSetName = "InputFile")]
		[ValidateScript({Test-Path $_})]
		[String]$File,
		
		[Parameter (Mandatory = $false, ParameterSetName = "licenseKey")]
		[Parameter (Mandatory = $false, ParameterSetName = "InputFile")]
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

		$_LicenseResponseCollection = New-Object System.Collections.ArrayList

		if ($file)
		{

			[Array]$LicenseKey = Get-Content $file

		}

	}

	Process 
	{

		# Loop through all keys, and add one by one.
		foreach ($_lk in ($LicenseKey | Where-Object { -not $_.startswith("#") }))
		{

			"[{0}] Processing LicenseKey: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_lk | Write-Verbose 

			$_key     = NewObject -LicenseKey
			$_key.key = '{0}' -f $_lk

			Try 
			{
			
				$_ret = Send-HPOVRequest -Uri $ApplianceLicensePoolUri -Method POST -Body $_key -Hostname $ApplianceConnection

			}

			Catch 
			{

				$_Exception = $_

				Switch ($_.FullyQualifiedErrorId)
				{

					"LICENSE_ALREADY_EXISTS"
					{

						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.LicenseKeyException LicenseKeyAlreadyExists ResourceExists 'LicenseKey' -Message "The license key provided already exists on the appliance.  Please correct the value, and try again."

					}

					"ADD_LICENSE_FAILED"
					{

						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.LicenseKeyException InstallLicenseFailure InvalidResult 'LicenseKey' -Message $_Exception.Message						

					}

					default
					{

						$ErrorRecord = New-ErrorRecord HPOneview.Appliance.LicenseKeyException InvalidResult InvalidResult 'LicenseKey' -Message $_Exception.Exception.Message

					}

				}

				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			$_AdditionalKeys = New-Object 'System.Collections.Generic.List[String]'

			if ($_ret.additionalKeys.Count -gt 0)
			{

				$_ret.additionalKeys | ForEach-Object { [void]$_AdditionalKeys.Add($_) }

			}

			New-Object HPOneView.Appliance.License ($_ret.product,
													$_ret.licenseType,
													$_ret.productDescription,
													$_ret.eon,
													$_ret.salesOrder,
													$_ret.availableCapacity,
													$_ret.totalCapacity,
													$_ret.key,
													$_ret.uri,
													$null,
													$_AdditionalKeys,
													$_ret.created,
													$_ret.ApplianceConnection)
			
		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
	
	}

}
