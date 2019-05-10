function Get-HPOVDriveEnclosure
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName='Default')]

	Param 
	(

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[String]$Name,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
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

		$_DriveEnclosureCollection = New-Object System.Collections.ArrayList
			
	}

	Process 
	{

		ForEach ($_appliance in $ApplianceConnection)
		{

			if ($_appliance.ApplianceType -ne 'Composer')
			{

				$ErrorRecord = New-ErrorRecord HPOneview.Appliance.ComposerNodeException InvalidOperation InvalidOperation 'ApplianceConnection' -Message ('The ApplianceConnection {0} is not a Synergy Composer.  This Cmdlet is only supported with Synergy Composers.' -f $_appliance.Name)
				$PSCmdlet.WriteError($ErrorRecord)

			}

			else
			{

				if ($PSBoundParameters['Label'])
				{

					$_uri = '{0}?category:drive-enclosures&query=labels:{1}' -f $IndexUri, $Label

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

							$_member.PSObject.TypeNames.Insert(0,"HPOneView.Storage.DriveEnclosure")

							$_member.driveBays | ForEach-Object { 
								
								$_.PSObject.TypeNames.Insert(0,"HPOneView.Storage.DriveEnclosure.DriveBay") 

								if ($_.drive)
								{

									$_.drive.PSObject.TypeNames.Insert(0,'HPOneView.Storage.DriveEnclosure.DriveBay.Drive')

								}
								
							}

							$_member.ioAdapters | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.Storage.DriveEnclosure.IoAdapter") }

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

					$uri = $DriveEnclosureUri

					if ($PSBoundParameters['Name'])
					{

						$_operator = '='

						if ($Name -match '\*' -or $Name -match '\?')
						{

							$_operator = 'matches'

						}

						$uri += "?filter=name {0} '{1}'&sort:asc" -f $_operator, $name.Replace('*','%25')

					}

					Write-Verbose ("[$($MyInvocation.InvocationName.ToString().ToUpper())] Processing {0} Connection" -f $_appliance.Name)

					"[{0}] Sending request"  -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

					Try
					{

						$_DriveEnclosures = Send-HPOVRequest -uri $uri -Hostname $_appliance.Name

					}
					
					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					if ($_DriveEnclosures.count -eq 0 -and (-not ($Name))) 
					{  
						
						"[{0}] No unmanaged devices found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose 
					
					}

					elseif ($_DriveEnclosures.count -eq 0 -and $PSBoundParameters['Name']) 
					{ 

						"[{0}] No drive enclosure reousrces with name found." -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

						$ExceptionMessage = "The '{0}' Drive Enclosure resource was not found on '{1}' Appliance. Please check the name and try again." -f $Name, $_appliance.Name
						$ErrorRecord = New-ErrorRecord HPOneview.UnmanagedDeviceResourceException UnmangedDeviceResouceNotFound ObjectNotFound 'Name' -Message $ExceptionMessage
						$PSCmdlet.WriteError($ErrorRecord)
							
					}
					
					else
					{

						$_DriveEnclosures.members | ForEach-Object {

							$_.PSObject.TypeNames.Insert(0,"HPOneView.Storage.DriveEnclosure")

							$_.driveBays | ForEach-Object { 
								
								$_.PSObject.TypeNames.Insert(0,"HPOneView.Storage.DriveEnclosure.DriveBay") 

								if ($_.drive)
								{

									$_.drive.PSObject.TypeNames.Insert(0,'HPOneView.Storage.DriveEnclosure.DriveBay.Drive')

								}
								
							}

							$_.ioAdapters | ForEach-Object { $_.PSObject.TypeNames.Insert(0,"HPOneView.Storage.DriveEnclosure.IoAdapter") }

							$_

						}

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
