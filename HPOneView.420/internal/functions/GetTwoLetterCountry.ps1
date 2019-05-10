function GetTwoLetterCountry
{

	<#
		.DESCRIPTION
		Helper function to get ISO3166-2 Compliant Country Name
					
		.Parameter Country
		Helper function to get ISO3166-2 Compliant Country Name

		.INPUTS
		None.  You cannot pipe objects to this cmdlet.
					
		.OUTPUTS
		System.String
		ISO3166-2 Compliant two character country name
		
		.EXAMPLE
		PS C:\> GetTwoLetterCountry 'United States'
		US

		Returns the ISO3166-2 Compliant 2-character Country name.
				
	#>

	[CmdletBinding (DefaultParameterSetName = 'Default')]

	Param 
	(

		[Parameter (Mandatory, ParameterSetName = 'Default')]
		[ValidateNotNullOrEmpty()]
		[String]$Name

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

	}

	Process
	{

		Write-Verbose 'Building Country collection.'

		$CountriesCollection = New-Object Hashtable

		$Countries = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]'AllCultures')

		foreach ($ObjCultureInfo in [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]'AllCultures'))
		{

			Try
			{

				[System.Globalization.RegionInfo]$_Country = $ObjCultureInfo.LCID

				if ($_Country.EnglishName -match ' AND ')
				{

					$_CountriesSplit = $_Country.EnglishName.Split(' AND ')

					ForEach ($_split in $_CountriesSplit)
					{

						if (-not($CountriesCollection.ContainsKey($_split)))
						{
				
							$CountriesCollection.Add($_split, $_Country.TwoLetterISORegionName.ToUpper());

						}

					}

				}

				else
				{

					if (-not($CountriesCollection.ContainsKey($_Country.EnglishName)))
					{


						$CountriesCollection.Add($_Country.EnglishName, $_Country.TwoLetterISORegionName.ToUpper());

					}

				}

			}

			Catch
			{

				Write-Verbose ("{0} Doesn't have RegionInfo" -f $ObjCultureInfo)

			}

		}

	}

	End
	{

		Write-Verbose 'Returning value'

		Write-Verbose ('Country Collection: {0}' -f ($CountriesCollection | Out-String))

		Write-Verbose ('ISO3166-2 Country Name: {0}' -f $CountriesCollection[$Name])

		$_Return = $CountriesCollection[$Name]

		if (-not($_Return))
		{

			$ErrorRecord = New-ErrorRecord InvalidOperationException CountryNameNotFound ObjectNotFound 'Name' -Message ('{0} is not a valid Country Name, or unable to find mapping to RegionInfo ISO3166-2 compliant 2-Character name.' -f $Name )
			$PSCmdlet.ThrowTerminatingError($ErrorRecord)`

		}

		Return $_Return

	}

}
