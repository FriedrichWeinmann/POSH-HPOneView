function Get-HPOVSanZone
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName='Default')]

	Param 
	(

		[Parameter (Mandatory = $false, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Object]$ManagedSan,

		[Parameter (Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Default')]
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

		$_FCZoneCollection = New-Object System.Collections.ArrayList

	}

	Process
	{

		if ($PSBoundParameters['ManagedSan'])
		{

			Switch ($ManagedSan.GetType().Name)
			{

				'PSCustomObject'
				{

					if ($ManagedSan.category -ne 'fc-sans')
					{

						$ExceptionMessage = "The ManagedSan resource '{0}' is not an allowed resource category." -f $ManagedSan.category
						$ErrorRecord = New-ErrorRecord HPOneView.ManagedSanResourceException InvalidManagedSanObject InvalidArgument 'ManagedSan' -Message $ExceptionMessage
						$PSCmdlet.ThrowTerminatingError($ErrorRecord)   

					}

					else
					{

						Try
						{

							$_resp = Send-HPOVRequest $ManagedSan.zonesUri -Hostname $ManagedSan.ApplianceConnection.Name

						}

						Catch
						{

							$PSCmdlet.ThrowTerminatingError($_)

						}

						ForEach ($_MemberZone in $_resp.members)
						{

							$_ZoneObject = NewObject -FCZone

							$_ZoneObject.PSObject.TypeNames.Insert(0,'HPOneView.Storage.ManagedSan.Zone')

							$_ZoneObject.Name                = $_MemberZone.name
							$_ZoneObject.State               = $_MemberZone.state
							$_ZoneObject.Status              = $_MemberZone.status
							$_ZoneObject.ManagedSan          = $_MemberZone.sanName
							$_ZoneObject.Created             = $_MemberZone.created
							$_ZoneObject.Modified            = $_MemberZone.modified
							$_ZoneObject.ApplianceConnection = $ManagedSan.ApplianceConnection

							Try
							{

								$_Aliases = Send-HPOVRequest $_MemberZone.AliasesUri -Hostname $ManagedSan.ApplianceConnection.Name

							}

							Catch
							{

								$PSCmdlet.ThrowTerminatingError($_)

							}

							ForEach ($_AliasMember in $_Aliases.members)
							{

								$_Alias = NewObject -FCAlias

								$_Alias.PSObject.TypeNames.Insert(0,'HPOneView.Storage.ManagedSan.Zone.Alias')

								$_Alias.Name = $_AliasMember.name
								$_Alias.WWN = $_AliasMember.members

								[void]$_ZoneObject.Members.Add($_Alias)

							}

							[void]$_FCZoneCollection.Add($_ZoneObject)

						}

					}

				}
				
				default
				{

					$ExceptionMessage = "The ManagedSan resource data type '{0}' is not an PSCustomObject." -f $ManagedSan.GetType().FullName
					$ErrorRecord = New-ErrorRecord HPOneView.ManagedSanResourceException InvalidManagedSanValue InvalidArgument 'ManagedSan' -Message $ExceptionMessage
					$PSCmdlet.ThrowTerminatingError($ErrorRecord)   

				}

			}			

		}

		else
		{

			ForEach ($_appliance in $ApplianceConnection)
			{

				Try
				{

					$_resp = Send-HPOVRequest $FcZonesUri -Hostname $_appliance

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

				ForEach ($_MemberZone in $_resp.members)
				{

					$_ZoneObject = NewObject -FCZone

					$_ZoneObject.PSObject.TypeNames.Insert(0,'HPOneView.Storage.ManagedSan.Zone')

					$_ZoneObject.Name                = $_MemberZone.name
					$_ZoneObject.State               = $_MemberZone.state
					$_ZoneObject.Status              = $_MemberZone.status
					$_ZoneObject.ManagedSan          = $_MemberZone.sanName
					$_ZoneObject.Created             = $_MemberZone.created
					$_ZoneObject.Modified            = $_MemberZone.modified
					$_ZoneObject.ApplianceConnection = [PSCustomObject]@{Name = $_appliance.Name; ID = $_appliance.ID}

					Try
					{

						$_Aliases = Send-HPOVRequest $_MemberZone.AliasesUri -Hostname $_appliance

					}

					Catch
					{

						$PSCmdlet.ThrowTerminatingError($_)

					}

					ForEach ($_AliasMember in $_Aliases.members)
					{

						$_Alias = NewObject -FCAlias

						$_Alias.PSObject.TypeNames.Insert(0,'HPOneView.Storage.ManagedSan.Zone.Alias')

						$_Alias.Name = $_AliasMember.name
						$_Alias.WWN = $_AliasMember.members

						[void]$_ZoneObject.Members.Add($_Alias)

					}

					[void]$_FCZoneCollection.Add($_ZoneObject)

				}

			}

		}

	}

	End
	{

		Return $_FCZoneCollection

	}

}
