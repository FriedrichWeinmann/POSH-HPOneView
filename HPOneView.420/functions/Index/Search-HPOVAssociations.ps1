function Search-HPOVAssociations 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]$AssociationName,

		[Parameter (Mandatory = $false, ValueFromPipeline)]
		[ValidateNotNullorEmpty()]
		[object]$Parent,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[object]$Child,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[int]$Count = 50,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[int]$Start = 0,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)    

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($PSBoundParameters['Parent'])
		{

			if (-not($Parent -is [PSCustomObject]))
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Parent' -Message "The provided -Parent Parameter value is not an Object.  Please correct the value."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			$ApplianceConnection = $Parent.ApplianceConnection

		}

		elseif ($PSBoundParameters['Child'])
		{

			if (-not($Child -is [PSCustomObject]))
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Chuld' -Message "The provided -Child Parameter value is not an Object.  Please correct the value."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			$ApplianceConnection = $Child.ApplianceConnection

		}

		if ($PSBoundParameters['ApplianceConnection'])
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

		# Initialize collection to hold multiple volume attachments objects
		$_IndexSearchResults = New-Object System.Collections.ArrayList

	}

	Process 
	{

		$uri = $associationsUri + '?start=' + $start.ToString() + '&count=' + $count.ToString()

		if ($PSBoundParameters['AssociationName']) 
		{ 

			$uri = $uri + "&name=" + $associationName 
		
		}
		
		if ($Parent) 
		{

			"[$($MyInvocation.InvocationName.ToString().ToUpper())] Parent resource: {0}" -f ($Parent | Out-String) | Write-Verbose 

			if (-not($Parent -is [PSCustomObject]))
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Parent' -Message "The provided -Parent Parameter value is not an Object.  Please correct the value."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}
					
			$uri = $uri + "&parentUri=" + $Parent.uri
		
		}
		
		if ($PSBoundParameters['Child']) 
		{

			"[$($MyInvocation.InvocationName.ToString().ToUpper())] Child resource: {0}" -f ($Child | Out-String) | Write-Verbose 

			if (-not($Child -is [PSCustomObject]))
			{

				$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'Child' -Message "The provided -Child Parameter value is not an Object.  Please correct the value."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			$uri = $uri + "&childUri=" + $Child.uri
		
		}
		
		$uri = $uri.Replace(" ", "%20")

		Try
		{

			$r = Send-HPOVRequest $uri -Hostname $ApplianceConnection.Name

		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$r.members | ForEach-Object {

			[void]$_IndexSearchResults.Add($_)

		}

	}
	
	End
	{

		Return $_IndexSearchResults

	}

}
