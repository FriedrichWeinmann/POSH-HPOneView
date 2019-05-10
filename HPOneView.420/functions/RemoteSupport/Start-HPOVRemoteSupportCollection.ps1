function Start-HPOVRemoteSupportCollection
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,
		
		[Parameter (Mandatory)]
		[ValidateSet ('AHS', 'Basic')]
		[String]$Type,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Switch]$Async,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false)]
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

		$_SchedulesToUpdate = New-Object System.Collections.ArrayList

	}

	Process 
	{

		$_DataCollection = [PSCustomObject]@{
			type           = "CollectionType";
			collectionType = "AHS"
		}

		switch ($InputObject.category)
		{

			'enclosures'
			{

				$_DataCollection.collectionType = 'Basic'
				$_Uri = '{0}?deviceID={1}&category=enclosures' -f $RemoteSupportDataCollectionsUri, $InputObject.uuid

			}

			'server-hardware'
			{

				$_DataCollection.collectionType = $RemoteSupportCollectionEnum[$Type]

				$_Uri = '{0}?deviceID={1}&category=server-hardware' -f $RemoteSupportDataCollectionsUri, $InputObject.uuid

			}

			${ResourceCategoryEnum.ServerProfile}
			{

				if ($null -ne $InputObject.serverHardwareUri)
				{

					$_DataCollection.collectionType = $RemoteSupportCollectionEnum[$Type]

					$_Uri = '{0}?deviceID={1}&category=server-hardware' -f $RemoteSupportDataCollectionsUri, $InputObject.uuid

				}

				else
				{

					$ExceptionMessage = 'The {0} Server Profile resource is not assigned to a compute resource.' -f $InputObject.category, $InputObject.name 
					$ErrorRecord = New-ErrorRecord HPOneview.InputObjectResourceException InvalidResourceObject InvalidArgument "InputObject" -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)

				}				

			}

			default
			{

				# Unsupported
				$ExceptionMessage = 'The {0} input object is an unsupported resource category type, "{1}".  Only "server-hardware", "server-profile" or "enclosure" resources are supported.' -f $InputObject.category, $InputObject.name 
				$ErrorRecord = New-ErrorRecord HPOneview.InputObjectResourceException InvalidResourceObject InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		if ($_Uri)
		{

			Try
			{
	
				$_resp = Send-HPOVRequest -Uri $_Uri -Method POST -Body $_DataCollection -Hostname $ApplianceConnection
	
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

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
