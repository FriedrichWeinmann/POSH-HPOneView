function New-HPOVExternalRepository
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdLetBinding (DefaultParameterSetName = 'Default')]
	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'PSCredentials')]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'PSCredentials')]
		[String]$Hostname,

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[Parameter (Mandatory, ParameterSetName = 'PSCredentials')]
		[String]$Directory,

		[Parameter (Mandatory, ParameterSetName = 'PSCredentials')]
		[PSCredential]$Credential,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[String]$Username,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[SecureString]$Password,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'PSCredentials')]
		[switch]$Http,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'PSCredentials')]
		[String]$Certificate,

		[Parameter (Mandatory = $false,ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false,ParameterSetName = 'PSCredentials')]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter (Mandatory = $false, ParameterSetName = 'PSCredentials')]
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

		if (-not $PSBoundParameters['Password'] -and $PSBoundParameters['Username'] -and $PSCmdlet.ParameterSetName -eq 'Default')
		{

			[SecureString]$Password = read-host -AsSecureString "Password"
			$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
			
		}

		elseif ($Password -is [SecureString] -and $PSCmdlet.ParameterSetName -eq 'Default')
		{

			$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))

		}

		elseif ($PSCmdlet.ParameterSetName -eq 'Default')
		{

			$_DecryptPassword = "$Password"

		}

		elseif ($PSBoundParameters['Credential'])
		{

			$Username        = $Credential.UserName
			$_DecryptPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

		}
		
		$_ExternalRepository = NewObject -ExternalRepository

		$_Protocol = 'https'

		if ($PSBoundParameters['Http'])
		{

			"[{0}] Setting protocol to HTTP." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_Protocol = 'http'

		}

		$_ExternalRepository.repositoryName = $Name
		$_ExternalRepository.userName       = $Username
		$_ExternalRepository.password       = $_DecryptPassword
		$_ExternalRepository.repositoryURI  = '{0}://{1}/{2}' -f $_Protocol, $Hostname, $Directory
		$_ExternalRepository.base64Data     = $Certificate
		
		# Post the new object to the appliancenvocationName.ToString().ToUpper())] Processing Appliance $($_Connection.Name)"
		Try
		{

			$_Resp = Send-HPOVRequest -Uri $ApplianceRepositoriesUri -Method POST $_ExternalRepository -Hostname $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if (-not($PSBoundParameters['Async']))
		{

			$_Resp | Wait-HPOVTaskComplete

		}

		else
		{

			$_Resp

		}

	}
	
	End 
	{
	
		"[{0}] Done." -f $MyInvocation.InvocationName.ToString() | Write-Verbose
	
	}

}
