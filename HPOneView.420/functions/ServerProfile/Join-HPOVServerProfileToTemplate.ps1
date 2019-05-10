function Join-HPOVServerProfileToTemplate 
{
		
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ("t")]
		[object]$Template,

		[Parameter (Mandatory)]
		[Alias ("p", 'Profile')] 
		[object]$ServerProfile,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = $Global:ConnectedSessions

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
		
		# If multiple appliance connections check for URI values in the Parameters
		If($ApplianceConnection.count -gt 1)
		{
			
			If ($template -is [string] -and $template.startswith('/rest/'))
			{

				"[{0}] $template" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidTemplateParameter InvalidArgument 'Template' -Message "Template Parameter as URI is not supported with multiple appliance connections."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			If ($ServerProfile -is [string] -and $ServerProfile.startswith('/rest/'))
			{

				"[{0}] $ServerProfile" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ErrorRecord = New-ErrorRecord HPOneView.ServerProfileResourceException InvalidProfileParameter InvalidArgument 'ServerProfile' -Message "ServerProfile Parameter as URI is not supported with multiple appliance connections."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

		}

		$uri = $ServerProfilesUri

		$colStatus = New-Object System.Collections.ArrayList

	}
	
	Process 
	{
		
		ForEach($_Connection in $ApplianceConnection)
		{
		
			# Process the template Parameter
			# Template passed as string
			if ($template -is [string])
			{
				
				# If the URI is passed as set the Template Uri variable. Should not Process if multiple connections identified
				if ($template.StartsWith('/rest'))
				{ 

					"[{0}] Template URI: $template" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					$templateUri = $template
			
				}

				# Otherwise, perform a lookup of the Enclosure Group
				else
				{

					"[{0}] Template Name: $template" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose					    
				
					Try 
					{

						$templateUri = (Get-HPOVServerProfileTemplate -Name $template -appliance $ApplianceConnection -ErrorAction Stop).Uri

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
				
				}

			}
									
			# Else the template object or template object collection is passed
			elseif (($template -is [Object]) -and ($template.category -eq $ResourceCategoryEnum.ServerProfileTemplate)) 
			{ 

				"[{0}] Template object provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$thisTemplate = $template | Where-Object { $_.ApplianceConnection.name -eq $_Connection.name }

				$templateUri = $thisTemplate.uri

				"[{0}] Enclosure Group Name: $($thisTemplate.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Enclosure Group Uri: $($thisTemplate.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			# Process the profile Parameter
			# Profile passed as string
			if ($ServerProfile -is [string])
			{
				
				# If the URI is passed as set the Template Uri variable. Should not Process if multiple connections identified
				if ($ServerProfile.StartsWith('/rest'))
				{ 

					"[{0}] Template URI: $ServerProfile" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$thisProfile = Send-HPOVRequest $ServerProfile -appliance $_Connection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
				
				}

				# Otherwise, perform a lookup of the Enclosure Group
				else
				{

					"[{0}] Template Name: $ServerProfile" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose					    
				
					Try
					{

						$thisProfile = Get-HPOVServerProfile -Name $ServerProfile -appliance $_Connection -ErrorAction Stop

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

				}

			}
									
			# Else the template object or template object collection is passed
			elseif (($ServerProfile -is [Object]) -and ($ServerProfile.category -eq $ResourceCategoryEnum.ServerProfile)) 
			{ 

				"[{0}] Profile object provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$thisProfile = $ServerProfile | Where-Object { $_.ApplianceConnection.name -eq $_Connection.name }

				"[{0}] Enclosure Group Name: $($thisProfile.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Enclosure Group Uri: $($thisProfile.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			if ($thisProfile.ApplianceConnection.name -eq $_Connection.name)
			{
				
				$thisProfile.serverProfileTemplateUri = $templateUri

				Try
				{

					$task = Set-HPOVResource $thisProfile -appliance $_Connection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				[void]$colStatus.Add($task)

			}

		}

	} # End Process Block

	End 
	{

		return $colStatus

	}

}
