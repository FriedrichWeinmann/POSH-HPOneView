function BuildPortConfigInfos
{

	[CmdLetBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[Object]$UplinkPorts,

		[Parameter (Mandatory = $False, ParameterSetName = 'Default')]
		[String]$EnclosureID = 1

	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

	}

	Process
	{



	}

	End
	{


	}

}
