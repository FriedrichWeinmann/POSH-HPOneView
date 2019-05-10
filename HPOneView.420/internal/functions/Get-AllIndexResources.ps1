function Get-AllIndexResources
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[String]$Uri,

		[Parameter (Mandatory)]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		$_ResourcesFromIndexCol = New-Object System.Collections.ArrayList

	}

	Process
	{

		if (-not $Uri.StartsWith($IndexUri) -and -not $Uri.StartsWith($AssociationsUri))
		{

			Throw ("URI is incorrect.  Does not begin with {0} or {1}." -f $IndexUri, $AssociationsUri)

		}

		"[{0}] Processing URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		Try
		{

			$_IndexResults = Send-HPOVRequest -Uri $Uri -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		ForEach ($_IndexEntry in $_IndexResults.members)
		{

			if ($Uri.StartsWith($AssociationsUri))
			{

				"[{0}] Get full associated object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_Uri = $_IndexEntry.childUri

			}

			else
			{

				"[{0}] Get full object: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_IndexEntry.name | Write-Verbose

				$_Uri = $_IndexEntry.uri

			}		

			Try
			{

				$_FullIndexEntry = Send-HPOVRequest -Uri $_Uri -Hostname $ApplianceConnection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			[void]$_ResourcesFromIndexCol.Add($_FullIndexEntry)

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Return $_ResourcesFromIndexCol

	}

}
