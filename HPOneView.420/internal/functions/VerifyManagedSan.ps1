function VerifyManagedSan 
{

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Object]$managedSan,

		[Parameter (Mandatory)]	
		[ValidateNotNullorEmpty()]	
		[object]$Appliance
	
	)
	
	Process 
	{

		if ($managedSan -eq "" -or $Null -eq $ManagedSan) 
		{
		   
			$managedSanUri = $Null

		}

		elseif ($managedSan -is [PSCustomObject] -and $managedSan.category -eq 'fc-sans') 
		{ 
					
			$managedSanUri = $managedSan.uri
						
		}

		elseif ($managedSan -is [PSCustomObject] -and -not ($managedSan.category -eq 'fc-sans')) 
		{ 
					
			$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidManagedSanUri InvalidArgument 'managedSan' -Message "The Managed SAN object category provided '$($managedSan.category)' is not the the expected value of 'fc-sans'. Please verify the Parameter value and try again."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)   
						
		}
				   
		elseif ($managedSan -is [String] -and $managedSan.StartsWith('/rest/')) 
		{ 
					
			$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidManagedSanUri InvalidArgument 'managedSan' -Message "The Managed SAN Uri provided '$managedSan' is incorrect.  Managed SAN URI must Begin with '/rest/fc-sans/managed-sans'."
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)                       
					
		}
					
		elseif ($managedSan -is [String] -and (-not($managedSan.StartsWith($script:fcManagedSansUri)))) 
		{

			# Get ManagedSan object
			Try { $managedSanUri = (Get-HPOVManagedSan $managedSan -appliance $Appliance).uri }

			# If specified ManagedSan object does not exist, generate trappable error
			catch 
			{
		
				$ErrorRecord = New-ErrorRecord HPOneView.NetworkResourceException InvalidManagedSanName InvalidArgument 'managedSan' -Message "The Managed SAN Name provided '$managedSan' was not found."
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)   

			}

		}

		else 
		{

			$managedSanUri = $managedSan

		}

		Return $managedSanUri

	}

}
