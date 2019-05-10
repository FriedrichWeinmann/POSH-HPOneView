function Set-HPOVRemoteSupportSetting
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]

	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Object]$PrimaryContact,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Object]$SecondaryContact,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Object]$ServicePartner,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Object]$Reseller,

		[Parameter (Mandatory = $false)]
		[ValidateSet ('PackagedSupport', 'SupportAgreement')]
		[String]$ContractType,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[String]$SupportID,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[String]$NewSerialNumber,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[String]$NewProductNumber,
		
		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
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

		$_RemoteSupportSettingsToSet = New-Object System.Collections.ArrayList

		switch ($InputObject.category)
		{

			'server-hardware'
			{

				$_uri = '{0}/{1}' -f $RemoteSupportComputeSettingsUri, $InputObject.uuid

			}

			'enclosures'
			{

				$_uri = '{0}/{1}' -f $RemoteSupportEnclosureSettingsUri, $InputObject.uuid

			}

			default
			{

				# Unsupported
				$ExceptionMessage = 'The {0} input object is an unsupported resource category type, "{1}".  Only "server-hardware" or "enclosure" resources are supported.' -f $InputObject.category, $InputObject.name 
				$ErrorRecord = New-ErrorRecord HPOneview.InputObjectResourceException InvalidResourceObject InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}
			
		}

		Switch ($PSBoundParameters.Keys)
		{

			'PrimaryContact'
			{

				if ($PrimaryContact.Type -ne 'Contact')
				{

					$ExceptionMessage = 'The PrimaryContact object is not a valid Remote Support Contact.'
					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.RemoteSupportContactException InvalidPrimaryContact InvalidArgument "InputObject" -TargetType $PrimaryContact.GetType().Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_PrimaryContactOp = NewObject -PatchOperation
				$_PrimaryContactOp.op    = 'replace'
				$_PrimaryContactOp.path  = '/primaryContactUri'
				$_PrimaryContactOp.value = $PrimaryContact.uri

				[Void]$_RemoteSupportSettingsToSet.Add($_PrimaryContactOp)
				
			}

			'SecondaryContact'
			{

				if ($SecondaryContact.Type -ne 'Contact')
				{

					$ExceptionMessage = 'The SecondaryContact object is not a valid Remote Support Contact.'
					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.RemoteSupportContactException InvalidSecondaryContact InvalidArgument "InputObject" -TargetType $SecondaryContact.GetType().Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_SecondaryContactOp = NewObject -PatchOperation
				$_SecondaryContactOp.op    = 'replace'
				$_SecondaryContactOp.path  = '/secondaryContactUri'
				$_SecondaryContactOp.value = $SecondaryContact.uri

				[Void]$_RemoteSupportSettingsToSet.Add($_SecondaryContactOp)
				
			}

			'Reseller'
			{

				if ($Reseller.Type -ne 'ChannelPartner' -or $Reseller.partnerType -ne 'RESELLER')
				{

					$ExceptionMessage = 'The Reseller object is not a valid Remote Support reseller partner.'
					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.RemoteSupportPartnerException InvalidReseller InvalidArgument "InputObject" -TargetType $Reseller.GetType().Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_ResellerOp = NewObject -PatchOperation
				$_ResellerOp.op    = 'replace'
				$_ResellerOp.path  = '/salesChannelPartnerUri'
				$_ResellerOp.value = $Reseller.uri

				[Void]$_RemoteSupportSettingsToSet.Add($_ResellerOp)
				
			}

			'ServicePartner'
			{
				
				if ($ServicePartner.Type -ne 'ChannelPartner' -or $ServicePartner.partnerType -ne 'SUPPORT')
				{

					$ExceptionMessage = 'The Reseller object is not a valid Remote Support suport partner.'
					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.RemoteSupportPartnerException InvalidServicePartner InvalidArgument "InputObject" -TargetType $ServicePartner.GetType().Name -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				$_ServicePartnerOp = NewObject -PatchOperation
				$_ServicePartnerOp.op    = 'replace'
				$_ServicePartnerOp.path  = '/supportChannelPartnerUri'
				$_ServicePartnerOp.value = $ServicePartner.uri

				[Void]$_RemoteSupportSettingsToSet.Add($_ServicePartnerOp)
				
			}

			'SupportID'
			{

				$_SupportIDOp = NewObject -PatchOperation
				$_SupportIDOp.op    = 'replace'
				$_SupportIDOp.path  = '/entitlement'
				$_SupportIDOp.value = [PSCustomOBject]@{

					obligationType = $ContractType;
					obligationId   = $SupportID

				}

				[Void]$_RemoteSupportSettingsToSet.Add($_SupportIDOp)
				
			}

			'NewSerialNumber'
			{

				$_NewSerialNumberOp = NewObject -PatchOperation
				$_NewSerialNumberOp.op    = 'replace'
				$_NewSerialNumberOp.path  = '/enteredSerialNumber'
				$_NewSerialNumberOp.value = $NewSerialNumber

				[Void]$_RemoteSupportSettingsToSet.Add($_NewSerialNumberOp)
				
			}

			'NewProductNumber'
			{

				$_NewProductNumberOp = NewObject -PatchOperation
				$_NewProductNumberOp.op    = 'replace'
				$_NewProductNumberOp.path  = '/enteredProductNumber'
				$_NewProductNumberOp.value = $NewProductNumber

				[Void]$_RemoteSupportSettingsToSet.Add($_NewProductNumberOp)
				
			}
			
		}

		Try
		{

			$_resp = Send-HPOVRequest -Uri $_uri -Method PATCH -Body $_RemoteSupportSettingsToSet -Hostname $ApplianceConnection

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

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
