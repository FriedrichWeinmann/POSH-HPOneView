function Update-HPOVEnclosure 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Refresh", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param 
	(
		
		[Parameter (ValueFromPipeline, Mandatory = $false, ParameterSetName = "Reapply")]
		[Parameter (ValueFromPipeline, Mandatory = $false, ParameterSetName = "Refresh")]
		[ValidateNotNullOrEmpty()]
		[Alias('Enclosure')]
		[object]$InputObject,

		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Reapply")]
		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false, ParameterSetName = "Refresh")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory, ParameterSetName = "Refresh")]
		[Switch]$Refresh,

		[Parameter (Mandatory = $false, ParameterSetName = "Refresh")]
		[String]$Hostname,

		[Parameter (Mandatory = $false, ParameterSetName = "Refresh")]
		[string]$Username,

		[Parameter (Mandatory = $false, ParameterSetName = "Refresh")]
		[Object]$Password,

		[Parameter (Mandatory = $false, ParameterSetName = "Refresh")]
		[PSCredential]$Credential,

		[Parameter (Mandatory, ParameterSetName = "Reapply")]
		[Switch]$Reapply,

		[Parameter (Mandatory = $false, ParameterSetName = "Reapply")]
		[Parameter (Mandatory = $false, ParameterSetName = "Refresh")]
		[switch]$Async

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

		$_TaskCollection           = New-Object System.Collections.ArrayList
		$_EnclosureCollection      = New-Object System.Collections.ArrayList
		$_RefreshOptionsCollection = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		if ($PipelineInput -or $InputObject -is [PSCustomobject]) 
		{
		
			"[{0}] Processing Pipeline input." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Error if the input value is not a PSObject
			if (-not $InputObject -is [PSCustomObject])
			{

				$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException InvalidEnclosureObjectType InvalidArgument 'InputObject' -TargetType 'PSObject' -Message "The provided InputObject value is not a valid PSObject ($($InputObject.GetType().Name)). Please correct your input value."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			"[{0}] Enclosure PSObject: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), ($InputObject | out-string) | Write-Verbose

			# Validate the Input object is the allowed category
			if ($InputObject.category -ne $ResourceCategoryEnum['Enclosure'])
			{

				$ExceptionMessage = "The provided InputObject object ({0}) category '{1}' is not an allowed value.  Expected category value is 'enclosures'. Please correct your input value." -f $InputObject.name, $InputObject.category
				$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException InvalidEnclosureCategory InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			if(-not $InputObject.ApplianceConnection)
			{

				$ExceptionMessage = "The provided InputObject object ({0}) does not contain the required 'ApplianceConnection' object property. Please correct your input value." -f $InputObject.name
				$ErrorRecord = New-ErrorRecord HPOneView.EnclosureResourceException InvalidEnclosureObject InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			[void]$_EnclosureCollection.Add($InputObject)
		
		}

		# Not Pipeline input, and support Array of Enclosure Name or PSObject
		else
		{

			"[{0}] Processing Enclosure Parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			ForEach ($_encl in $InputObject)
			{
					
				"[{0}] Enclosure value: {1}." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_encl | Write-Verbose

				"[{0}] Looking for Enclosure Name on connected sessions provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				# Loop through all Appliance Connections
				ForEach ($_appliance in $ApplianceConnection)
				{

					"[{0}] Processing '{1}' Session." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

					Try
					{

						$_resp = Get-HPOVLogicalEnclosure $_encl -ApplianceConnection $_appliance.Name

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					[void]$_EnclosureCollection.Add($_resp)

				}
					
			}

		}

	}

	End
	{
		# Perform the work
		ForEach ($_enclosure in $_EnclosureCollection) 
		{

			"[{0}] Processing Enclosure: '$($_enclosure.name) [$($_enclosure.uri)]'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			switch ($PSCmdlet.ParameterSetName) 
			{

				"Reapply" 
				{ 

					"[{0}] Reapply Enclosure configuration." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_Params = @{ uri = $_enclosure.uri + "/configuration"; method = 'PUT' }
						
				}
						
				"Refresh"
				{ 

					"[{0}] Refreshing Enclosure data." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$_RefreshOptions = NewObject -EnclosureRefresh

					$_uri = $_enclosure.uri + "/refreshState"

					if ($_enclosure.state -ieq 'unmanaged' -and $_enclosure.stateReason -ieq 'unowned')
					{

						$_RefreshOptions.refreshForceOptions = NewObject -EnclosureRefreshForceOptions

						if (-not $PSBoundParameters['Username'] -and -not $PSBoundParameters['Credential'])
						{

							$ExceptionMessage = "The appliance can no longer communicate with {0} Enclosure, and requires a valid Username, Password and Hostname/IPAddress.  Please provide the correct parameters." -f $_enclosure.name
							$ErrorRecord = New-ErrorRecord HPOneView.Library.UnsupportedArgumentException MissingRequiredUsernameParameter InvalidOperation 'Enclosure' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						if (-not $PSBoundParameters['Password'] -and -not $PSBoundParameters['Credential'])
						{

							$ExceptionMessage = "The appliance can no longer communicate with {0} Enclosure, and requires a valid Username, Password and Hostname/IPAddress.  Please provide the correct parameters." -f $_enclosure.name
							$ErrorRecord = New-ErrorRecord HPOneView.Library.UnsupportedArgumentException MissingRequiredPasswordParameter InvalidOperation 'Password' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						if (-not $PSBoundParameters['Hostname'])
						{

							$ExceptionMessage = "The appliance can no longer communicate with {0} Enclosure, and requires a valid Username, Password and Hostname/IPAddress.  Please provide the correct parameters." -f $_enclosure.name
							$ErrorRecord = New-ErrorRecord HPOneView.Library.UnsupportedArgumentException MissingRequiredHostnameParameter InvalidOperation 'Hostname' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						if ($PSBoundParameters['Credential'])
						{

							$_Username = $Credential.Username
							$_Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

						}

						elseif ($PSBoundParameters['Username'])
						{

							Write-Warning "The -Username and -Password parameters are being deprecated.  Please transition your scripts to using the -Credential parameter."

							$_Username = $Username.clone()

							if ($Password -is [SecureString])
							{

								$_Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

							}

							else
							{

								$_Password = $Password.Clone()

							}

						}

						$_RefreshOptions.refreshForceOptions.address  = $Hostname
						$_RefreshOptions.refreshForceOptions.username = $_Username
						$_RefreshOptions.refreshForceOptions.password = $_Password

					}

					$_Params = @{ uri = $_uri; method = 'PUT'; body = $_RefreshOptions }
						
				}
				
			}
			
			if ($PSCmdlet.ShouldProcess($_enclosure.name,"$($PSCmdlet.ParameterSetName) Enclosure configuration. WARNING: Depending on this action, there might be a brief outage."))
			{ 

				"[{0}] Sending request to $($PSCmdlet.ParameterSetName) Enclosure configuration" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					
					$_task = Send-HPOVRequest @_Params -Hostname $_enclosure.ApplianceConnection.Name

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if (-not $PSBoundParameters['Async'])
				{
					
					 $_task | Wait-HPOVTaskComplete
				
				}

				else
				{

					$_task

				}

			}

			elseif ($PSBoundParameters['WhatIf'])
			{
				
				"[{0}] User included -WhatIf." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
			
			}

			else
			{

				"[{0}] User cancelled." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}           

		}

	}

}
