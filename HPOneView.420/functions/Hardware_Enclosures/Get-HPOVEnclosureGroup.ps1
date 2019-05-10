function Get-HPOVEnclosureGroup 
{
	
	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]    
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]$Name,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $false)]
		[Alias ("x", "export")]
		[ValidateScript({split-path $_ | Test-Path})]
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

		$EGCollection = New-Object System.Collections.ArrayList
		
	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			"[{0}] Processing '{1}' Appliance (of {2})" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_appliance.Name, $ApplianceConnection.Count | Write-Verbose

			if ($PSboundParameters['name']) 
			{

				"[{0}] Enclosure Group name provided: '$name'" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
				$name = $name -replace ("[*]","%25") -replace ("[&]","%26")
	
				#$uri = $enclosureGroupsUri + "?filter=name='$name'"
				$uri = $enclosureGroupsUri + "?filter=name matches '$name'"
	
			}
	
			else 
			{
	
				"[{0}] No Enclosure Group name provided. Looking for all Enclosure Group resources." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
				$uri = $enclosureGroupsUri
	
			}
	
			Try
			{
	
				$enclGrps = Send-HPOVRequest $uri -Hostname $_appliance
	
			}
			
			Catch
			{
	
				"[{0}] API Error Caught: $($_.Exception.Message)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
				$PSCmdlet.ThrowTerminatingError($_)
	
			}
	
			if ($enclGrps.count -eq 0 -and $name) 
			{ 
	
				"[{0}] Enclosure Group '$name' resource not found. Generating error" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				$ExceptionMessage = "The specified Enclosure Group '{0}' was not found on '{1}'.  Please check the name and try again." -f $Name, $_appliance.Name
				$ErrorRecord = New-ErrorRecord InvalidOperationException EnclosureGroupNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
				$PSCmdlet.WriteError($ErrorRecord)  
				
			}
	
			elseif ($enclGrps.count -eq 0) 
			{ 
	
				"[{0}] No Enclosure Group resources found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
			}
	
			else 
			{
	
				"[{0}] Found $($enclGrps.count) Enclosure Group resources." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
				$enclGrps.members | ForEach-Object { 
					
					$_.PSObject.TypeNames.Insert(0,'HPOneView.EnclosureGroup')	
	
					[void]$EGCollection.Add($_) 
					
				}
	 
			}

		}

   
	}

	End 
	{

		"[{0}] Done. $($enclGrps.count) enclosure group(s) found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose     

		if ($exportFile)
		{ 
			
			$enclGrps.members | convertto-json -Depth 99 | Set-Content -Path $exportFile -force -encoding UTF8 
		
		}
				
		else 
		{
			
			Return $EGCollection
		
		}  

	}

}
