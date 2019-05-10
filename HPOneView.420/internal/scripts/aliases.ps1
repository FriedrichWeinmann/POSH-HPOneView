$aliases = @{
	'Add-HPOVSppFile'				  = 'Add-HPOVBaseline'
	'Copy-HPOVProfile'			      = 'Copy-HPOVServerProfile'
	'Get-HPOVProfile'				  = 'Get-HPOVServerProfile'
	'Get-HPOVProfileAssign'		      = 'New-HPOVServerProfileAssign'
	'Get-HPOVProfileConnectionList'   = 'Get-HPOVServerProfileConnectionList'
	'Get-HPOVServerHardwareTypes'	  = 'Get-HPOVServerHardwareType'
	'Get-HPOVSppFile'				  = 'Get-HPOVBaseline'
	'New-HPOVAddressRange'		      = 'New-HPOVAddressPoolRange'
	'New-HPOVEnclosure'			      = 'Add-HPOVEnclosure'
	'New-HPOVLdap'				      = 'New-HPOVLdapDirectory'
	'New-HPOVProfile'				  = 'New-HPOVServerProfile'
	'New-HPOVProfileAttachVolume'	  = 'New-HPOVServerProfileAttachVolume'
	'New-HPOVProfileConnection'	      = 'New-HPOVServerProfileConnection'
	'New-HPOVSanManager'			  = 'Add-HPOVSanManager'
	'New-HPOVServer'				  = 'Add-HPOVServer'
	'New-HPOVStoragePool'			  = 'Add-HPOVStoragePool'
	'New-HPOVStorageSystem'		      = 'Add-HPOVStorageSystem'
	'Remove-HPOVLdap'				  = 'Remove-HPOVLdapDirectory'
	'Remove-HPOVProfile'			  = 'Remove-HPOVServerProfile'
	'Set-HPOVRole'				      = 'Set-HPOVUserRole'
	'Show-HPOVBaselineRepositorySize' = 'Get-HPOVBaselineRepository'
	'sr'							  = 'Send-HPOVRequest'
	'Wait-HPOVTaskAccepted'		      = 'Wait-HPOVTaskStart'
}
foreach ($alias in $aliases.Keys)
{
	Set-Alias -Name $alias -Value $aliases[$alias]
}