function Remove-HPOVServerProfileTemplate
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = "default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('spt','name')]
		[Object]$ServerProfileTemplate,

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

		if (-not($PSBoundParameters['ServerProfileTemplate']))
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
			if (($ServerProfileTemplate -is [string]) -and ($ServerProfileTemplate.StartsWith($ServerProfileTemplatessUri))) 
			{
					
				"[{0}] SourceName is a Server Profile Template URI: $($ServerProfileTemplate)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ErrorRecord = New-ErrorRecord ArgumentNullException ParametersNotSpecified InvalidArgument 'ServerProfileTemplate' -Message "The input Parameter 'ServerProfileTemplate' is a resource URI. For multiple appliance connections this is not supported."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			}

			if (($ServerProfileTemplate -is [array]) -and ($ServerProfileTemplate.getvalue(0).gettype() -is [string]) -and $ServerProfileTemplate -match '/rest/') 
			{
				
				"[{0}] Assign is a Server Profile URI: $($ServerProfileTemplate)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				$ErrorRecord = New-ErrorRecord ArgumentNullException ParametersNotSpecified InvalidArgument 'ServerProfileTemplate' -Message "The input Parameter 'ServerProfileTemplate' is a resource URI. For multiple appliance connections this is not supported."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

		}

		$taskCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		"[{0}] Profile input type:  $($ServerProfileTemplate.gettype())" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		foreach ($_spt in $ServerProfileTemplate) 
		{

			if ($_spt -is [String] -and (-not($_spt.StartsWith.($ServerProfileTemplatessUri)))) 
			{

				Try
				{

					$_spt = Get-HPOVServerProfileTemplate -Name $_spt -ApplianceConnection $ApplianceConnection -ErrorAction Stop

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($_spt -is [String])
			{

				Try
				{

					$_spt = Send-HPOVRequest -Uri $_spt -Hostname $ApplianceConnection

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($_spt -is [PSCustomObject] -and $_spt.category -ine $ResourceCategoryEnum.ServerProfileTemplate) 
			{
				
				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'ServerProfileTemplate' -Message ("Invalid profile template object provided: {0}.  Please verify the object and try again." -f $_spt.name )
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if ($PSCmdlet.ShouldProcess($ApplianceConnection.Name,("remove Server Profile Template {0} from appliance?" -f $_spt.name )))
			{   
				
				$uri = $_spt.uri

				if ($PSBoundParameters['Force'])
				{

					$uri += '?force=true'

				}

				Try
				{

					$_resp = Send-HPOVRequest -uri $uri -method DELETE -Hostname $ApplianceConnection

					[void]$taskCollection.Add($_resp)

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

		Return $taskCollection

	}

}
