Function Start-iseTranscript
{

	Param
	(

		[string]$logname = (Get-logNameFromDate -path "C:\fso" -postfix " $(hostname)" -Create)

	)

	$transcriptHeader = '**************************************
	Windows PowerShell ISE Transcript Start
	Start Time: {0}
	UserName: {1}
	UserDomain: {2}
	ComputerName: {3}
	Windows version: {4}
	**************************************
	Transcript started. Output file is {5}' -f [DateTime]::Now(), $env:username, $env:USERDNSDOMAIN, $env:COMPUTERNAME, (Get-CimObject win32_operatingsystem).version, $logname

	$transcriptHeader >> $logname

	$psISE.CurrentPowerShellTab.Output.Text >> $logname

	# Keep current Prompt
	if ($null -eq $__promptDef)
	{

		$__promptDef =  (Get-ChildItem Function:Prompt).Definition
		$promptDef = (Get-ChildItem Function:Prompt).Definition

	} 
	
	else
	{

		$promptDef = $__promptDef

	}

	$newPromptDef = '
	if ($global:_LastText -ne $psISE.CurrentPowerShellTab.Output.Text)
	{

		Compare-Object -ReferenceObject $global:_LastText.Split("`n") -DifferenceObject $psISE.CurrentPowerShellTab.Output.Text.Split("`n") | ? { $_.SideIndicator -eq "=>" } | % { $_.InputObject.TrimEnd() } | Out-File -FilePath ($Global:_DSTranscript) -Append
		$global:_LastText = $psISE.CurrentPowerShellTab.Output.Text

	}
	' + $promptDef

	New-Item -Path Function: -Name "Global:Prompt" -Value ([ScriptBlock]::Create($newPromptDef)) -Force | Out-Null
	
}
