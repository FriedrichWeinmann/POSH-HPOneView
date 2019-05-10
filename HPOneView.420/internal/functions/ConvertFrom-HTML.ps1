function ConvertFrom-HTML 
{

	[CmdletBinding ()]
	Param
	(

		[Parameter (ValueFromPipeline, Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.String] $html,

		[switch]$NoClobber
		
	)

	Begin { }

	Process 
	{
		
		# remove line breaks, replace with spaces
		if (-not ($NoClobber.ispresent)) { $html = $html -replace "(`r|`n|`t)", " " }
		
		# remove invisible content
		@('head', 'style', 'script', 'object', 'embed', 'applet', 'noframes', 'noscript', 'noembed') | ForEach-Object {$html = $html -replace "<$_[^>]*?>.*?</$_>", "" }
		
		# Condense extra whitespace
		$html = $html -replace "( )+", " "
		
		# Add line breaks
		@('div','p','blockquote','h[1-9]') | ForEach-Object { $html = $html -replace "</?$_[^>]*?>.*?</$_>", ("`n" + '$0' )} 

		# Add line breaks for self-closing tags
		@('div','p','blockquote','h[1-9]','br') | ForEach-Object { $html = $html -replace "<$_[^>]*?/>", ('$0' + "`n")} 
		
		# Strip tags 
		$html = $html -replace "<[^>]*?>", ""
		 
		# replace common entities
		@(
			@("&amp;bull;", " * "),
			@("&amp;lsaquo;", "<"),
			@("&amp;rsaquo;", ">"),
			@("&amp;(rsquo|lsquo);", "'"),
			@("&amp;(quot|ldquo|rdquo);", '"'),
			@("&amp;trade;", "(tm)"),
			@("&amp;frasl;", "/"),
			@("&amp;(quot|#34|#034|#x22);", '"'),
			@('&amp;(amp|#38|#038|#x26);', "&amp;"),
			@("&amp;(lt|#60|#060|#x3c);", "<"),
			@("&amp;(gt|#62|#062|#x3e);", ">"),
			@('&amp;(copy|#169);', "(c)"),
			@("&amp;(reg|#174);", "(r)"),
			@("&amp;nbsp;", " "),
			@("&amp;(.{2,6});", ""),
			@("&nbsp;", " ")
		) | ForEach-Object { $html = $html -replace $_[0], $_[1] }

	}

	End 
	{
	
		return $html

	}

}
