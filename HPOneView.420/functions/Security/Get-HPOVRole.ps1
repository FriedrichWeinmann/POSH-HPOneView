function Get-HPOVRole 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default")]
	Param()
	
	Begin 
	{

		Write-Warning "This CMDLET is now deprecated. Please use the Get-HPOVUser CMDLET to retrieve the user account and associated Roles."

	}

}
