function Remove-HPOVServerProfile 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('uri','name','profile')]
		[Object]$ServerProfile,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false, ParameterSetName = "default")]
		[Switch]$force
	
	)

   Begin 
   {

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['ServerProfile']))
		{

			$PipelineINput = $true

		}

		else
		{

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

		}

		if($ApplianceConnection.count -gt 1)
		{

			# Check for appliance specific URI Parameters and error if more than one appliance connection supplied
			if (($ServerProfile -is [string]) -and ($ServerProfile.StartsWith($ServerProfilesUri))) 
			{
					
				"[{0}] SourceName is a Server Profile URI: $($ServerProfile)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				$ErrorRecord = New-ErrorRecord ArgumentNullException ParametersNotSpecified InvalidArgument 'Remove-HPOVServerProfile' -Message "The input Parameter 'profile' is a resource URI. For multiple appliance connections this is not supported."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			}

			if (($ServerProfile -is [array]) -and ($ServerProfile.getvalue(0).gettype() -is [string]) -and $ServerProfile -match '/rest/') 
			{
				
				"[{0}] Assign is a Server Profile URI: $($SourceName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				$ErrorRecord = New-ErrorRecord ArgumentNullException ParametersNotSpecified InvalidArgument 'Remove-HPOVServerProfile' -Message "The input Parameter 'profile' is a resource URI. For multiple appliance connections this is not supported."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

		}

	}

	Process 
	{

		"[{0}] Profile input type:  {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $ServerProfile.gettype() | Write-Verbose

		foreach ($_profile in $ServerProfile) 
		{

			if ($_profile -is [String] -and (-not($_profile.StartsWith.($ServerProfilesUri)))) 
			{

				Try
				{

					$_profile = Get-HPOVServerProfile -Name $_profile -ApplianceConnection $ApplianceConnection -ErrorAction Stop

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($_profile -is [String])
			{

				Try
				{

					$_profile = Send-HPOVRequest $_profile -Hostname $ApplianceConnection

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($_profile -is [PSCustomObject] -and $_profile.category -ine $ResourceCategoryEnum.ServerProfile) 
			{
				
				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'SeverProfile' -Message ("Invalid profile object provided: {0}.  Please verify the object and try again." -f $_profile.name )
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if ($PSCmdlet.ShouldProcess($ApplianceConnection.Name,("remove Server Profile {0} from appliance?" -f $_profile.name )))
			{   
				
				$uri = $_profile.uri

				if ($PSBoundParameters['Force'])
				{

					$uri += '?force=true'

				}

				Try
				{

					$_resp = Send-HPOVRequest -Uri $uri -Method DELETE -Hostname $ApplianceConnection

					$_resp

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($PSBoundParameters['Whatif'])
			{

				"[{0}] -WhatIf provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

			else
			{

				"[{0}] User cancelled." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
