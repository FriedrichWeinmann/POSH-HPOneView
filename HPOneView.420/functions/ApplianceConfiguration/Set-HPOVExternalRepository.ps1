function Set-HPOVExternalRepository
{

	# .ExternalHelp HPOneView.420.psm1-help.xml
	
	[CmdLetBinding (DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
	Param
	(

		[Parameter (Mandatory, ParameterSetName = "Default", ValueFromPipeline)]
		[Parameter (Mandatory, ParameterSetName = "PSCredentials", ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'PSCredentials')]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = 'PSCredentials')]
		[PSCredential]$Credential,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[String]$Username,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[SecureString]$Password,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'PSCredentials')]
		[String]$Certificate,

		[Parameter (Mandatory = $false,ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false,ParameterSetName = 'PSCredentials')]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = "default", ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)
	
	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not $PSBoundParameters['InputObject'])
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

	}

	Process
	{

		if ($InputObject.category -ne 'repository-manager')
		{

			$ExceptionMessage = "The specified '{0}' InputObject parameter value is not supported." -f $InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneView.InputObjectResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($InputObject.repositoryType -eq 'FirmwareInternalRepo')
		{

			$ExceptionMessage = "The specified '{0}' InputObject parameter value is an Internal Baseline Repository.  Only External repositories can be removed." -f $InputObject.name
			$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineRepositoryResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		$_UpdatedInputObject = NewObject -ExternalRepository | Select-Object * -ExcludeProperty repositoryType, repositoryURI
		$_UpdatedInputObject.repositoryName = $InputObject.name

		# Commented out until PATCH fully works
		#$_UpdatedInputObject = NewObject -PatchOperation
		#$_UpdatedInputObject.op = 'replace'
		#$_UpdatedInputObject.path = '/repository'

		#$_UpdatedValues = [PSCustomObject]@{}

		[Uri]$_RepositoryUrlObject       = $InputObject.repositoryUrl.Clone()
		[String]$_RespositoryUrlToUpdate = $InputObject.repositoryUrl.Clone()

		switch ($PSBoundParameters.Keys)
		{

			'Name'
			{

				"[{0}] Updating repository name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose
				#$_UpdatedValues | Add-Member -NotePropertyName respositoryName -NotePropertyValue $Name
				$_UpdatedInputObject.repositoryName = $Name

			}

			'Certificate'
			{

				"[{0}] Updating repository HTTPS certificate." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				#$_UpdatedValues | Add-Member -NotePropertyName base64Data -NotePropertyValue $Certificate
				$_UpdatedInputObject.base64Data = $Certificate

			}

			'Credential'
			{

				"[{0}] Updating repository credentials with PSCredential object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$Username        = $Credential.UserName
				$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

				#$_UpdatedValues | Add-Member -NotePropertyName userName -NotePropertyValue $Username
				#$_UpdatedValues | Add-Member -NotePropertyName password -NotePropertyValue $_DecryptPassword
				$_UpdatedInputObject.userName = $Username
				$_UpdatedInputObject.password = $_DecryptPassword

			}

			'Username'
			{

				"[{0}] Updating repository username." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				#$_UpdatedValues | Add-Member -NotePropertyName userName -NotePropertyValue $userName
				$_UpdatedInputObject.userName = $Username

			}

			'Password'
			{

				"[{0}] Updating repository password." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

				#$_UpdatedValues | Add-Member -NotePropertyName password -NotePropertyValue $_DecryptPassword

				$_UpdatedInputObject.password = $_DecryptPassword

			}

		}

		#$_UpdatedInputObject.value = $_UpdatedValues
	
		if ($PSCmdlet.ShouldProcess($InputObject.Name, ("Modify repository from appliance {0}" -f $InputObject.ApplianceConnection.Name)))
		{   
			
			Try
			{

				#$_Resp = Send-HPOVRequest -Uri $InputObject.uri -Method PATCH -Body $_UpdatedInputObject -AddHeader @{'If-Match' = $InputObject.eTag} -Hostname $InputObject.ApplianceConnection
				$_Resp = Send-HPOVRequest -Uri $InputObject.uri -Method PUT -Body $_UpdatedInputObject -AddHeader @{'If-Match' = $InputObject.eTag} -Hostname $InputObject.ApplianceConnection

				if (-not $PSBoundParameters['Async'])
				{

					 $_Resp | Wait-HPOVTaskComplete

				}

				else
				{

					$_Resp

				}

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		elseif ($PSBoundParameters['WhatIf'])
		{

			"[{0}] Caller passed -WhatIf Parameter." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		else
		{

			"[{0}] Caller selected NO to confirmation prompt." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

	}

	End
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
