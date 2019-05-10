function Join-Scope
{

	[CmdletBinding ()]
	Param
	(

		[Parameter (Mandatory, Position = 0)]
		[Object]$Scope

	)

	Begin
	{

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Debug

	}

	Process
	{

		$_ScopeQueryStringBuilder = New-Object "System.Collections.Generic.List``1[[System.String]]"

		ForEach ($_scope in $Scope)
		{

			if ($_scope -isnot [HPOneView.Appliance.ScopeCollection] -and $_scope -isnot [HPOneView.Appliance.ConnectionPermission])
			{

				"[{0}] Scope {1} is not a valid HPOneView.Appliance.ScopeCollection resource." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_scope | Write-Verbose

				$ExceptionMessage = "Scope {0} is not a valid HPOneView.Appliance.ScopeCollection resource." -f $_scope
				$ErrorRecord = New-ErrorRecord HPOneView.Appliance.ScopeResourceException ScopeResourceNotFound ObjectNotFound -TargetObject 'Name' -Message $ExceptionMessage
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)

			}

			elseif ($_scope -is [HPOneView.Appliance.ScopeCollection])
			{

				$_ScopeName = $_scope.Name

			}

			else
			{

				$_ScopeName = $_scope.ScopeName

			}

			if (-not ($_ScopeQueryStringBuilder | Where-Object { $_ -match $_ScopeName }) -and $_ScopeName -ne 'AllResources')
			{

				"[{0}] Adding Scope {1} to collection." -f $MyInvocation.InvocationName.ToString().ToUpper(), $_ScopeName | Write-Verbose

				[void]$_ScopeQueryStringBuilder.add(("scope:'{0}'" -f $_ScopeName))

			}		

		}

		Return [String]::Join(' OR ', $_ScopeQueryStringBuilder.ToArray())

	}	

}
