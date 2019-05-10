if (-not (Test-Path "HKCU:\Software\Hewlett-Packard\HPOneView"))
{
	
	New-Item "HKCU:\Software\Hewlett-Packard\HPOneView" -force | Out-Null
	
}

#######################################################
# Library Global Settings Init
#

# Needed to support non-Windows PowerShell environments
$private:IsWindows = if (-not (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue)) { $True }
else { $IsWindows }

if ($private:IsWindows)
{
	
	# Check to see if Global Policy is set first.
	$regkeyGlobal = "HKLM:\Software\Hewlett-Packard\HPOneView"
	$regkeyUser = "HKCU:\Software\Hewlett-Packard\HPOneView"
	$UserUseMSDSC = [bool](Get-ItemProperty -LiteralPath $regkeyUser -ErrorAction SilentlyContinue).'UseMSDSC'
	$PesterRun = Get-Variable -Name PesterTest -Scope Global -ErrorAction SilentlyContinue
	
	Write-Verbose "$regkeyUser exists: $(Test-Path $regkeyUser)" -verbose:$script:ModuleVerbose
	Write-Verbose "UseMSDSC Enabled: $($UserUseMSDSC)" -verbose:$script:ModuleVerbose
	
	# Override Write-Host for MSDSC
	if ((Test-Path $regkeyUser) -and ($UserUseMSDSC))
	{
		
		function Write-Host
		{
			
			[CmdletBinding ()]
			param
			(
				
				[Parameter (Mandatory = $false)]
				[Object]
				$Object,
				
				[Parameter (Mandatory = $false)]
				[Object]
				$Object2,
				
				[Parameter (Mandatory = $false)]
				[Object]
				$Object3,
				
				[Switch]
				$NoNewLine,
				
				[ConsoleColor]
				$ForegroundColor,
				
				[ConsoleColor]
				$BackgroundColor
				
			)
			
			# Override default Write-Host...
			Write-Verbose $Object -verbose:$script:ModuleVerbose
			
		}
		
		function Get-Host
		{
			
			[CmdletBinding ()]
			param ()
			
			return [PSCustomObject]$Width = @{ UI = @{ RawUI = @{ MaxWindowSize = @{ width = 120 } } } }
			
		}
		
	}
	
}

if ($PesterRun)
{
	
	function Write-Host
	{
		
		[CmdletBinding ()]
		param
		(
			
			[Parameter (Mandatory = $false)]
			[Object]
			$Object,
			
			[Parameter (Mandatory = $false)]
			[Object]
			$Object2,
			
			[Parameter (Mandatory = $false)]
			[Object]
			$Object3,
			
			[Switch]
			$NoNewLine,
			
			[ConsoleColor]
			$ForegroundColor,
			
			[ConsoleColor]
			$BackgroundColor
			
		)
		
		# Override default Write-Host...
		Out-Null
		
	}
	
}

#######################################################
#  Remove-Module Processing
#

$ExecutionContext.SessionState.Module.OnRemove = {
	
	"[{0}] Cleaning up" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose -verbose:$script:ModuleVerbose
	
	'PesterTest', 'CallStack', 'ConnectedSessions', 'FCNetworkFabricTypeEnum', 'GetUplinkSetPortSpeeds', 'SetUplinkSetPortSpeeds', 'LogicalInterconnectConsistencyStatusEnum', 'UplinkSetNetworkTypeEnum', 'UplinkSetEthNetworkTypeEnum', 'LogicalInterconnectGroupRedundancyEnum', 'IgnoreCertPolicy', 'ResponseErrorObject' | ForEach-Object { Remove-Variable -Name $_ -Scope Global -ErrorAction SilentlyContinue }
	
}