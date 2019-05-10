function Set-HPOVUserRole 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ("user",'userName')]
		[Object]$Name,

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[Alias ('roleName')]
		[Array]$Roles,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{

		Write-Warning "This CMDLET is now deprecated. Please use the Set-HPOVUser CMDLET to modify user accounts and associated roles/permissions."

	}

}
