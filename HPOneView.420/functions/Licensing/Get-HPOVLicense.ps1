function Get-HPOVLicense 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param
	(

		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[ValidateSet ("OneViewAdvanced", "OneView", "OneViewAdvancedNoiLO", "OneViewNoiLO","all")]
		[String]$Type,
		
		[Parameter (Mandatory = $False, ParameterSetName = "Default")]
		[ValidateSet ("Unlicensed", "Permanent",$null)]
		[String]$State,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Switch]$Summary,
		
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Switch]$Report,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
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

		$_LicenseResources = New-Object System.Collections.ArrayList

		[string]$filter = $null
		
		If ($PSboundParameters['Type'])
		{

			"[{0}] License Type: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Type | Write-Verbose

			switch ($Type)
			{

				# User wants the HP OneView License report
				{$_ -match "OneView","OneViewAdvanced"} 
				{

					$filter += "?filter=`"product='HP OneView Advanced'`""

				}

				# User wants the HP OneView without iLO License Report
				{$_ -match "OneViewNoiLO","OneViewAdvancedNoiLO"} 
				{

					$filter += "?filter=`"product='HP OneView Advanced w/o iLO'`""

				}

			}

		}

		If ($PSboundParameters['State'])
		{

			"[{0}] License State: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $State | Write-Verbose

			# Check to see if the license type/product was specified, as we would have an existing filter value
			If ($filter)
			{

				$filter += "&filter=`"licenseType='$State'`""

			}
			ElseIf (-not($filter))
			{

				$filter += "?filter=`"licenseType='$State'`""

			}

		}

		ElseIf (-not($PSboundParameters['State']))
		{

			"[{0}] No license state provided ({1})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $State | Write-Verbose

		}
  
		If ($PSboundParameters['Report'])
		{
			
			"[{0}] Parameter is being deprecated." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Write-Warning "The -Report parameter is being deprecated.  Node information is contained within the .Nodes property of the returned object."
			
		}

		elseif ($PSboundParameters['Summary'])
		{

			"[{0}] Generating Summary Report" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			# Check to see if the license type/product was specified, as we would have an existing filter value
			If ($filter)
			{

				$disSummary = "&view=summary"

			}
			ElseIf (-not($filter))
			{

				$disSummary = "?view=summary"

			}

		}

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose
					
			Try
			{

				# Send the request
				$_Uri = "{0}{1}{2}" -f $ApplianceLicensePoolUri, $Filter, $disSummary
				$_LicenseCol = Send-HPOVRequest -Uri $_Uri -Hostname $_appliance

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			ForEach ($_license in $_LicenseCol.members)
			{

				$_Nodes          = New-Object 'System.Collections.Generic.List[HPOneView.Appliance.LicensedNode]'
				# $_UnlicensedNodes = New-Object 'System.Collections.Generic.List[HPOneView.Appliance.UnlicensedNode]'
				$_AdditionalKeys = New-Object 'System.Collections.Generic.List[String]'

				ForEach ($_node in $_license.nodes)
				{

					"[{0}] Adding '{1}' to '{2}' license pool collection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_node.nodeName, $_license.product | Write-Verbose

					$_LicensedNode = New-Object HPOneView.Appliance.LicensedNode ($_node.nodeName,
																				  $_node.nodeId,
																				  $_node.appliedDate,
																				  $_node.nodeUri)

					[void]$_Nodes.Add($_LicensedNode)

				}

				if ($_license.additionalKeys.Count -gt 0)
				{

					$_license.additionalKeys | ForEach-Object { [void]$_AdditionalKeys.Add($_) }

				}

				"[{0}] Creating '{1} ({2})' license pool object." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_license.product, $_license.licenseType | Write-Verbose

				New-Object HPOneView.Appliance.License ($_license.product,
														$_license.licenseType,
														$_license.productDescription,
														$_license.eon,
														$_license.salesOrder,
														$_license.availableCapacity,
														$_license.totalCapacity,
														$_license.key,
														$_license.uri,
														$_Nodes,
														$_AdditionalKeys,
														$_license.created,
														$_license.ApplianceConnection)

			}

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
