function Search-HPOVIndex  
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]$Search,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]$Category,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[int]$Count = 50,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[int]$Start = 0,

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

		# Initialize collection to hold multiple volume attachments objects
		$_IndexSearchResults = New-Object System.Collections.ArrayList

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[$($MyInvocation.InvocationName.ToString().ToUpper())] Processing Appliance Connection '{0}' (of {1})" -f $_appliance.Name, $ApplianceConnection.count | Write-Verbose

			$uri = $indexuri + '?start=' + $start.ToString() + '&count=' + $count.ToString()
		
			if ($search) 
			{ 
				
				$uri = $uri + "&userQuery=" + $search 
			
			}
			
			if ($category) 
			{ 
				
				$uri = $uri + "&category=" + $category 
			
			}
			
			$uri = $uri.Replace(" ", "%20")

			Try
			{

				$r = Send-HPOVRequest $uri -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}		
			
			if ($r.count -eq 0 -and $PSBoundParameters['Search']) 
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException NoIndexResults ObjectNotFound 'Search' -Message ("No Index results found for '{0}' on '{1}." -f $Search, $_appliance.Name)
				$PSCmdlet.WriteError($ErrorRecord)
			}

			else 
			{
				
				$r.members | ForEach-Object {

					$_.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.IndexResource')

					[void]$_IndexSearchResults.Add($_)

				}

			}

		}

	}

	End
	{

		"Done. {0} index resource(s) found." -f $_IndexSearchResults.count | Write-Verbose

		Return $_IndexSearchResults

	}

}
