function Add-HPOVBaseline 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateScript({Test-Path $_})]
		[Alias ('sppFile')]
		[Object]$File,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[HPOneView.Appliance.ScopeCollection]$Scope,

		[Parameter (Mandatory = $false)]
		[switch]$Async,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)

	Begin 
	{
		
		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if (-not($PSBoundParameters['File']))
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
		
		if (-not(Test-Path $File -PathType Leaf))
		{

			$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineFileNotFound ObjectNotFound 'File' -Message ("The baseline file '{0}' was not found.  Please check the path and filename." -f $File.Name)
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)				

		}

		if ($File -isnot [System.IO.FileInfo])
		{ 
			
			$File = Get-ChildItem -Path $File
			
		}

		if ($File.Length -le 0)
		{
		
			$ExceptionMessage = ("The File resource '{0}' file size is 0." -f $File.Name)
			$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException ResourceCannotBeZero InvalidArgument 'File' -TargetType 'System.IO.FileInfo' -Message $ExceptionMessage
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)

		}

		ForEach ($_appliance in $ApplianceConnection)
		{

			$_BaselineExists = $null

			"[{0}] Processing Appliance $($_appliance.Name)" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			# Check if the Baseline exists already, instead of waiting for filetransfer to finish
			"[{0}] Checking if Baseline exists" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

			Try
			{

				$_BaselineExists = Get-HPOVBaseline -FileName ($File.BaseName.Replace('.','_') + $File.Extension) -ApplianceConnection $_appliance -ErrorAction SilentlyContinue

			}

			Catch
			{

			  $PSCmdlet.ThrowTerminatingError($_)

			}

			if (-not $_BaselineExists)
			{

				# Start upload file
				Try
				{

					$_Params = @{
						URI                 = $fwUploadUri;
						File                = $File.FullName;
						ApplianceConnection = $_appliance
					}

					if ($PSBoundParameters['Scope'])
					{

						$_sb = New-Object System.Collections.Arraylist

						ForEach ($_Scope in $Scope)
						{

							"[{0}] Adding resource to Scope: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $_Scope.Name | Write-Verbose

							[void]$_sb.Add($_Scope.Uri)

						}

                        $_ScopeHttpHeader = @{'initialScopeUris' = [String]::Join(', ', $_sb.ToArray())}

						$_Params.Add('AddHeader', $_ScopeHttpHeader)

					}

					$task = Upload-File @_Params

					if (-not($PSBoundParameters['Async']))
					{

						"[{0}] Response is a task resource, calling Wait-HPOVTaskComplete" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$task = $task | Wait-HPOVTaskComplete

					}
				
					$Task

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			elseif ($_BaselineExists)
			{

				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.BaselineResourceException BaselineResourceAlreadyExists ResourceExists 'File' -Message ("The Baseline '{0}' is already present on the appliance.  Please upload a different baseline." -f $File.Name)
				$PSCmdlet.WriteError($ErrorRecord)

			}

		}

	}
	
	End 
	{
	
		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose
	
	}

}
