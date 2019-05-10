function New-HPOVRemoteSupportPartner
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

   	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateSet ('Support','Reseller')]
		[String]$Type,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[int]$PartnerId,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Switch]$Default,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
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
		
	}

	Process
	{

		$_RemoteSupportPartnerObject             = NewObject -RemoteSupportPartner
		$_RemoteSupportPartnerObject.id          = $PartnerId;
		$_RemoteSupportPartnerObject.default     = $Default.IsPresent;
		$_RemoteSupportPartnerObject.partnerType = $Type.ToUpper()

		"[{0}] Validating PartnerID: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $PartnerId | Write-Verbose

		# Validate PartnerID
		Try
		{

			$_resp = Send-HPOVRequest -Uri $RemoteSupportChannelPartnersValidatorUri -Method POST -Body $PartnerId.ToString() -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		Try
		{

			$_resp = Send-HPOVRequest -Uri $RemoteSupportChannelPartnersUri -Method POST -Body $_RemoteSupportPartnerObject -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}
		
		$_resp.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.RemoteSupport.Partner')
		$_resp

	}

	End
	{

		"Done." | Write-Verbose

	}

}
