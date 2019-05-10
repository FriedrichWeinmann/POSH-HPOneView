function Get-HPOVUnmanagedDevice 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName='Default')]

	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[Alias ('report')]
		[Switch]$List,

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Label,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | Where-Object Default)

	)
	
	Begin 
	{

		if ($PSBoundParameters['List'])
		{

			Write-Warning "The List Parameter has been deprecated.  The CMDLET will now display object data in Format-List view."

		}

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

		$_UnmanagedDevicesCollection = New-Object System.Collections.ArrayList

		$uri = $UnmanagedDevicesUri

		if ($PSBoundParameters['Name'])
		{

			if ($Name.Contains('*'))
			{

				$uri += "&filter=name matches '{0}'" -f $Name.Replace('*','%25')

			}

			else
			{

				$uri += "&filter=name EQ '{0}'" -f $Name

			}

		}

	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			if ($PSBoundParameters['Label'])
			{

				$_uri = '{0}?category:unmanaged-devices&query=labels:{1}' -f $IndexUri, $Label

				Try
				{

					$_IndexMembers = Send-HPOVRequest -Uri $_uri -Hostname $_appliance

					# Loop through all found members and get full SVT object
					ForEach ($_member in $_IndexMembers.members)
					{

						Try
						{

							$_member = Send-HPOVRequest -Uri $_member.uri -Hostname $_appliance

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}						

						$_member.PSObject.TypeNames.Insert(0,'HPOneView.UnmanagedResource')

						$_member

					}

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			else
			{

				"[{0}] Sending request"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				Try
				{

					$_UnmanagedDevices = Send-HPOVRequest $uri -Hostname $_appliance.Name

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				if ($_UnmanagedDevices.count -eq 0 -and (-not($Name))) 
				{  
					
					"[{0}] No unmanaged devices found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
				
				}

				elseif ($_UnmanagedDevices.count -eq 0 -and $Name)
				{


					"[{0}] No unmanaged devices with name found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					$ExceptionMessage = "The '{0}' Unmanaged Device resource was not found on '{1}' Appliance. Please check the name and try again." -f $Name, $_appliance.Name
					$ErrorRecord = New-ErrorRecord HPOneview.UnmanagedDeviceResourceException UnmangedDeviceResouceNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
					$PSCmdlet.WriteError($ErrorRecord)

				}

				else
				{

					$_UnmanagedDevices.members | ForEach-Object {

						$_.PSObject.TypeNames.Insert(0,"HPOneView.UnmanagedResource")

						$_

					}

				}

			}
			
		}			

	}

	End 
	{

		"[{0}] Done." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

	}

}
