function New-HPOVSnmpTrapDestination
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'SnmpV3')]
		[ValidateNotNullOrEmpty()]
		[String]$Destination,
		
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullOrEmpty()]
		[String]$Community = 'public',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "SnmpV3")]
		[ValidateNotNullOrEmpty()]
		[Int]$Port = '162',

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "SnmpV3")]
		[ValidateNotNullOrEmpty()]
		[ValidateSet ('SNMPv1', 'SNMPv2', 'SNMPv3', IgnoreCase = $False)]
		[String]$SnmpFormat = 'SNMPv1',

		[Parameter (Mandatory, ParameterSetName = "SnmpV3")]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.SnmpV3User]$SnmpV3User,

		[Parameter (Mandatory = $false, ParameterSetName = "SnmpV3")]
		[ValidateSet ('Inform', 'Trap', IgnoreCase = $False)]
		[String]$NotificationType = 'Trap',

		[Parameter (Mandatory = $false, ParameterSetName = "SnmpV3")]
		[ValidateNotNullOrEmpty()]
		[String]$EngineID,
		
		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "SnmpV3")]
		[ValidateNotNullOrEmpty()]
		[Array]$TrapSeverities,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "SnmpV3")]
		[ValidateNotNullOrEmpty()]
		[Array]$VCMTrapCategories,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "SnmpV3")]
		[ValidateNotNullOrEmpty()]
		[Array]$EnetTrapCategories,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "SnmpV3")]
		[ValidateNotNullOrEmpty()]
		[Array]$FCTrapCategories

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		$_TrapDestinationCol = New-Object System.Collections.ArrayList

	}

	Process
	{

		if ($SnmpFormat -eq 'SnmpV3' -and $NotificationType -eq 'Trap' -and -not $PSboundParameters['EngineID'])
		{

			$ExceptionMessage = 'Setting NotificationType to "Trap" requires an SNMPv3 Engine ID.  Please provide a value for the EngineID parameter.'

			Throw $ExceptionMessage

		}

		if ($PSCmdlet.ParameterSetName -eq "SnmpV3" -and $SnmpFormat -ne 'SnmpV3' -and $NotificationType -eq 'Trap' )
		{

			$ExceptionMessage = 'Setting NotificationType is only for SNMPv3 configurations.  Please change the SnmpFormat to "SNMPv3" or omit the NotificationType parameter.'

			Throw $ExceptionMessage

		}
		
		if ($PSCmdlet.ParameterSetName -eq "SnmpV3" -and $SnmpFormat -eq 'SnmpV3' -and -not $PSboundParameters['SnmpV3User'])
		{

			$ExceptionMessage = 'Configuring SNMPv3 trap destinations requires an SNMPv3 user account.  Please use the New-HPOVSnmpV3User Cmdlet and provide the value to the SnmpV3User parameter.'

			Throw $ExceptionMessage

		}

		$_TrapDestination = NewObject -SnmpTrapDestination

		$_TrapDestination.trapDestination    = $Destination
		$_TrapDestination.communityString    = $Community
		$_TrapDestination.trapFormat         = $SnmpFormat

		switch ($PSBoundParameters.keys)
		{

			'TrapSeverities'
			{

				ForEach ($_severity in $TrapSeverities)
				{
					
					# Throw error
					if ($SnmpTrapSeverityEnums -notcontains $_severity)
					{

						$ErrorRecord = New-ErrorRecord HPOneView.SnmpTrapDestination InvalidTrapSeverity InvalidArgument 'TrapSeverities' -Message ("The provided SNMP Trap Severity {0} is unsupported.  Please check the value, making sure it is one of these values: {1}." -f $_severity, ([System.String]::Join(", ", $SnmpTrapSeverityEnums)))

						$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

					}

					$_severity = $_severity.SubString(0,1).ToUpper() + $_severity.SubString(1).tolower()
					
					"[{0}] Processing {1} Trap Severity." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_severity | Write-Verbose 
					
					[void]$_TrapDestination.trapSeverities.Add($_severity)

				}

			}

			'VCMTrapCategories'
			{
			
				ForEach ($_category in $VCMTrapCategories)
				{
					
					# Throw error
					if ($SnmpVcmTrapCategoryEnums -notcontains $_category)
					{

						$ErrorRecord = New-ErrorRecord HPOneView.SnmpTrapDestination InvalidVcmTrapCategory InvalidArgument 'VCMTrapCategories' -Message ("The provided VCM Trap Category {0} is unsupported.  Please check the value, making sure it is one of these values: {1}." -f $_category, ([System.String]::Join(", ", $SnmpVcmTrapCategoryEnums)))

						$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

					}

					$_category = $_category.SubString(0,1).ToUpper() + $_category.SubString(1).tolower()
					
					"[{0}] Processing {1} VCM Trap Category." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_category | Write-Verbose 

					[void]$_TrapDestination.vcmTrapCategories.Add($_category)

				}
			
			}

			'EnetTrapCategories'
			{
			
				ForEach ($_category in $EnetTrapCategories)
				{
					
					# Throw error
					if ($SnmpEneTrapCategoryEnums -notcontains $_category)
					{

						$ErrorRecord = New-ErrorRecord HPOneView.SnmpTrapDestination InvalidEnetTrapCategory InvalidArgument 'EnetTrapCategories' -Message ("The provided Ethernet Trap Category {0} is unsupported.  Please check the value, making sure it is one of these values: {1}." -f $_category, ([System.String]::Join(", ", $SnmpEneTrapCategoryEnums)))

						$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

					}

					if ($_category.StartsWith('port'))
					{

						$_category = $_category.SubString(0,1).ToUpper() + $_category.SubString(1,3).tolower() + $_category.SubString(4,1).ToUpper() + $_category.SubString(6).tolower()

					}

					"[{0}] Processing {1} Enet Trap Category." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_category | Write-Verbose 

					[void]$_TrapDestination.enetTrapCategories.Add($_category)

				}
			
			}

			'FCTrapCategories'
			{
			
				ForEach ($_category in $FCTrapCategories)
				{

					# Throw error
					if ($SnmpFcTrapCategoryEnums -notcontains $_category)
					{

						$ErrorRecord = New-ErrorRecord HPOneView.SnmpTrapDestination InvalidFcTrapCategory InvalidArgument 'FCTrapCategories' -Message ("The provided FC Trap Category {0} is unsupported.  Please check the value, making sure it is one of these values: {1}." -f $_category, ([System.String]::Join(", ", $SnmpFcTrapCategoryEnums)))

						$PSCmdlet.ThrowTerminatingError($ErrorRecord)  

					}

					"[{0}] Processing {1} FC Trap Category." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_category | Write-Verbose 
					
					[void]$_TrapDestination.fcTrapCategories.Add($_category)

				}
			
			}

		}

		$_TrapDestination.PSObject.TypeNames.Insert(0,'HPOneView.Networking.SnmpTrapDestination')

		[void]$_TrapDestinationCol.Add($_TrapDestination)

		if ($SnmpFormat -eq 'SnmpV3')
		{

			$_TrapDestination.trapFormat = 'SNMPv3'
			$_TrapDestination.userName = $SnmpV3User.userName

			if ($NotificationType -eq 'Trap')
			{

				$_TrapDestination.inform = $false

				if (-not $SnmpV3EngineIdPattern.Match($EngineID).Success)
				{

					# Generate terminating error EngineID is not in the correct format
					$ExceptionMessage = "The EngineID parameter value '{0}' is not in the correct format.  The EngineID must be prefixed with '10x' followed by an even muber of 10 to 64 hexadecimal digits." -f $EngineID
					
					Throw $ExceptionMessage

				}

				$_TrapDestination.engineId = $EngineID				

			}

		}

	}

	End
	{

		Return $_TrapDestinationCol

	}

}
