function Wait-Reboot ([int]$Time = 600)
{

	$_Time = $Time

	foreach ($i in (1..$_Time)) 
	{

		$_Percentage = $i / $_Time
		
		$_Remaining = New-TimeSpan -Seconds ($_Time - $i)

		$_Message = "Remaining time {0}" -f $_Remaining

		Write-Progress -Activity $_Message -PercentComplete ($_Percentage * 100)
		
		Start-Sleep 1

	}

	Write-Progress -Activity $_Message -Completed

}
