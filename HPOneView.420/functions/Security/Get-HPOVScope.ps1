function Get-HPOVScope
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param
	(

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[ValidateNotNullorEmpty()]
		[SupportsWildcards()]
		[String]$Name,		

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Alias ('Appliance')]
		[ValidateNotNullOrEmpty()]
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

	}

	Process
	{

		$_uri = $ScopesUri

		if ($PSBoundParameters['Name'])
		{

			if ($Name.Contains('*'))
			{

				$_uri = "{0}?query=name matches '{1}'" -f $_uri, $Name.Replace('*','%25')

			}

			else
			{

				$_uri = "{0}?query=name eq '{1}'" -f $_uri, $Name

			}

		}		

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing {1} appliance connection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			# Get Scope resource
			Try
			{

				$_Scopes = Send-HPOVRequest $_uri -Hostname $_appliance				

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($PSBoundParameters['Name'] -and $_Scopes.count -eq 0)
			{

				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.ScopeResourceException ScopeResourceNotFound ObjectNotFound -TargetObject 'Name' -Message ('{0} was not found on {1} appliance.  Check the Name Parameter value.' -f $Name, $_appliance.Name)
				$PSCmdlet.WriteError($ErrorRecord)

			}

			# Process Scopes Collection from API
			ForEach ($_scopemember in $_Scopes.members)
			{

				$_Scope = New-Object HPOneView.Appliance.ScopeCollection($_scopemember.name, 
																		 $_scopemember.description, 
																		 $_scopemember.uri, 
																		 $_scopemember.eTag, 
																		 $_scopemember.ApplianceConnection)

				# Lookup Scope resource associations, and add to [ScopeCollectionMembers] Members property
				Try
				{

					$_IndexAssocationUri = '{0}?filter=scopeuris:{1}' -f $IndexUri, $_scopemember.uri

					$_AssociatedResources = Send-HPOVRequest -Uri $_IndexAssocationUri -Hostname $_appliance

				}

				Catch
				{

				  $PSCmdlet.ThrowTerminatingError($_)

				}

				ForEach ($_Member in ($_AssociatedResources.members | Sort name))
				{

					$_ScopeMember = New-Object HPOneView.Appliance.ScopeCollectionMemberEntry($_Member.name, $ScopeCategoryEnum[$_Member.category], $_Member.uri)

					[void]$_Scope.Members.Add($_ScopeMember)

				}

				$_Scope

			}

		}
		
	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
