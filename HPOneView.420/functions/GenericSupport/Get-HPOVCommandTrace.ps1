function Get-HPOVCommandTrace
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding ()]
	Param
	(

		[Parameter (Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias('Command')]
		[ScriptBlock]$ScriptBlock = {},

		[Parameter (Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$Location = (Get-Location).path

	)

	Begin 
	{

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Caller: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

		if ($Caller -eq 'Get-HPOVCommandTrace')
		{

			Throw "You cannot use the Cmdlet to trace itself.  Please specify a different HPE OneView PowerShell Cmdlet."

		}

		$_TranscriptFile = $Location + '\' + (get-date -uformat %y%m%d%H%M) + '_HPOV_transcript.log'

		if ($host.name -match 'ISE' -and $PSVersionTable.PSVersion -lt '5.0')
		{

			Start-IseTranscript $_TranscriptFile | Out-Null

		}

		else
		{

			Try
			{
	
				'[{0}] Starting Transcript logging.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

				'[{0}] Generating new trace file: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $_TranscriptFile | Write-Verbose
				
				Start-Transcript $_TranscriptFile | Out-Null
	
			}
	
			catch
			{
	
				$PSCmdlet.ThrowTerminatingError($_)
	
			}

		}
		
		($PSLibraryVersion | Out-String) | Write-Verbose -Verbose:$true

		# Enable .Net Class Library tracing
		[HPOneView.Config]::EnableVerbose = $true
		[HPOneView.Config]::EnableDebug = $true

	}

	Process
	{

		$sb = New-Object System.Text.StringBuilder
		[void]$sb.Append("`$VerbosePreference = 'Continue'`n")
		[void]$sb.Append($ScriptBlock.ToString())

		'[{0}] ScritpBlock to execute: {1}' -f $MyInvocation.InvocationName.ToString().ToUpper(), $sb.ToString() | Write-Verbose

		Invoke-Command -ScriptBlock ([Scriptblock]::Create($sb.ToString())) -ErrorVariable CapturedError | Out-Null

		if ($null -ne $CaptureError)
		{

			$CapturedError | Write-Host

		}

		([String]::Join('',(1..80 | ForEach-Object { "-" }))) | Write-Verbose -Verbose:$true

	}

	End
	{

		[HPOneView.Config]::EnableVerbose = $false
		[HPOneView.Config]::EnableDebug = $false

		Stop-Transcript | Out-Null

		'[{0}] Stopped transcript logging.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		[System.IO.FileInfo]$_TranscriptFile

	}

}
