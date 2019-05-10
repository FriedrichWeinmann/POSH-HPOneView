function Disable-HPOVMSDSC 
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]

	Param ()

	Begin { }

	Process 
	{

		$RegKey = "HKCU:\Software\Hewlett-Packard\HPOneView"

		if (-not(Test-Path $RegKey)) { New-Item -Path $RegKey -force | Write-Verbose }

		$UseMSDSC = [bool](Get-ItemProperty -LiteralPath $RegKey -ea silentlycontinue).'UseMSDSC'

		if (-not($UseMSDSC)) { New-ItemProperty -Path $RegKey -Name UseMSDSC -Value 0 -Type DWORD | Write-Verbose }

		else { Set-ItemProperty -Path $RegKey -Name UseMSDSC -Value 0 -Type DWORD | Write-Verbose }

	}

	End { }

}
