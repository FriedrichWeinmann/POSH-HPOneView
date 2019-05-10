function Remove-HPOVServerProfileConnection
{

	<#

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "ConnectionName")]
	Param 
	(

		# Server Profile resource
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "ConnectionName")]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "PassThru")]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory, ParameterSetName = "ConnectionName")]
		[ValidateNotNullOrEmpty()]
		[String]$ConnectionName,

		[Parameter (Mandatory, ParameterSetName = "ConnectionID")]
		[ValidateNotNullOrEmpty()]
		[Int]$ConnectionID

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
