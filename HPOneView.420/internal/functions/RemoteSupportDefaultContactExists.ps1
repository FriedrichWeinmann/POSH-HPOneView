function RemoteSupportDefaultContactExists
{

	[CmdletBinding ()]
	Param 
	(

		[Object]$ApplianceConnection

	)

	Process
	{

		# Check to make sure that 1 RS contact is default
		Try
		{

			$_Contacts = Send-HPOVRequest -Uri $RemoteSupportContactsUri -Hostname $ApplianceConnection

			# No default contact exists, generate terminating error
			if (-not $_Contacts.members.default)
			{

				$ExceptionMessage = 'The appliance {0} does not have a configured default contact.  One must exist before enabling Remote Support.' -f $ApplianceConnection
				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.RemoteSupportException NoDefaultContact InvalidOperation 'ApplianceConnection' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			}

			'[{0}] Default Contact: ' -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_Contacts.members | Where-Object default).uri | Write-Verbose

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

	}	

}
