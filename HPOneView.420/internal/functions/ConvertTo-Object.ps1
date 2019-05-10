function ConvertTo-Object
{
		
	[CmdletBinding ()]
	Param 
	(

		 [Parameter (Mandatory)]
		 [ValidateNotNullOrEmpty()]
		 [System.Collections.ArrayList]$Objects

	)

	Begin
	{

		$NewObjects = New-Object System.Collections.ArrayList

	}

	Process
	{
		
		# Write-Verbose "Objects is '$($Objects.GetType().Fullname)' type."
		
		ForEach($_obj in $Objects)
		{

			# Write-Verbose "_obj is '$($_obj.GetType().Fullname)' type."

			# Write-Verbose "Processing: $($_obj.name)"

			switch ($_obj.category)
			{

				"ethernet-networks"
				{
				
					#[HPOneView.Networking.EthernetNetwork]$_newObj = $_obj

					$_obj.PSObject.TypeNames.Insert(0,'HPOneView.Networking.EthernetNetwork')
				
				}

				"fc-networks"
				{
				
					#[HPOneView.Networking.FibreChannelNetwork]$_newObj = $_obj
					$_obj.PSObject.TypeNames.Insert(0,'HPOneView.Networking.FibreChannelNetwork')
				
				}

				"fcoe-networks"
				{
				
					#[HPOneView.Networking.FCoENetwork]$_newObj = $_obj
					$_obj.PSObject.TypeNames.Insert(0,'HPOneView.Networking.FCoENetwork')

				}

				default
				{
				
					#$_newObj = $_obj

				}

			}


			# Write-Verbose "_newObj is '$($_newObj.GetType().Fullname)' type."

			#[void]$NewObjects.Add($_newObj)
			[void]$NewObjects.Add($_obj)

		}

	}

	End
	{

		Return $NewObjects

	}

}
