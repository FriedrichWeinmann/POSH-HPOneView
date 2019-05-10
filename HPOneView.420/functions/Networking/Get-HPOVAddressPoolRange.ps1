function Get-HPOVAddressPoolRange 
{  

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[ValidateSet ('IPv4', 'vmac', 'vwwn', 'vsn', 'all')]
		[Alias('Pool')]
		[Object]$Type = 'all',

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "Pipeline")]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Pipeline")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($PSCmdlet.ParameterSetName -eq 'Pipeline')
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

		$_RangeList = New-Object System.Collections.ArrayList
					
	}

	Process 
	{

		if ($PipelineInput -or $PSBoundParameters['InputObject'])
		{

			if (($InputObject.category -match "id-pool-" -or $InputObject.category -eq 'id-range-IPV4-subnet') -and $InputObject.ApplianceConnection) 
			{

				foreach ($_RangeUri in $InputObject.rangeUris) 
				{

					Try
					{

						$_rangeObject = Send-HPOVRequest $_RangeUri -Hostname $InputObject.ApplianceConnection.Name

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					$_rangeObject | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AddressPoolRange") } 
					
					[void]$_RangeList.Add($_rangeObject)

				}

			}

			elseif ($InputObject.category -match "id-pool-" -and -not($InputObject.ApplianceConnection))
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException MissingApplianceConnectionProperty InvalidArgument 'InputObject' 'PSObject' -Message "The InputObject Parameter value does not contain an ApplianceConnection property.  Did this object come from Get-HPOVAddressPool or Send-HPOVRequest?  Please correct the Parameter value and try again."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			else 
			{
			
				$ExceptionMessage = "The InputObject Parameter value is not a valid Poll ID object.  Object Category '{0}', expected 'id-pool-vmac', 'id-pool-vwwn', or 'id-pool.vsn'.  Please correct the Parameter value and try again." -f $InputObject.category
				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			
			}

		}

		else
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				Try
				{

					$_AddressPoolCol = Get-HPOVAddressPool -Type $Type -ApplianceConnection $_appliance.Name -ErrorAction Stop

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				foreach ($_AddressPool in $_AddressPoolCol) 
				{

					ForEach ($_RangUri in $_AddressPool.rangeUris)
					{

						Try
						{

							$_rangeObject = Send-HPOVRequest $_RangUri -Hostname $_AddressPool.ApplianceConnection.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						$_rangeObject | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AddressPoolRange") } 

						[void]$_RangeList.Add($_rangeObject)

					}

				}

			}

		}	

	}

	End 
	{

		Return $_RangeList

	}

}
