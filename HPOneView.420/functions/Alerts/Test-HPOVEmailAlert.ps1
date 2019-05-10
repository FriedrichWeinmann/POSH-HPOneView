function Test-HPOVEmailAlert
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param
	(	

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[Array]$Recipients,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Subject = 'This is a test message.',

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Body = 'Test email message from HPE OneView appliance.',
	
		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
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

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError "ApplianceConnection" -Message "No Appliance connection session found.  Please use Connect-HPOVMgmt to establish a connection, then try your command agian."
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

		$_SMTPConfigCollection = New-Object System.Collections.ArrayList

	}
	
	Process 
	{

		$_EmailTest = NewObject -TestSmtpConfig		
		
		# Add recipients to property
		ForEach ($_recipient in $Recipients)
		{
			
			# Validate recipient is a valid Email Address
			if (-not $_recipient -as [Net.Mail.MailAddress])
			{

				$ExceptionMessage = 'The provided recipient email address {0} is invalid.' -f $_recipient
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.EmailAlertResourceException InvalidEmailAddress InvalidArgument "Recipients" -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)			

			}

			[void]$_EmailTest.toAddress.Add($_recipient)

		}

		if ([Regex]::Match($Body,$HtmlPattern).Success)
		{

			$_EmailTest.htmlMessageBody = $Body

		}

		else
		{

			$_EmailTest.textMessageBody = $Body

		}

		$_EmailTest.subject = $Subject

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Try
			{
     
				$null = Send-HPOVRequest -Uri $TestNotificationUri -Method POST -Body $_EmailTest -Hostname $_appliance

			}

			catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			# Add properties
			$_EmailTest | Add-Member -NotePropertyName category -NotePropertyValue appliance
			$_EmailTest | Add-Member -NotePropertyName uri -NotePropertyValue $TestNotificationUri
			$_EmailTest | Add-Member -NotePropertyName ccAddress -NotePropertyValue @()
			$_EmailTest | Add-Member -NotePropertyName bccAddress -NotePropertyValue @()
			$_EmailTest | Add-Member -NotePropertyName eTag -NotePropertyValue $null
			$_EmailTest | Add-Member -NotePropertyName created -NotePropertyValue $null
			$_EmailTest | Add-Member -NotePropertyName modified -NotePropertyValue $null
			$_EmailTest | Add-Member -NotePropertyName ApplianceConnection -NotePropertyValue (New-Object HPOneView.Library.ApplianceConnection($_appliance.Name, $_appliance.ID))
			$_EmailTest

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
	}	

}
