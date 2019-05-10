function Remove-ApplianceConnection
{
	
	[CmdletBinding ()]
	[Alias ('rac')]
	Param 
	(

		[Parameter (Mandatory = $false, ValueFromPipeline, Position = 0)]
		#[ValidateNotNullorEmpty()]
		[Object]$InputObject
	
	)

	Begin
	{

		# Write-Verbose "InputObject: $($InputObject | Out-String)"

	}

	Process
	{

		if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string] -and $InputObject -isnot [Hashtable])
		{

			Write-Verbose 'InputObject is IEnumerable'

			$Collection = New-Object System.Collections.ArrayList

			foreach ($object in $InputObject) 
			{ 

				$_UpdatedObject = Remove-ApplianceConnection $object
				
				[void]$Collection.Add($_UpdatedObject)
				
			}

			Return ,$Collection

		}

		elseif ($InputObject.GetType().Name -eq 'PSCustomObject')
		{

			Write-Verbose 'InputObject is [PSCustomObject]. Copying...'

			$_ClonedObject = $InputObject.PSObject.Copy()

			foreach ($property in $InputObject.PSObject.Properties)
			{

				if ($InputObject.($property.Name) -is [System.Collections.IEnumerable] -and $InputObject.($property.Name) -isnot [string] -and $InputObject.($property.Name) -isnot [Hashtable])
				{

					Write-Verbose 'Property is IEnumerable'

					$_SubCollection = New-Object System.Collections.ArrayList

					foreach ($_subobject in $InputObject.($property.Name)) 
					{ 
					
						$_UpdatedObject = Remove-ApplianceConnection $_subobject
						
						[void]$_SubCollection.Add($_UpdatedObject)
						
					}

					$_ClonedObject.($property.Name) = $_SubCollection

				}

				else
				{

					if ($property.Name -eq 'ApplianceConnection')
					{
				
						Write-Verbose 'Found ApplianceConnection prop, removing'

						$_ClonedObject.PSObject.Properties.Remove($property.Name)

					}

					elseif ($InputObject.($property.Name) -is [PSCustomObject] -and $InputObject.($property.Name) -isnot [string])
					{

						"Nested [PSCustomObject] {0}, Processing..." -f $property.Name | Write-Verbose

						$_ClonedObject.($property.Name) = Remove-ApplianceConnection $InputObject.($property.Name)

					}

				}

			}

			Return $_ClonedObject

		}

		else
		{

			Return $InputObject
		
		}
	
	}

}
