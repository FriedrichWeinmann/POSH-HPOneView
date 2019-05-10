function Add-HPOVServerProfileConnection
{

	<#

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		# Server Profile resource
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'PassThru')]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		# Connections to add, from New-HPOVServerProfileConnection helper Cmdlet
		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'PassThru')]
		[ValidateNotNullOrEmpty()]
		[Object]$Connections,

		[Parameter (Mandatory, ParameterSetName = 'PassThru')]
		[Switch]$PassThru,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default']
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'PassThru']
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | ? Default)

	)

	#>



	Throw "Not implemented."

}
