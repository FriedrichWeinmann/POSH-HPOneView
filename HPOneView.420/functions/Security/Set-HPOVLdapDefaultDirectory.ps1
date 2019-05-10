function Set-HPOVLdapDefaultDirectory 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdletBinding (SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias('Directory')]
		[Object]$InputObject,

		[Switch]$DisableLocalLogin,
	
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName)]
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
			
			$PipelineInput = $True 
	
		}

		else
		{

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

		$_TaskCollection      = New-Object System.Collections.ArrayList
		$_DirectoryCollection = New-Object System.Collections.ArrayList
	
	}

	#Build collection of objects to Process
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing Appliance $($_appliance.Name) (of $($ApplianceConnection.Count)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Create default Directory configuration object
			$_DefaultDirectoryConfig = [PSCustomObject]@{
			
				allowLocalLogin     = (-not($DisableLocalLogin.IsPresent));
				defaultLoginDomain  = $Null;
				ApplianceConnection = $_appliance

			}

			switch ($InputObject.Gettype().Name) 
			{

				"String" 
				{

					if ($InputObject -ne "Local") 
					{

						"[{0}] Authentication Directory Name provided: $InputObject" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						Try
						{

							$InputObject = Get-HPOVLdapDirectory -Name $InputObject -Hostname $_appliance.Name -ErrorAction Stop

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

					}

					elseif ($InputObject -eq "Local") 
					{

						$InputObject = [PSCustomObject] @{

							type                = 'LoginDomainConfigInfoDto';
							name                = "LOCAL";
							uri                 = "";
							loginDomain         = "0";

						}

					}

				}

				"PSCustomObject" 
				{

					if ($InputObject.type -match 'LoginDomainConfig') 
					{

						"[{0}] Authentication Directory Object provided: {1} ({2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $InputObject.name, $InputObject.uri | Write-Verbose

						$InputObject.type = 'LoginDomainConfigInfoDto'

					}

					else 
					{

						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.LdapDirectoryException InvalidAuthDirectoryObject InvalidArgument "InputObject" -TargetType "PSObject" -Message "The authentication directory object type '$($InputObject.type)' provided is not correct.  The type must be 'LoginDomainConfigVersion200'.  Please correct the value and try again."

						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

			}

			$_DefaultDirectoryConfig.defaultLoginDomain = ($InputObject | Select-Object type,loginDomain,name,eTag,uri)

			[void]$_DirectoryCollection.Add($_DefaultDirectoryConfig)

		}

	}

	# Process objects here
	End 
	{

		ForEach ($_DirectoryToProcess in $_DirectoryCollection)
		{

			if ($PSCmdlet.ShouldProcess($_DirectoryToProcess.ApplianceConnection.Name,"Set appliance authentication directory $($_DirectoryToProcess.defaultLoginDomain.name) as default domain")) 
			{
		
				"[{0}] Setting default Authentication Directory to: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_DirectoryToProcess.defaultLoginDomain.name | Write-Verbose

				Try
				{

					$_resp = Send-HPOVRequest -Uri $authnSettingsUri -Method POST -Body $_DirectoryToProcess -Hostname $_DirectoryToProcess.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($IsWindows)
				{

					"[{0}] Setting PowerShell library AuthProvider registry (HKCU:\Software\Hewlett-Packard\HPOneView) value to 'AuthProvider#{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_DirectoryToProcess.defaultLoginDomain.name | Write-Verbose

					Set-ItemProperty -Path HKCU:\Software\Hewlett-Packard\HPOneView -Name ("AuthProvider#{0}" -f $_DirectoryToProcess.ApplianceConnection.Name) -Value $_DirectoryToProcess.defaultLoginDomain.name -Type STRING | Write-Verbose

				}
				
			}

			elseif ($PSBoundParameters['WhatIf'])
			{

				"[{0}] WhatIf was passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_resp = $null

			}

			else
			{

				"[{0}] User likely selected 'No' to prompt." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_resp = $null

			}

			$_resp

		}

	}

}
