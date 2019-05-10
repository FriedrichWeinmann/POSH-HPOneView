function Start-HPOVLibraryTrace
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param
	(
	
		[Parameter (Mandatory = $false)]
		[String]$Location = (Get-Location).path
	
	)

	Throw "This Cmdlet is now deprecated.  Please use Get-HPOVCommandTrace instead."

}
