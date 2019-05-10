function Get-InterconnectBayObject
{

	[CmdletBinding ()]
	Param 
	(

		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.Collections.DictionaryEntry]$InterconnectBay,
		
		[Parameter (Mandatory)]
		[ValidateNotNullOrEmpty()]
		[Object]$ApplianceConnection

	)

	Process
	{

		switch ($InterconnectBay.Value) 
		{

			'SEVC40f8'
			{            

				$_PartNumber = '794502-B23'
				
			}

			'SEVC16GbFC'
			{

				$_PartNumber = '779227-B21'

			}

			'SE20ILM'
			{

				$_PartNumber = '779218-B21'

			}

			'SE10ILM'
			{

				$_PartNumber = '779215-B21'

			}

			'SE12SAS'
			{

				Try
				{

					$_interconnectObject = Get-HPOVSasInterconnectType -partNumber "755985-B21" -Appliance $ApplianceConnection

				}
				
				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}

			}

			default 
			{

				# Should we throw an exception here?
				# $ExceptionMessage = "The specified Interconnect Bay type was not"
				# $ErrorRecord = New-ErrorRecord HPOneView.SnmpTrapDestination InvalidTrapSeverity InvalidArgument 'InterconnectBay' -Message ("The provided SNMP Trap Severity {0} is unsupported.  Please check the value, making sure it is one of these values: {1}." -f $_severity, ([System.String]::Join(", ", $SnmpTrapSeverityEnums)))

				# $PSCmdlet.ThrowTerminatingError($ErrorRecord)  
				$_interconnectObject = $null

			}
					
		}

		Try
		{

			'[{0}] Looking for {1} (P/N: {2})' -f $MyInvocation.InvocationName.ToString().ToUpper(), $InterconnectBay.Value, $_Partnumber | Write-Verbose

			if ($Null -ne $_PartNumber)
			{

				$_interconnectObject = Get-HPOVInterconnectType -partNumber $_PartNumber -Appliance $ApplianceConnection

			}
			
		}

		Catch
		{

			$PSCmdlet.ThrowTerminatingError($_)

		}

	}

	End
	{

		Return $_interconnectObject

	}

}
