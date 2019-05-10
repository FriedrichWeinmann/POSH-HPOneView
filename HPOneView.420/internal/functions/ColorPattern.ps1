filter ColorPattern( [string]$Pattern, [hashtable]$Color) 
{

	$split = $_ -split $Pattern

	$found = [regex]::Matches( $_, $Pattern, 'IgnoreCase' )

	for( $i = 0; $i -lt $split.Count; ++$i ) 
	{

		[ConsoleColor]$displayColor = $Color.keys | ForEach-Object { if ($_ -ieq $found[$i]) { $color[$_]} }
		Write-Host $split[$i] -NoNewline
		Write-Host $found[$i] -NoNewline -ForegroundColor $displayColor

	}

	[console]::WriteLine()

}
