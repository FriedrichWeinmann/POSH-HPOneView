function BuildGroupList
{

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Position = 0, Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Search,

		[Parameter (Position = 1, Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Username,

		[Parameter (Position = 2, Mandatory = $false, ParameterSetName = 'Default')]
		[SecureString]$Password,

		[Parameter (Position = 3, Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Directory,

		[Parameter (Position = 4, Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection

	)

	Begin
	{

		"[{0}] Processing Search: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Search | Write-Verbose

		$_Collection = New-Object System.Collections.ArrayList

		$_body = @{
			
			type             = 'Group2RoleSearchContext';
			directoryName    = $Directory;
			userName         = $Username;
			password         = $Password;
			searchContext    = $Search

		}

		if ($PSBoundParameters['Password'])
		{

			$_body.password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
			
		}

	}

	Process
	{

		$_uri = $AuthnDirectorySearchContext

		if ($Search.ToLower().StartsWith('ou=') -or $Search.ToLower().StartsWith('cn=') -or $Search.ToLower().StartsWith('dc='))
		{

			"[{0}] Navigating tree" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_body | Add-Member -NotePropertyName start -NotePropertyValue 0 -force

		}

		else
		{

			"[{0}] Searching for group name" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_GroupSearch = $True

			$_uri += '/search'		

		}

		Try
		{

			$_Resp = Send-HPOVRequest -uri $_uri -Method POST -body $_body -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not($_GroupSearch))
		{

			ForEach ($_ChildOU in ($_Resp | Where-Object hasChildren))
			{

				"[{0}] Processing Child OU {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ChildOU.distinguishedName | Write-Verbose

				$_Groups = BuildGroupList $_ChildOU.distinguishedName $Username $Password $Directory $ApplianceConnection

				ForEach ($_group in $_Groups)
				{
			
					[void]$_Collection.Add($_group)
			
				}

			}

		}
		
		ForEach ($_DirGroup in ($_Resp | Where-Object groupType))
		{

			"[{0}] Processing Group {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_DirGroup.displayName.Replace('CN=',$null) | Write-Verbose

			$_entry = New-Object HPOneView.Appliance.LdapDirectoryGroup($_DirGroup.displayName.Replace('CN=',$null),
																		$_DirGroup.distinguishedName, 
																		$_DirGroup.distinguishedName.Replace($_DirGroup.displayName + ',',$null), 
																		$Directory)

			[void]$_Collection.Add($_entry)

		}

	}

	End
	{

		Return $_Collection
	
	}
	
}
