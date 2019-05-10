filter Convert-IP2Decimal
{

	([Net.IPAddress][String]([Net.IPAddress]$_)).Address
	
}
