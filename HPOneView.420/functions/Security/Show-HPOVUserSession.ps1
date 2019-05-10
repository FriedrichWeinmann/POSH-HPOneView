function Show-HPOVUserSession 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param ()

	Begin 
	{
	
		Write-Warning "This CMDLET has been deprecated. Please use the $ConnectedSessions Global variable for appliance session information."
	
	}

	Process { }

	End { }

}
