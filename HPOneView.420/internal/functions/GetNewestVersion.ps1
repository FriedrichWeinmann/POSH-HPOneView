Function GetNewestVersion
{

	<#
		Internal-only function.
	#>

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Array]$Collection

	)

	Process
	{

		if ($Collection.Count -eq 0)
		{

			# The baseline likely doesn't contain the component firmware

			Return 'N/A'

		}

		$_NewerVersion = '0.0'

		# Figure out which is the newest, and only display that if multiple ROM versions found
		foreach ($_Component in $Collection)
		{

			'Processing {0} version of {1}' -f $_Component.Version, $_Component.name | Write-Verbose

			if ($_Component.Version -ge $_NewerVersion)
			{

				$_NewerVersion = $_Component.Version
					
			}

		}

		if ($_NewerVersion -eq '0.0')
		{

			$_NewerVersion = 'N/A'

		}

		Return $_NewerVersion

	}

}
