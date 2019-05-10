function Get-HPOVBaselineRepository
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $False)]
		[ValidateNotNullOrEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $False)]
		[ValidateSet ('Internal', 'External')]
		[String]$Type,
	
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

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing Appliance {1} (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose 

			"[{0}] Getting baseline repo information resources" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 

			$_Uri = '{0}?sort=name:asc' -f $ApplianceRepositoriesUri

			if ($Name)
			{

				$_Uri += "&filter=name EQ '{0}'" -f $Name

			}

			if ($Type)
			{

				$_Uri += "&filter=repositoryType EQ '{0}'" -f $RepositoryType[$Type]

			}

			Try
			{

				$_BaselineRepos = Send-HPOVRequest -Uri $_Uri -Hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($Name -and $_BaselineRepos.Count -eq 0)
			{

				$ExceptionMessage = "The specified '{0}' baseline repository resource was not found on '{1}' appliance connection.  Please check the name and try again." -f $Name, $_appliance.Name 
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineRepositoryResourceException BaselineRepositoryResourceNotFound ObjectNotFound "Name" -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				ForEach ($_RepoEntry in $_BaselineRepos.members)
				{

					$_RepoEntry.PSObject.TypeNames.Insert(0,'HPOneView.Appliance.BaselineRepository')

					$_RepoEntry

				}

			}

		}
		
	}

	End
	{

		"[{0}] done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
