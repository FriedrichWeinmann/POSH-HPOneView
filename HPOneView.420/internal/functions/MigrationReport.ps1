function MigrationReport
{

	[CmdletBinding ()]
	Param
	(

		[Parameter (Mandatory)]
		[Object]$task

	)

	Process
	{

		$vcMigrationReport = NewObject -VCMigratorReport

		Try
		{

			$vcMigrationReport.apiVcMigrationReport = Send-HPOVRequest $task.associatedResource.resourceUri

		}
		
		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

		$vcMigrationReport.migrationState = $vcMigrationReport.apiVcMigrationReport.migrationState

		$vcMigrationReport.issueCount = $vcMigrationReport.apiVcMigrationReport.highCount + $vcMigrationReport.apiVcMigrationReport.mediumCount + $vcMigrationReport.apiVcMigrationReport.lowCount
		
		if ($vcMigrationReport.migrationState -eq "UnableToMigrate" -or $vcMigrationReport.issueCount -gt 0) 
		{
			
			foreach ($itemCategory in $vcMigrationReport.apiVcMigrationReport.items) 
			{
			
				foreach ($issue in $itemCategory.issues) 
				{
			
					$issue | ForEach-Object { 

						if ($_.description -match "The specified enclosure is managed by Virtual Connect Enterprise Manager") 
						{

							Write-Warning "Enclosure is currently managed by Virtual Connect Enterprise Manager."
								
							$vcMigrationReport.VcemManaged = $True
						
						}

						$_ | add-member -NotePropertyName name -NotePropertyValue $itemCategory.name -force 
						$_ | add-member -NotePropertyName resourceName -NotePropertyValue $_.name -force 
						
						[void]$vcMigrationReport.outReport.Add($_)
						
					}
			
				}
			
				foreach ($item in $itemCategory.items) 
				{ 
			
					$items = $item | Where-Object severity -notmatch "OK"

					$items | ForEach-Object { 
			
						$_.issues | add-member -NotePropertyName name -NotePropertyValue $itemCategory.name -force 
						$_.issues | add-member -NotePropertyName resourceName -NotePropertyValue $_.name -force 

						[void]$vcMigrationReport.outReport.Add($_.issues)
			
					}
				
				}
			
			}

		}

	}

	End
	{

		Return $vcMigrationReport

	}

}
