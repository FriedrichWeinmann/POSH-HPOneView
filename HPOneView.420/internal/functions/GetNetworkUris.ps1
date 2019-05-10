function GetNetworkUris
{

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Position = 0, Mandatory, ParameterSetName = "Default")]
		[Array]$_Networks,

		[Parameter (Position = 1, Mandatory, ParameterSetName = "Default")]
		[Object]$_ApplianceConnection

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		$_NetworkUris = New-Object System.Collections.ArrayList

	}

	Process
	{

		# Get Network URI's if values are of type String
		ForEach ($_net in $_Networks)
		{

			"[{0}] _net Type is {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_net.GetType().FullName | Write-Verbose

			# Network is String and Name; call Get-HPOVNetwork
			if ($_net -is [String] -and (-not($_net.StartsWith('/rest/'))))
			{

				"[{0}] Network is type String, and Network Name" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Get Network Object
				Try
				{

					$_net = Get-HPOVNetwork -Name $_net -ApplianceConnection $_ApplianceConnection -ErrorAction Stop

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
				"[{0}] Found Network {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_net.name, $_net.uri | Write-Verbose 
	
				# Insert object into original arraylist
				[void]$_NetworkUris.Add($_net.uri)

			}

			elseif ($_net -is [String] -and $_net.StartsWith('/rest/'))
			{

				"[{0}] Network is type String, and URI of network." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

				"[{0}] Adding URI to collection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_net | Write-Verbose 

				[void]$_NetworkUris.Add($_net)

			}

			# // Need to change this to HPOneView.Networking.Networks.Ethernet
			elseif ($_net -is [PSCustomObject])
			{

				if (-not('HPOneView.Networking.EthernetNetwork','HPOneView.Networking.FCoENetwork','HPOneView.Networking.Networks.FibreChannelNetwork' -contains $_net.PSObject.TypeNames[0]))
				{

					"[{0}] Input object is not a valid Network type." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}
				
				"[{0}] Network '{1}' is [{2}]" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_net.name, $_net.GetType().Fullname | Write-Verbose

				[void]$_NetworkUris.Add($_net.uri)

			}

		}

	}

	End
	{

		"[{0}] Network URIs: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), [String]::Join("," , $_NetworkUris.ToArray()) | Write-Verbose

		Return $_NetworkUris
	
	}

}
