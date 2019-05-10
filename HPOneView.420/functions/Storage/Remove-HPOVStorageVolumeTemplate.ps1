function Remove-HPOVStorageVolumeTemplate 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = "default",SupportsShouldProcess,ConfirmImpact = 'High')]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('uri', 'name', 'templateName', 'Template')]
		[Object]$InputObject,
	
		[Parameter (Mandatory = $False, ValueFromPipelineByPropertyName, ParameterSetName = "default")]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default),

		[Parameter (Mandatory = $False, ParameterSetName = "default")]
		[switch]$Force
	
	)

	Begin 
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose
				
		if (-not($PSBoundParameters['Template'])) 
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

		$_TaskCollection = New-Object System.Collections.ArrayList
		$_SVTCollection  = New-Object System.Collections.ArrayList

	}

	Process 
	{

		if ($PipelineInput) 
		{

			"[{0}] Processing Pipeline input" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		}

		foreach ($_svt in $InputObject) 
		{

			# SVT passed is a URI
			if (($_svt -is [String]) -and [System.Uri]::IsWellFormedUriString($_svt,'Relative')) 
			{

				"[{0}] Received URI: $($_svt)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				"[{0}] Getting SVT object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				if (($ApplianceConnection | Measure-Object).Count -gt 1)
				{

					$ErrorRecord = New-ErrorRecord HPOneview.Appliance.AuthSessionException MultipleApplianceConnections InvalidArgument 'ApplianceConnection' -Message 'The specified ApplianceConnection Parameter contains multiple Appliance Connections.  This CMDLET only supports 1 Appliance Connection in the ApplianceConnect Parameter value when using a Storage Volume Template URI value.  Please correct this and try again.'
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)

				}

				Try
				{

					$_svtObject = Send-HPOVRequest $_svt -ApplianceConnection $ApplianceConnection

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				[void]$_SVTCollection.Add($_svtObject)

			}

			# SVT passed is the Name
			elseif (($_svt -is [string]) -and (-not $_svt.startsWith("/rest")))
			{

				"[{0}] Received SVT Name {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_svt | Write-Verbose

				"[{0}] Getting SVT object from Get-HPOVStorageVolumeTemplate" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				ForEach ($_appliance in $ApplianceConnection)
				{

					"[{0}] Processing '$_appliance' Appliance Connection [of $($ApplianceConnection.count)]" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_svtObject = Get-HPOVStorageVolumeTemplate $_svt -ApplianceConnection $ApplianceConnection -ErrorAction Stop

					}

					Catch
					{
						
						$PSCmdlet.ThrowTerminatingError($_)

					}

					$_svtObject | ForEach-Object {

						"[{0}] Adding '$($_.name)' SVT to collection." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						[void]$_SVTCollection.Add($_)

					}

				}

			}

			# SVT passed is the object
			elseif ($_svt -is [PSCustomObject]) 
			{

				"[{0}] SVT Object provided." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
				"[{0}] object name: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_svt.name | Write-Verbose
				"[{0}] object uri: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_svt.uri | Write-Verbose
				"[{0}] object appliance connection: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_svt.ApplianceConnection.Name | Write-Verbose
				"[{0}] object category: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_svt.category | Write-Verbose

				if ($_svt.category -ieq 'storage-volume-templates')
				{

					If (-not $_svt.ApplianceConnection)
					{

						$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument "Template:$($Template.Name)" -TargetType PSObject -Message "The Template resource provided is missing the source ApplianceConnection property.  Please check the object provided and try again."
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)

					}					

					[void]$_SVTCollection.Add($_svt)

				}

				else 
				{

					$ExceptionMessage = "The InputObject parameter value {0} is not a supported object type.  Only 'storage-volume-templates' resources are permitted." -f $_svt.Name
					$ErrorRecord = New-ErrorRecord InvalidOperationException InvalidArgumentValue InvalidArgument 'InputObject' -TargetType 'PSObject' -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)

				}				
			
			}

		}

	}

	End
	{

		"[{0}] Processing $($_SVTCollection.count) SVT resources to remove." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		# Process SVT Resources
		ForEach ($_svtObject in $_SVTCollection)
		{

			if ($PSCmdlet.ShouldProcess($_svtObject.name,"Remove SVT from appliance '$($_svtObject.ApplianceConnection.Name)'")) 
			{

				"[{0}] Removing SVT '$($_svtObject.name)' from appliance '$($_svtObject.ApplianceConnection.Name)'." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{
					
					if ($PSBoundParameters['Force'])
					{

						$_svtObject.uri += "?force=true"

					}

					$_resp = Send-HPOVRequest $_svtObject.Uri DELETE -Hostname $_svtObject.ApplianceConnection.Name

					[void]$_TaskCollection.Add($_resp)

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($PSBoundParameters['WhatIf'])
			{

				"[{0}] WhatIf Parameter was passed." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			}

		}

		Return $_TaskCollection

	}

}
