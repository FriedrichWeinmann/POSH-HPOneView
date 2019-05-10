function Set-HPOVServerProfileConnection
{

	<#

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "ConnectionName")]
	Param 
	(

		# Server Profile resource
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "ConnectionName")]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory, ParameterSetName = "ConnectionName")]
		[ValidateNotNullOrEmpty()]
		[String]$ConnectionName,

		[Parameter (Mandatory, ParameterSetName = "ConnectionID")]
		[ValidateNotNullOrEmpty()]
		[Int]$ConnectionID

		# Should contain the simliar parameters from New-HPOVServerProfileConnection

		[Object]$Network,

		[Int]$TypicalBandwidth,

		[Int]$MaximumBandwidth,

		[Boolean]$Bootable,

		[String]$BootPriority,

		[Parameter (Mandatory, ParameterSetName = 'PassThru')]
		[Switch]$PassThru,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | ? Default)

	)

	#>

	Throw "Not implemented."

}
