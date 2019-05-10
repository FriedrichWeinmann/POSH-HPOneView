function Remove-HPOVResource 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml
	 
	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[Alias('Resource')]
		[ValidateNotNullorEmpty()]
		[Alias ("ro",'nameOruri','uri','name')]
		[object]$InputObject,

		[Parameter (Mandatory = $false)]
		[switch]$force,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
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

		$_RemoveResourceCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{
		 
		switch ($InputObject.GetType().Name) 
		{ 

			"PSCustomObject"  
			{ 
				
				"[{0}] Resource object passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] Name: $($InputObject.name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] URI: $($InputObject.uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] Type: $($InputObject.type)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				[void]$_RemoveResourceCollection.Add($InputObject)
				
			}
		 
			"String"
			{
				
				# NameOrUri value is a URI
				if ($InputObject.StartsWith("/rest"))
				{

					"[{0}] Resource URI passed '$($InputObject)', getting object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_resource = Send-HPOVRequest $InputObject -Hostname $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
					[void]$_RemoveResourceCollection.Add($_resource)

				}

				# It's a string value
				else 
				{
					
					"[{0}] Resource name provided: $($InputObject)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Querying appliance index for resource." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					# Use Index filtering to locate object
					Try
					{

						$_resources = Send-HPOVRequest ($indexUri + "?filter=name='$InputObject'") -Hostname $ApplianceConnection

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					"[{0}] Found $($_resources.count) resources." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					if($_resources.members)
					{

						# Error should only be displayed if a Name was provided, and it wasn't globally unique on the appliance (i.e. Server Profile and Ethernet Network with the same name, which is completely valid.)
						if($_resources.count -gt 1)
						{
							
							"[{0}] Resources found: $($_resources.members | % { $_.name + " of type " + $_.category })" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$ErrorRecord = New-ErrorRecord InvalidOperationException ResourceNotUnique LimitsExceeded 'InputObject' -Message "'$InputObject' is not unique.  Located $($_resources.count) resources with the same value."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

						else 
						{ 
						
							[void]$_RemoveResourceCollection.Add($_resources.members)

						}

					}

					else 
					{ 

						$ErrorRecord = New-ErrorRecord InvalidOperationException ResourceNotFound ObjectNotFound 'InputObject' -Message "Resource '$InputObject' not found. Please check the resource value provided and try the call again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

			}   
			  
		}

	}
	
	End
	{

		$n = 1

		ForEach ($_resource in $_RemoveResourceCollection)
		{

			"[{0}] Processing '$($_resource.name)', $n of $($_RemoveResourceCollection.Count)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ([bool]$force) 
			{ 
				
				$_resource.uri += "?force=true" 
			
			}

			Try
			{
								
				Send-HPOVRequest $_resource.uri DELETE

			}

			Catch
			{

				$PSCmdlet.ThrowTerminatingError($_)

			}

			$n++

		}

	}

}
