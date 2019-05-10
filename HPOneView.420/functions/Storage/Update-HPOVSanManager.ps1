function Update-HPOVSanManager 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Name','SANManager')]
		[Object]$InputObject,
		
		[Parameter (ValueFromPipelineByPropertyName, Mandatory = $false)]
		[ValidateNotNullorEmpty()]
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

		"[{0}] Verify auth" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		if (-not($ApplianceConnection -is [HPOneView.Appliance.Connection]) -and (-not($ApplianceConnection -is [System.String])) -and (-not($PipelineInput)))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException InvalidApplianceConnectionDataType InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter is not type [HPOneView.Appliance.Connection] or [System.String].  Please correct this value and try again.'
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif (($ApplianceConnection | Measure-Object).Count -gt 1 -and (-not($PipelineInput)))
		{

			$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException MultipleApplianceConnections InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter contains multiple Appliance Connections.  This CMDLET only supports 1 Appliance Connection in the ApplianceConnect Parameter value.  Please correct this and try again.'
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		elseif (-not($PipelineInput))
		{

			Try 
			{
	
				$ApplianceConnection = Test-HPOVAuth $ApplianceConnection

			}

			Catch [HPOneview.Appliance.AuthSessionException] 
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException NoApplianceConnections AuthenticationError 'ApplianceConnection' -TargetType $ApplianceConnection.GetType().Name -Message $_.Exception.Message -InnerException $_.Exception
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			Catch 
			{

				$PSCmdlet.ThrowTerminatingError($_.Exception)

			}

		}

		$_SanManagerRefreshCollection = New-Object System.Collections.ArrayList
	
	}

	Process 
	{

		$request = [PsCustomObject]@{refreshState = "RefreshPending"}

		# Validate input object type
		# Checking if the input is System.String and is NOT a URI
		if ($InputObject -is [string]) 
		{
			
			"[{0}] SANManager Name: $($SANManager)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$SANManager = Get-HPOVSanManager $SANManager -Hostname $ApplianceConnection

			}
			
			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

		}

		# Checking if the input is PSCustomObject, and the category type is server-profiles, which could be passed via pipeline input
		elseif (($InputObject -is [System.Management.Automation.PSCustomObject]) -and ($InputObject.category -ieq "fc-device-managers")) 
		{

			"[$($MyInvocation.InvocationName.ToString().ToUpper())] SANManager is an object: {0}" -f $InputObject.name | Write-Verbose 
		
		}

		else 
		{

			$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType $InputObject.GetType().Name -Message "The Parameter 'InputObject' value is invalid.  Please validate the 'InputObject' Parameter value you passed and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		if ($InputObject.isInternal)
		{

			"[$($MyInvocation.InvocationName.ToString().ToUpper())] '{0}' SAN Manager is internal.  Skipping." -f $InputObject.name | Write-Verbose 

		}

		else
		{

			"[$($MyInvocation.InvocationName.ToString().ToUpper())] Refreshing SAN Manager resource: {0}" -f $InputObject.name | Write-Verbose 
		
			Try
			{

				$_resp = Send-HPOVRequest $InputObject.uri PUT $request -Hostname $ApplianceConnection.Name
		
			}
		
			Catch
			{
		
				$PSCmdlet.ThrowTerminatingError($_)
		
			}

			$_resp

		}

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
