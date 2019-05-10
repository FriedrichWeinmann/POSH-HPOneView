function Set-HPOVServerHardwareType
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[Alias('Resource')]
		[validateNotNullorEmpty()]
		[Object]$InputObject,
	
		[Parameter (Mandatory)]
		[validateNotNullorEmpty()]
		[String]$Name,
			
		[Parameter (Mandatory = $false)]
		[String]$Description,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false)]
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

		# Support ApplianceConnection property value via pipeline from Enclosure Object
		if(-not $PSboundParameters['InputObject'])
		{

			$PipelineInput = $True

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
	
	}

	Process 
	{	

		# Validate the input object category is server-hardware-types
		if ($InputObject.category -ne 'server-hardware-types')
		{

			$ExceptionMessage = "The specified '{0}' InputObject parameter value is not supported type.  Only Server Hardware Type resources are allowed." -f $InputObject
			$ErrorRecord = New-ErrorRecord HPOneView.InputObjectResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_UpdatedSHTResourceDescriptions = [PSCustomObject]@{
			name        = $Name;
			description = $Description
		}

		"[{0}] Will update the SHT name from {1} to {2}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $Name | Write-Verbose

		if ($PSBoundParameters['Description'])
		{

			"[{0}] Will update the SHT sescription from {1} to {2}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.description, $Description | Write-Verbose		

		}
		
		try
		{

			$_resp = Send-HPOVRequest -Uri $InputObject.uri -Method PUT -Body $_UpdatedSHTResourceDescriptions -Hostname $ApplianceConnection

		}

		catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$_resp.PSObject.TypeNames.Insert(0, 'HPOneView.ServerHardwareType')
		$_resp

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
