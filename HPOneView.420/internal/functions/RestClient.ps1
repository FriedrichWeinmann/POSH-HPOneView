function RestClient 
{

	<#

		.SYNOPSIS 
		Internal Private Class for building a RestClient using [System.Net.WebRequest]

		.DESCRIPTION 
		This is a private, internal class/function to create a new [System.Net.WebRequest] object with pre-defined properties of the HttpWebReqeuest connection.  This class will set the following attributes, which the caller can overload the values with their own after the resource has been created:

			Timeout = 20000
			ContentType = "application/json"
			Accept = "application/json"
			Headers.Item("X-API-Version") = $MaxXAPIVersion
			Headers.Item("accept-language") = "en_US"
			Headers.Item("accept-encoding") = "gzip, deflate"
			Headers.Item("auth") = ${Global:ConnectedSessions}.sessionID  NOTE: Only if the sessionID exists.
			AutomaticDecompression = "GZip,Deflate,None"

		The URI of the WebRequest object will automatically include the connected (or requested if the first call is Connect-HPOVMgmt) appliance address or name ($script:HPOneViewAppliance).  This value can be overloaded, but the Auth token that may be included as an HTTP header item could be invalid.

		.INPUTS
		None.

		.OUTPUTS
		New [System.Net.WebRequest] object.

		.Parameter URI
		The URI of the request.  Do not include the appaliance hostname or IP Address, only the cononical URI value (i.e. /rest/server-hardware).

		.Parameter Method
		Optional.  Provide the HTTP method for the request.  The default value is 'GET'.  Only the following values are allowed:

			GET
			PUT
			POST
			DELETE
			PATCH

		.Parameter Appliance
		Provide the appliance hostname or FQDN.

	#>

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $False, Position = 0)]
		[ValidateScript({if ("GET","POST","DELETE","PATCH","PUT" -match $_) {$true} else { Throw "'$_' is not a valid Method.  Only GET, POST, DELETE, PATCH, or PUT are allowed." }})]
		[string]$method = "GET",

		[Parameter (Mandatory, Position = 1)]
		[ValidateScript({if ($_.startswith('/')) {$true} else {throw "-URI must being with a '/' (eg. /rest/server-hardware) in its value. Please correct the value and try again."}})]
		[string]$uri,

		[Parameter (Mandatory, Position = 2)]
		[ValidateNotNullorEmpty()]
		[string]$Appliance = $Null

	)

	Begin 
	{

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Debug

		$url = 'https://{0}{1}' -f $Appliance, $uri

		"[{0}] Building new [System.Net.HttpWebRequest] object for {1} {2}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $method, $url | Write-Verbose

	}

	Process 
	{

		$RestClient = (New-Object HPOneView.Utilities.Net).RestClient($url, $Method, $MaxXAPIVersion)

		$GuidRegEx = "$($LogicalInterconnectsUri.Replace('/','\/'))\/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\/support-dumps"

		if ($ExtendedTimeoutUris -contains $uri -or ([RegEx]::Match($uri, $GuidRegEx) -and $Uri.StartsWith($LogicalInterconnectsUri)))
		{

			"[{0}] Increasing timeout to 10 minutes for '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Uri | Write-Verbose

			# Increase timeout to 10 minutes.
			$RestClient.Timeout = 600000

		}

	}

	End 
	{

		Return $RestClient

	}

}
