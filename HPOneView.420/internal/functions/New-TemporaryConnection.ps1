function New-TemporaryConnection
{

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[String]$Hostname
	
	)

	Process
	{

		$_ID = 99

		While (-not($FoundID))
		{

			if ($ConnectedSessions.ConnectionID -notcontains $_ID)
			{

				$FoundID = $_ID

			}

			$_ID--

		}

		$_TemporaryConnection = New-Object HPOneView.Appliance.Connection($_ID, $Hostname, 'TemporaryConnection')

		[void]${Global:ConnectedSessions}.Add($_TemporaryConnection)

		Return $_TemporaryConnection

	}	

}
