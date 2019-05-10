function Get-HPOVServerHardwareType 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]
	Param
	(

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[string]$Model,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Alias ("x", "export")]
		[ValidateScript ({split-path $_ | Test-Path})]
		[String]$exportFile

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

		$_SHTCollection = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing Appliance Connection {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name | Write-Verbose

			$uri = '{0}?sort=name:asc' -f $ServerHardwareTypesUri

			if ($PSBoundParameters['Name'])
			{

				"[{0}] Server Hardware Type name provided: '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Name | Write-Verbose

				$uri = "{0}&filter=name matches '{1}'" -f $uri, $Name.Replace('*','%25')

			}

			if ($PSBoundParameters['Model'])
			{

				"[{0}] Server Hardware Type model provided: '{1}'" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Model | Write-Verbose

				$uri = "{0}&filter=model matches '{1}'" -f $uri, $model.Replace('*','%25')

			}

			Try
			{

				$_resp = Send-HPOVRequest $uri -hostname $_appliance

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			if ($PSBoundParameters['Name'] -and $_resp.count -eq 0)
			{

				$ExceptionMessage = "'{0}' Server Hardware Type not found on '{1}' appliance connection. Please check the name and try again." -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord InvalidOperationException ServerHardwareTypeNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			elseif ($PSBoundParameters['Model'] -and $_resp.count -eq 0)
			{

				$ExceptionMessage = "'{0}' Server Hardware Type model not found on '{1}' appliance connection. Please check the name and try again." -f $Model, $_appliance.Name
				$ErrorRecord = New-ErrorRecord InvalidOperationException ServerHardwareTypeNotFound ObjectNotFound 'Model' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				$_resp.members | ForEach-Object { 
					
					$_.PSObject.TypeNames.Insert(0,'HPOneView.ServerHardwareType')

					[void]$_SHTCollection.Add($_)
				
				}

			}

		}

	}

	End 
	{

		if ($PSboundParameters['ExportFile']) 
		{

			$_SHTCollection | ConvertTo-JSON -Depth 99 > $ExportFile

		}

		else
		{

			Return $_SHTCollection

		}

	}

}
