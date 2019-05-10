function Set-HPOVRackMemberLocation
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Facilities.RackMember]$InputObject,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Int]$ULocation,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
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

		$_RackCol        = New-Object System.Collections.ArrayList
		$_TaskCollection = New-Object System.Collections.ArrayList

	}

	Process
	{

		"[{0}] RackMember Object provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name | Write-Verbose

		If (-not($InputObject.ApplianceConnection))
		{

			$ErrorRecord = New-ErrorRecord HPOneView.RackResourceException InvalidArgumentValue InvalidArgument "InputObject" -TargetType PSObject -Message "The InputObject object resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		# Get Rack from member
		Try
		{

			$Rack = Send-HPOVRequest -Uri $InputObject.RackUri -Hostname $InputObject.ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		($Rack.rackMounts | Where-Object mountUri -eq $InputObject.Uri).topUSlot = ($ULocation + $InputObject.UHeight - 1)

		Try
		{

			Send-HPOVRequest -Uri $Rack.uri -Method PUT -Body $Rack -Hostname $Rack.ApplianceConnection | Out-Null

			Get-HPOVRackMember -InputObject $Rack -Name $InputObject.Name -ErrorAction Stop

		}
		
		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
