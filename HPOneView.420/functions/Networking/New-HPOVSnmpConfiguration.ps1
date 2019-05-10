function New-HPOVSnmpConfiguration
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'Snmpv3')]
		[ValidateNotNullOrEmpty()]
		[String]$ReadCommunity,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $False, ParameterSetName = 'Snmpv3')]
		[ValidateNotNullOrEmpty()]
		[Bool]$SnmpV1,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'Snmpv3')]
		[ValidateNotNullOrEmpty()]
		[Bool]$SnmpV3,

		[Parameter (Mandatory, ParameterSetName = 'Snmpv3')]
		[HPOneView.Networking.SnmpV3User[]]$SnmpV3Users,
		
		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "Snmpv3")]
		[ValidateNotNullOrEmpty()]
		[String]$Contact,

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "Snmpv3")]
		[ValidateNotNullOrEmpty()]
		[Array]$AccessList,
		
		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[Parameter (Mandatory = $False, ParameterSetName = "Snmpv3")]
		[ValidateNotNullOrEmpty()]
		[Array]$TrapDestinations

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		$_SnmpConfigrationCol = New-Object System.Collections.ArrayList

	}

	Process
	{

		$_SnmpConfig = NewObject -SnmpConfig

		switch ($PSBoundParameters.keys)
		{

			'ReadCommunity'
			{

				$_SnmpConfig.readCommunity = $ReadCommunity

			}

			'Contact'
			{

				$_SnmpConfig.systemContact = $Contact
			
			}

			'Snmpv1'
			{

				$_SnmpConfig.enabled = $Snmpv1

			}

			'Snmpv3'
			{

				$_SnmpConfig.v3Enabled = $Snmpv3

			}

			'SnmpV3Users'
			{

				ForEach ($_SnmpV3User in $SnmpV3Users)
				{

					[void]$_SnmpConfig.snmpUsers.add($_SnmpV3User)

				}

			}

			'AccessList'
			{
			
				ForEach ($_entry in $AccessList)
				{

					[void]$_SnmpConfig.snmpAccess.Add($_entry)

				}
			
			}

			'TrapDestinations'
			{
			

				ForEach ($_entry in $TrapDestinations)
				{

					[void]$_SnmpConfig.trapDestinations.Add($_entry)

				}

			}

		}


		$_SnmpConfig.PSObject.TypeNames.Insert(0,'HPOneView.Networking.SnmpConfiguration')

		[void]$_SnmpConfigrationCol.Add($_SnmpConfig)

	}

	End
	{

		Return $_SnmpConfigrationCol

	}

}
