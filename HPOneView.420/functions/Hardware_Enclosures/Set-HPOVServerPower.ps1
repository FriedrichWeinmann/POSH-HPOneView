function Set-HPOVServerPower 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(
	
		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ("name","uri","serverUri")]
		[object]$Server,

		[Parameter (Mandatory = $false)]
		[Alias ('PowerState')]
		[ValidateSet ("On", "Off")]
		[string]$State = "On",

		[Parameter (Mandatory = $false)]
		[ValidateSet ("PressAndHold", "MomentaryPress", "ColdBoot", "Reset")]
		[string]$powerControl = "MomentaryPress",

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		Write-Warning "This Cmdlet has been deprecated.  Please use either Start-HPOVServer, Stop-HPOVServer or Restart-HPOVServer."

	}

}
