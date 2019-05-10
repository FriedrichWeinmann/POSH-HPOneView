function Install-HPOVApplianceCertificate 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]

	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default', ValueFromPipeline)]
		[Alias ('PrivateKey', 'Certificate')]
		[ValidateNotNullOrEmpty()]
		[Object]$Path,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Switch]$Async,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
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

		$_TaskStatus = New-Object System.Collections.ArrayList

	}

	Process 
	{

		$_CertificateObject = NewObject -ApplianceSslCertificate

		'Path is valid: {0}' -f (Test-Path $Path) | Write-Verbose

		if ((Test-Path $Path) -or $Path -Is [System.IO.FileInfo])
		{

			"[{0}] Opening {1} file for reading.)" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Path | Write-Verbose

			Try
			{

				$_ReadFile = [System.IO.File]::OpenText($Path)
				$_Certificate = $_ReadFile.ReadToEnd()
				$_ReadFile.Close()
				$_CertificateObject.base64Data = ($_Certificate | Out-String) -join "`n"

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}			

		}

		elseif ($Path.Contains('-----BEGIN CERTIFICATE-----'))
		{

			"[{0}] Received certificate contents." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_CertificateObject.base64Data = ($Path | Out-String) -join "`n"
			
		}
		
		else 
		{

			$Exceptionmessage = 'The supplied Path value is not a valid X.509 certificate, System.IO.FileInfo object, or path to a valid X.509 certificate.'
			$ErrorRecord = New-ErrorRecord InvalidOperationException PathValueInvalid InvalidArgument 'Install-HPOVUpdate' -Message $Exceptionmessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		Try
		{

			"[{0}] Installing appliance CA signed certificate" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			$_resp = Send-HPOVRequest -Uri $applianceCsr -Method PUT -BOdy $_CertificateObject -HostName $ApplianceConnection

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		if ($PSBoundParameters['Async'])
		{

			$_resp

		}

		else
		{

			$_resp | Wait-HPOVTaskComplete

		}

	}

	End 
	{

		'[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
