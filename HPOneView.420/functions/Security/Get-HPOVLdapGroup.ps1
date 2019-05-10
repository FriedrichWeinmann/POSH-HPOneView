function Get-HPOVLdapGroup 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Alias ("group","GroupName")]
		[string]$Name,

		[Parameter (Mandatory, ParameterSetName = 'Export')]
		[Alias ('x')]
		[ValidateScript({split-path $_ | Test-Path})]
		[string]$Export,
		
		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'Export')]
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

		$_DirectoryGroupsCollection = New-Object System.Collections.ArrayList
		
	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{
		
			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			Try
			{ 
				
				$_Groups = Send-HPOVRequest $AuthnEgroupRoleMappingUri -Hostname $_appliance.Name

				ForEach ($_Group in $_Groups.members)
				{

					$_Group.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.AuthDirectoryGroupRoleMapping") 
				
					[void]$_DirectoryGroupsCollection.Add($_Group)

				}

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}      

	}

	End 
	{

		if ($PSBoundParameters['Name']) 
		{ 
			
			$_DirectoryGroupsCollection = $_DirectoryGroupsCollection | Where-Object egroup -eq $Name

			if ($_DirectoryGroupsCollection.Count -eq 0)
			{
				
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.LdapDirectoryGroupException AuthDirectoryGroupResourceNotFound ObjectNotFound "Name" -Message "The specified '$name' Authentication Directory Group resource not found.  Please check the name and try again."
				
				$PSCmdlet.WriteError($ErrorRecord)

			}
		
		}

		if ($PSBoundParameters['Export'])
		{ 
			
			$_DirectoryGroupsCollection | convertto-json > $Export 
		
		}
 
		else 
		{

			Return $_DirectoryGroupsCollection

		}

	}

}
