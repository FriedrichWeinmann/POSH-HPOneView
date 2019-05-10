function Restore-HPOVCustomBaseline
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(
	
		[Parameter (Mandatory = $False)]
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

		$_TaskCollection     = New-Object System.Collections.ArrayList
		$_BaselineCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing Appliance $($_appliance.Name) (of $($ApplianceConnection.Count))" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			"[{0}] Getting all baseline resources" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_baselineresources = Send-HPOVRequest $fwUploadUri -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}
			
			foreach ($_baseline in ($_baselineresources.members | Where-Object bundleType -eq 'Custom' -and state -eq 'Removed'))
			{

				$_CustomBaselineRestore = NewObject -CustomBaselineRestore

				$_CustomBaselineRestore.baselineUri        = $_baseline.uri	
				$_CustomBaselineRestore.customBaselineName = $_baseline.name

				"[{0}] Looking up Associations for '$($_baseline.name) [$($_baseline.uuid)]' custom baseline." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					$_uri = '{0}?parentUri={1}' -f $AssociationsUri, $_baseline.uri

					$_baselineassociations = Send-HPOVRequest -Uri $_uri -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				foreach ($_association in $_baselineassociations.members)
				{

					"[{0}] Adding '$($_association.childUri)' to object collection." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					[void]$_CustomBaselineRestore.hotfixUris.Add($_association.childUri)

				}

				"[{0}] Sending request to recreate '$_CustomBaselineRestore.customBaselineName' custom baseline." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_resp = Send-HPOVRequest $fwUploadUri $_CustomBaselineRestore -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				[void]$_TaskCollection.Add($_resp)
				
			}				

		}
		
	}

	End
	{

		"[{0}] done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		Return $_TaskCollection

	}


}
