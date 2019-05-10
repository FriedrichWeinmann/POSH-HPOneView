function New-HPOVCustomBaseline
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullorEmpty()]
		[Object]$SourceBaseline,

		[Parameter (Mandatory)]
		[Array]$Hotfixes,

		[Parameter (Mandatory)]
		[String]$BaselineName,

		[Parameter (Mandatory = $false)]
		[Switch]$Async,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.ScopeCollection]$Scope,

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

		if (-not($PSBoundParameters['SourceBaseline']))
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

		$TaskCollection = New-Object System.Collections.ArrayList

	}

	Process 
	{
		
		$_CustomBaseline = NewObject -CustomBaseline

		# Validate Source Baseline
		switch ($SourceBaseline.GetType().Name)
		{

			'PSCustomObject'
			{
				
				if ($SourceBaseline.category -ne 'firmware-drivers')
				{

					$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException InvalidBaselineResource InvalidArgument 'SourceBaseline' -TargetType 'PSObject' -Message "The provided SourceBaseline object is not the required category, 'firmware-drivers'. Please correct the input Parameter."
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}
				
				"[{0}] Baseline Object Provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] Baseline Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $SourceBaseline.shortName | Write-Verbose
				"[{0}] Baseline URI: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $SourceBaseline.uri | Write-Verbose

			}

			'String'
			{

				"[{0}] Baseline Name Provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),$SourceBaseline | Write-Verbose

				# Get Source Baseline from Baseline Name
				Try
				{

					$BaselineParamName = $SourceBaseline.Clone()
					$SourceBaseline = Get-HPOVBaseline -SppName $SourceBaseline -ApplianceConnection $ApplianceConnection -ErrorAction SilentlyContinue

					If (-not $SourceBaseline)
					{

						$ExceptionMessage = "The provided SourceBaseline '{0}' was not found." -f $BaselineParamName
						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'SourceBaseline' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
			}

		}
		
		# Loop through Hotfixes
		ForEach ($_HotFix in $Hotfixes)
		{

			switch ($_HotFix.GetType().Name)
			{

				'PSCustomObject'
				{
					
					if ($_HotFix.category -ne 'firmware-drivers' -and $_HotFix.bundleType -ne 'Hotfix')
					{

						$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException InvalidBaselineResource InvalidArgument 'Hotfixes' -TargetType 'PSObject' -Message "The provided Hotfix object is not the required category and type.  Only 'firmware-drivers' category and 'Hotfix' type are allowed. Please correct the input Parameter."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}
					
					"[{0}] Hotfix baseline object provided" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
					"[{0}] Hotfix baseline Name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(),$_HotFix.shortName | Write-Verbose
					"[{0}] Hotfix baseline URI: {1}" -f $MyInvocation.InvocationName.ToString(),$_HotFix.uri | Write-Verbose

				}

				'String'
				{

					"[{0}] Hotfix Name Provided: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_HotFix | Write-Verbose

					# Get Source Baseline from Baseline Name
					Try
					{

						$_HotFixName = $_HotFix.Clone()
						$_HotFix = Get-HPOVBaseline  -File $_HotFix -ApplianceConnection $ApplianceConnection -ErrorAction SilentlyContinue

						If (-not $_HotFix)
						{

							$ExceptionMessage = "The provided Hotfix '{0}' was not found." -f $_HotFixName
							$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceNotFound ObjectNotFound 'Hotfixes' -Message $ExceptionMessage
							$PSCmdlet.ThrowTerminatingError($ErrorRecord)

						}

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}
					
				}

			}

			[void]$_CustomBaseline.hotfixUris.Add($_HotFix.uri)

		}

		$_CustomBaseline.baselineUri        = $SourceBaseline.uri
		$_CustomBaseline.customBaselineName = $BaselineName

		$_Params = @{
			URI      = $fwUploadUri;
			Method   = 'POST';
			Body     = $_CustomBaseline;
			Hostname = $ApplianceConnection.Name
		}

		if ($PSBoundParameters['Scope'])
		{

			$_sb = New-Object System.Collections.Arraylist

			ForEach ($_Scope in $Scope)
			{

				"[{0}] Adding to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

				[void]$_sb.Add($_Scope.Uri)

			}

			$_ScopeHttpHeader = @{'initialScopeUris' = [String]::Join(', ', $_sb.ToArray())}

			$_Params.Add('AddHeader', $_ScopeHttpHeader)

		}
		
		# Post the new object to the appliance
		Try
		{

			$_Resp = Send-HPOVRequest -Uri $ApplianceFwDriversUri -Method POST -Body $_CustomBaseline -Hostname $ApplianceConnection.Name

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
