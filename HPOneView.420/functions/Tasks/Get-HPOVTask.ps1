function Get-HPOVTask 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "ResourceCategory")]
		[ValidateNotNullorEmpty()]
		[Alias ("TaskName")]
		[string]$Name,

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = "Default")]
		[Alias('Resource')]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = "ResourceCategory")]
		[ValidateNotNullorEmpty()]
		[Alias ("Category")]
		[String]$ResourceCategory,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "ResourceCategory")]
		[ValidateNotNullorEmpty()]
		[ValidateSet ("Unknown","New","Running","Pending","Stopping","Suspended","Terminated","Killed","Completed","Error","Warning")]
		[string]$State,

		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "ResourceCategory")]
		[ValidateScript({ if ([int]$_ -gt -1) {$true} else {Throw "The Count Parameter value '$_' is invalid."}})]
		[Int]$Count = 0,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "ResourceCategory")]
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

		$_TaskCollection = New-Object System.Collections.ArrayList

	}
	
	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			$uri = $TasksUri + '?sort=modified:desc'

			if ($PSBoundParameters['Name']) 
			{ 
		
				"[{0}] Name Parameter value: $($Name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$Uri += "&filter=name='$Name'" 
		
			}

			if ($PSBoundParameters['State']) 
			{ 
		
				"[{0}] State Parameter value: $($State)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$Uri += "&filter=taskState='$State'" 
							
			}

			if ($PSBoundParameters['Count']) 
			{

				"[{0}] Count Parameter value: $($Count)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					
				$Uri += "&count=$Count&sort=created:descEnding" 

			}


			"[{0}] Parameter Set Name resolved to: $($PSCmdlet.ParameterSetName)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			switch ($PSCmdlet.ParameterSetName) 
			{

				"Default" 
				{
					
					if ($PSBoundParameters['InputObject']) 
					{

						# If the Resource value is a Name
						if (($InputObject -is [string]) -and (-not($InputObject.StartsWith("/rest/"))))
						{

							"[{0}] Resource Parameter Name: $($InputObject)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$Uri += "&filter=associatedResource.resourceName='$InputObject'" 
							
						}

						# Checking if the input is System.String and IS a URI
						elseif (($InputObject -is [string]) -and ($InputObject.StartsWith("/rest/"))) 
						{
				
							"[{0}] Resource Parameter URI: $($InputObject)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
							$Uri += "&filter=associatedResource.resourceUri='$InputObject'" 
							
			
						}

						# Checking if the input is PSCustomObject, and the category type is not null, which would be passed via pipeline input
						elseif (($InputObject -is [PSCustomObject]) -and ($InputObject.category)) 
						{

							"[{0}] Resource is an object: '$($InputObject.name)' of type '$($InputObject.Category)'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							"[{0}] Using URI value ($($InputObject.Uri)) from input object." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

							$Uri += "&filter=associatedResource.resourceUri='$($InputObject.Uri)'" 
							
						}

						else 
						{
							 
							$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -Message "The Resource input Parameter was not recognized as a valid type or format."
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)
							
						}
						
					}

				} # End Default
				
				"ResourceCategory" 
				{ 
				
					"[{0}] Resource Category was specified:  $($ResourceCategory)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$Uri += "&filter=associatedResource.resourceCategory='$($ResourceCategory)'" 

				} # End ResourceCategory

			} # End switch

			"[{0}] URI: $($Uri)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			if ($Count -gt 0 ) 
			{ 
			
				"[{0}] Getting $($Count) task objects." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
		
			}

			else 
			{ 
			
				"[{0}] ($($Count)) Returning all available task objects." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
		
			}

			try 
			{
		
				$_tasks = Send-HPOVRequest $Uri -Hostname $_appliance

				if ($_tasks.count -eq 0) 
				{ 
				
					"[{0}] No tasks found on Appliance '$($_appliance.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					if ($Name)
					{

						$ExceptionMessage = "Task '{0}' name was not found on '{1}' appliance connection." -f $Name, $_appliance.Name
						$ErrorRecord = New-ErrorRecord InvalidOperationException ResourceNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
						$PSCmdlet.WriteError($ErrorRecord)

					}
					
				}

				else 
				{ 
				
					$_tasks.members | ForEach-Object { 
							
						$_.PSObject.TypeNames.Insert(0,"HPOneView.Appliance.TaskResource") 
						
						[void]$_TaskCollection.Add($_)
						
					}
 
				}

			}

			catch 
			{

				$PSCmdlet.ThrowTerminatingError($_)
			
			}

		}

	}    

	End
	{

		"[$($MyInvocation.InvocationName.ToString().ToUpper())] Done. {0} task resource(s) found." -f $_TaskCollection.count | Write-Verbose

		Return $_TaskCollection

	}

}
