function New-HPOVRemoteSupportContact
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

   	[CmdletBinding (DefaultParameterSetName = "Default" )]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Alias ('GivenName')]
		[String]$Firstname,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Surname')]
		[String]$Lastname,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$Email,

		[Parameter (Mandatory, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$PrimaryPhone,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$AlternatePhone,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$Language = 'en',

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[String]$Notes,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[switch]$Default,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{
		
		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection) -and -not(${Global:ConnectedSessions}))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif ($ApplianceConnection -is [System.Collections.IEnumerable] -and $ApplianceConnection -isnot [System.String])
		{

			For ([int]$c = 0; $c -lt $ApplianceConnection.Count; $c++) 
			{

				Try 
				{
			
					$ApplianceConnection[$c] = Test-HPOVAuth $ApplianceConnection[$c]

				}

				Catch [HPOneview.Appliance.AuthSessionException] 
				{

					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError $ApplianceConnection[$c].Name -Message $_.Exception.Message -InnerException $_.Exception
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				Catch 
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

		}

		else
		{

			Try 
			{
			
				$ApplianceConnection = Test-HPOVAuth $ApplianceConnection

			}

			Catch [HPOneview.Appliance.AuthSessionException] 
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError 'ApplianceConnection' -Message $_.Exception.Message -InnerException $_.Exception
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		$_RemoteSupportContactCol = New-Object System.Collections.ArrayList

	}

	Process 
	{
		
		$_c = 0

		ForEach($_Connection in $ApplianceConnection)
		{

			$_c++ 

			"[{0}] Processing {1} of {2} Appliance Connection(s)" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_c, ($ApplianceConnection | Measure-Object).Count | Write-Verbose

			$_RemoteSupportContact = NewObject -RemoteSupportContact

			$_RemoteSupportContact.default        = $PSBoundParameters['Default'].IsPresent
			$_RemoteSupportContact.alternatePhone = $AlternatePhone
			$_RemoteSupportContact.email          = $Email
			$_RemoteSupportContact.firstName      = $Firstname
			$_RemoteSupportContact.lastName       = $Lastname
			$_RemoteSupportContact.language       = $Language
			$_RemoteSupportContact.notes          = $Notes
			$_RemoteSupportContact.primaryPhone   = $PrimaryPhone

			$_PatchOp       = NewObject -PatchOperation
			$_PatchOP.op    = 'add'
			$_PatchOP.path  = '/contacts'
			$_PatchOP.value = $_RemoteSupportContact

			Try
			{

				$_Contacts = Send-HPOVRequest -Uri $RemoteSupportContactsUri -Hostname $_Connection

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# Check to see if there is a default contact, if so, add it as an array to the operation and set its default property to false
			if ($PSBoundParameters['Default'])
			{

				"[{0}] Checking for existing default contact" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				if ($_Contacts.members | Where-Object default)
				{

					"[{0}] Default contact found: {0} {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($_Contacts.members | Where-Object default).firstName, ($_Contacts.members | Where-Object default).lastName | Write-Verbose
					
					$_DefaultContact = $_Contacts.members | Where-Object default
					$_DefaultContact.default = $false

					$_UpdatePatchOp       = NewObject -PatchOperation
					$_UpdatePatchOp.op    = 'replace'
					$_UpdatePatchOp.path  = '/contacts/{0}' -f $_DefaultContact.contactKey
					$_UpdatePatchOp.value = $_DefaultContact

					$_NewContact = $_PatchOp.PSObject.Copy()

					$_PatchOp = New-Object System.Collections.ArrayList
					[void]$_PatchOp.Add($_NewContact)
					[void]$_PatchOp.Add($_UpdatePatchOp)

				}

				else
				{

					"[{0}] No default contact. Configured contacts: {0}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Contacts.count | Write-Verbose

				}

			}

			elseif (-not ($_Contacts.members | Where-Object default) -and -not $PSBoundParameters['Default'])
			{

				"[{0}] No default contacts were present, and new contact was not specified as default.  Setting it as Default contact." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				$_PatchOP.value.default = $true

			}
			
			Try
			{

				# Task object is returned dur to PATCH operation
				$_resp = Send-HPOVRequest -Uri $RemoteSupportUri -Method PATCH -Body $_PatchOp -Hostname $_Connection | Wait-HPOVTaskComplete

				# If not successful, generate terminating error
				if ($_resp.taskState -ne 'Completed')
				{

					$ExceptionMessage = [String]::Join(' ', $_resp.taskErrors.Message)
					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportContactException InvalidResult InvalidResult "Contact" -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			Try
			{

				# Get newly created contact
				$_Contacts = Send-HPOVRequest -Uri $RemoteSupportContactsUri -Hostname $_Connection

				$_NewContact = $_Contacts.members | Where-Object { ('{0} {1}' -f $_.firstName, $_.lastName) -like ('{0} {1}' -f $Firstname, $Lastname) }

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$_NewContact.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.RemoteSupport.Contact')

			$_NewContact

		}

	}

	End
	{

		"Done." | Write-Verbose

	}

}
