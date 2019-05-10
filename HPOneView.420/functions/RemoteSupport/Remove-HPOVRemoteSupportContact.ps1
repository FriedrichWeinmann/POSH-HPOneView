function Remove-HPOVRemoteSupportContact
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

   	[CmdletBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Contact')]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{
		
		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['InputObject']))
		{

			$PipelineInput = $true

		}

		else
		{
	
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

		}		

		$_RemoteSupportContactsCol = New-Object System.Collections.ArrayList
		$_TaskCollection           = New-Object System.Collections.ArrayList

	}

	Process 
	{
		
		if ($InputObject -is [PSCustomObject]) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Remote Support Contact Object provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

			If ($InputObject.type -eq 'Contact')
			{

				If (-not($InputObject.ApplianceConnection))
				{

					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportContactException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message "The InputObject object resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				[void]$_RemoteSupportContactsCol.Add($InputObject)

			}

			else
			{

				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportContactException InvalidArgumentValue InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message "The InputObject object resource is not an expected type.  The allowed resource category type is 'Contact'.  Please check the object provided and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		else 
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				"[{0}] Processing Appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

				"[{0}] Processing Contact Name {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject | Write-Verbose

				Try
				{

					$_Contact = Get-HPOVRemoteSupportContact -ApplianceConnection $_appliance | Where-Object firstName -eq $InputObject

					$_Contact | ForEach-Object {

						[void]$_RemoteSupportContactsCol.Add($_)

					}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}				

			}

		}

	}

	End
	{

		"[{0}] Begin resource removal process." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		foreach ($_contact in $_RemoteSupportContactsCol) 
		{

			$Name          = "{0} {1}" -f $_contact.firstName, $_contact.lastName
			$RemoveMessage = "Remove Remote Support Contact '{0}'" -f $Name

			if ($_contact.default)
			{

				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.RemoteSupportContactException UnableToRemoveDefaultContact InvalidOperation "Contact" -TargetType 'PSObject' -Message ("The Contact resource '{0}' is currently the default.  The removal of the Default Contact is not supported.  If you wish to remove this contact, please set another contact as the Default first." -f $Name)
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			else
			{

				if ($PSCmdlet.ShouldProcess($_contact.ApplianceConnection.Name,$RemoveMessage))
				{   
							 
					Try
					{
					
						$_task = Send-HPOVRequest -Uri $_contact.uri -Method DELETE -Hostname $_contact.ApplianceConnection.Name -AddHeader @{'If-Match' = $_contact.eTag}

						[void]$_TaskCollection.Add($_task)

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

				elseif ($PSBoundParameters['WhatIf'])
				{

					"[{0}] Caller passed -WhatIf Parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

				else
				{

					"[{0}] Caller selected NO to confirmation prompt." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				}

			}
			
		}

		Return $_TaskCollection

	}

}
