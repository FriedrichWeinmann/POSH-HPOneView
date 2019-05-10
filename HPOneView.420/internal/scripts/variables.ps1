# Set HPOneView POSH Library Version
[Version]$ModuleVersion = '4.20.1971.1960'
New-Variable -Name PSLibraryVersion -Scope Global -Value (New-Object HPOneView.Library.Version($ModuleVersion)) -Option Constant -ErrorAction SilentlyContinue
$Global:CallStack = Get-PSCallStack
$script:ModuleVerbose = [bool]($Global:CallStack | Where-Object { $_.Command -eq "<ScriptBlock>" }).position.text -match "-verbose"
[void][Reflection.Assembly]::LoadWithPartialName("System.Web")

# Check to see if another module is loaded in the console, but allow Import-Module to Process normally if user specifies the same module name
if (Get-Module -Name HPOneView* | Where-Object Name -ne "HPOneView.420")
{
	
	write-Host "CRITICAL:  Another HP OneView module is already loaded:  " -ForegroundColor Yellow -BackgroundColor Black
	Write-Host "  |" -ForegroundColor Yellow -BackgroundColor Black
	get-module -name HPOneView* | ForEach-Object { write-host "  |--> $($_.name) ($($_.Version))" -ForegroundColor Yellow -BackgroundColor Black }
	write-host ""
	
	[System.String]$Exception = 'InvalidOperationException'
	[System.String]$ErrorId = 'CannotLoadMultipleLibraries'
	[System.Object]$TargetObject = 'Import-Module HPOneView.420'
	[System.Management.Automation.ErrorCategory]$ErrorCategory = 'ResourceExists'
	[System.String]$Message = 'Another HPE OneView module is already loaded.  The HPE OneView PowerShell library does not support loading multiple versions of libraries within the same console.'
	
	$_exception = New-Object $Exception $Message
	$ErrorRecord = New-Object Management.Automation.ErrorRecord $_exception, $ErrorID, $ErrorCategory, $TargetObject
	throw $ErrorRecord
	
}

# Region URIs and Enums
${Global:ConnectedSessions} = New-Object HPOneView.Library.ConnectedSessionsList
${Global:ResponseErrorObject} = New-Object System.Collections.ArrayList
New-Variable -Name DefaultTimeout -Value (New-Timespan -Minutes 20) -Option Constant
$script:FSOpenMode = [System.IO.FileMode]::Open
$script:FSRead = [System.IO.FileAccess]::Read
[MidpointRounding]$MathMode = 'AwayFromZero'
[String]$MinXAPIVersion = "1000"
[String]$MaxXAPIVersion = "1000"
[String]$Repository = "https://api.github.com/repos/HewlettPackard/POSH-HPOneView/releases"

if ($Global:IgnoreCertPolicy)
{
	
	[HPOneView.PKI.SslValidation]::IgnoreCertErrors = $true
	
}

$ResourceCategoryEnum = @{
	Baseline				    = 'firmware-drivers';
	ServerHardware			    = 'server-hardware';
	ServerHardwareType		    = 'server-hardware-types';
	ServerProfile			    = 'server-profiles';
	ServerProfileTemplate	    = 'server-profile-templates';
	Enclosure				    = 'enclosures';
	LogicalEnclosure		    = 'logical-enclosures';
	EnclosureGroup			    = 'enclosure-groups';
	Interconnect			    = 'interconnects';
	LogicalInterconnect		    = 'logical-interconnects';
	LogicalInterconnectGroup    = 'logical-interconnect-groups';
	SasInterconnect			    = 'sas-interconnects';
	SasLogicalInterconnect	    = 'sas-logical-interconnects';
	SasLogicalInterconnectGroup = 'sas-logical-interconnect-groups';
	ClusterProfile			    = 'hypervisor-cluster-profiles';
	HypervisorManager		    = 'hypervisor-managers';
	HypervisorCluster		    = 'hypervisor-clusters';
	ClusterNode				    = 'hypervisor-hosts';
	FabricManager			    = 'fabric-managers';
	FabricManagerTenant		    = 'tenants';
	RackManager				    = 'rack-managers'
}

#------------------------------------
#  Appliance Configuration
#------------------------------------
[Int]$ApplianceStartupTimeout = 900
[String]$ApplianceStartProgressUri = '/rest/appliance/progress'
[String]$ApplianceVersionUri = '/rest/appliance/nodeinfo/version'
[String]$ApplianceEulaStatusUri = '/rest/appliance/eula/status'
[String]$ApplianceEulaSaveUri = '/rest/appliance/eula/save'
[String]$ApplianceNetworkConfigUri = '/rest/appliance/network-interfaces'
[String]$ApplianceNetworkStatusUri = '/rest/appliance/network-interfaces/status'
[String]$ApplianceNetworkMacAddrUri = '/rest/appliance/network-interfaces/mac-addresses'
[string]$ApplianceDateTimeUri = '/rest/appliance/configuration/time-locale'
[String]$ApplianceGlobalSettingsUri = '/rest/global-settings'
[String]$ApplianceBaselineRepoUri = '/rest/firmware-drivers'
[String]$ApplianceRepositoriesUri = '/rest/repositories'
[String]$ApplianceBaselineRepositoriesUri = '/rest/firmware-repositories/defaultOneViewRepo'
[Hashtable]$RepositoryType = @{
	External = 'FirmwareExternalRepo';
	Internal = 'FirmwareInternalRepo'
}
[String]$ApplianceXApiVersionUri = '/rest/version'
[String]$ApplianceHANodesUri = '/rest/appliance/ha-nodes'
[String]$ApplianceBackupUri = '/rest/backups'
[String]$ApplianceRestoreRepoUri = '/rest/backups/archive'
[String]$ApplianceAutoBackupConfUri = '/rest/backups/config'
[String]$ApplianceRestoreUri = '/rest/restores'
[String]$ApplianceProxyConfigUri = '/rest/appliance/proxy-config'
[Hashtable]$ApplianceUpdateProgressStepEnum = @{
	
	COMPLETED		     = "Restore Completed";
	FAILED			     = "Restore Failed";
	PREPARING_TO_RESTORE = "Preparing to Restore";
	RESTORING_DB		 = "Restoring Database";
	RESTORING_FILES	     = "Restoring Files";
	STARTING_SERVICES    = "Starting Services";
	UNKNOWN			     = "The restore step is unknown"
	
}
[Hashtable]$ApplianceLocaleSetEnum = @{
	
	'en-US' = 'en_US.UTF-8';
	'en_US' = 'en_US.UTF-8';
	'zh_CN' = 'zh_CN.UTF-8';
	'zh-CN' = 'zh_CN.UTF-8';
	'ja_JP' = 'ja_JP.UTF-8';
	'ja-JP' = 'ja_JP.UTF-8';
	
}
[Hashtable]$ApplianceLocaleEnum = @{
	
	'en_US.UTF-8' = 'English (United States)';
	'zh_CN.UTF-8' = 'Chinese (China)';
	'ja_JP.UTF-8' = 'Japanese (Japan)';
	
}
[Hashtable]$DayOfWeekEnum = @{
	
	Sunday    = 'SU';
	SU	      = 'SU';
	SUN	      = 'SU';
	Monday    = 'MO';
	MO	      = 'MO';
	MON	      = 'MO';
	Tuesday   = 'TU';
	TU	      = 'TU';
	TUE	      = 'TU';
	TUES	  = 'TU';
	Wednesday = 'WE';
	WE	      = 'WE';
	WED	      = 'WE';
	Thursday  = 'TH';
	Thur	  = 'TH';
	Thurs	  = 'TH';
	TH	      = 'TH';
	Friday    = 'FR';
	Fri	      = 'FR';
	FR	      = 'FR';
	Saturday  = 'SA';
	Sat	      = 'SA';
	SA	      = 'SA';
	
}
[Hashtable]$AppliancePlatformType = @{
	
	hardware = 'Composer';
	vm	     = 'VMA'
	
}
[String]$ApplianceSupportDumpUri = "/rest/appliance/support-dumps"
[String]$ApplianceHealthStatusUri = "/rest/appliance/health-status"
[String]$ApplianceUpdateImageUri = "/rest/appliance/firmware/image"
[String]$ApplianceUpdatePendingUri = "/rest/appliance/firmware/pending"
[String]$ApplianceUpdateNotificationUri = "/rest/appliance/firmware/notification"
[String]$ApplianceUpdateMonitorUri = "/cgi-bin/status/update-status.cgi"
[String]$ApplianceSnmpReadCommunityUri = "/rest/appliance/device-read-community-string"
[String]$script:applianceRebootUri = '/rest/appliance/shutdown?type=REBOOT'
[String]$script:applianceShutDownUri = '/rest/appliance/shutdown?type=HALT'
[String]$script:applianceCsr = '/rest/certificates/https/certificaterequest'
[String]$script:applianceSslCert = '/rest/certificates/https'
[String]$Script:appliancePingTestUri = '/rest/appliance/reachable'
[string]$script:applianceDebugLogSetting = '/logs/rest/debug/'
[string]$script:RemoteSyslogUri = '/rest/remote-syslog'
[string]$script:IPSubnetAddressPattern = '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' +
'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' +
'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' +
'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' +
'(/0*([1-9]|[12][0-9]|3[0-2]))?$'
[String]$LabelsUri = '/rest/labels'
[String]$LabelsResourcesBaseUri = '/rest/labels/resources'
[String]$ApplianceSnmpV3TrapDestUri = '/rest/appliance/snmpv3-trap-forwarding/destinations'
[String]$ApplianceSnmpV3UsersUri = '/rest/appliance/snmpv3-trap-forwarding/users'
[String]$ApplianceSnmpV1TrapDestUri = '/rest/appliance/trap-destinations'
[String]$ApplianceSnmpV1TrapDestValidationUri = '/rest/appliance/trap-destinations/validation'
[String]$ApplianceSnmpV3TrapDestUri = '/rest/appliance/snmpv3-trap-forwarding/destinations'
[String]$ApplianceSnmpV3TrapDestValidationUri = '/rest/appliance/snmpv3-trap-forwarding/destinations/validation'
[String]$ApplinaceSnmpV3EngineIdUri = '/rest/global-settings/appliance/global/applianceSNMPv3EngineId'

#------------------------------------
#  Remote Support
#------------------------------------
[String]$RemoteSupportUri = '/rest/support'
[String]$RemoteSupportConfigUri = '/rest/support/configuration'
[String]$RemoteSupportContactsUri = '/rest/support/contacts'
[String]$RemoteSupportSitesUri = '/rest/support/sites'
[String]$RemoteSupportDefaultSitesUri = '/rest/support/sites/default'
[String]$ServerHardwareRemoteSupportSettingsUri = '/rest/support/server-hardware'
[String]$EnclosureRemoteSupportSettingsUri = '/rest/support/server-hardware'
[String]$RemoteSupportDataCollectionsUri = '/rest/support/data-collections'
[String]$RemoteSupportDataCollectionsDownloadUri = '/rest/support/data-collections/download'
[string]$InsightOnlinePortalRegistraionUri = '/rest/support/portal-registration'
[String]$RemoteSupportChannelPartnersUri = '/rest/support/channel-partners'
[String]$RemoteSupportChannelPartnersValidatorUri = '/rest/support/channel-partners/validator'
[String]$RemoteSupportDataCollectionScheduleUri = '/rest/support/schedules'
[String]$RemoteSupportComputeSettingsUri = '/rest/support/server-hardware'
[String]$RemoteSupportEnclosureSettingsUri = '/rest/support/enclosures'
[HashTable]$RemoteSupportResourceSettingEnum = @{
	'salesChannelPartnerUri'   = 'SalesChannelPartner';
	'supportChannelPartnerUri' = 'SupportChannelPartner';
	'primaryContactUri'	       = 'PrimaryContact';
	'secondaryContactUri'	   = 'SecondaryContact'
}
[Hashtable]$RemoteSupportCollectionEnum = @{
	'AHS'   = 'AHS';
	'Basic' = 'Basic'
}
[Array]$RemoteSupportUris = @(
	$RemoteSupportUri,
	$RemoteSupportConfigUri,
	$RemoteSupportContactsUri,
	$RemoteSupportSitesUri,
	$RemoteSupportDefaultSitesUri
)
#------------------------------------
#  Remote Technician
#------------------------------------
[String]$RemoteTechnicianUri = '/rest/appliance/rda-cas'
[String]$RemoteTechnicianAclUri = '{0}/access-control' -f $RemoteTechnicianUri
[String]$RemoteTechnicianActiveTechniciaConnectionsUri = '{0}/connections' -f $RemoteTechnicianUri
[String]$RemoteTechnicianActiveApplianceConnectivityStatusUri = '{0}/connectivity' -f $RemoteTechnicianUri
[String]$RemoteTechnicianAgentInfoUri = '{0}/info' -f $RemoteTechnicianUri
[String]$RemoteTechnicianConnectivitySessionsUri = '{0}/sessions' -f $RemoteTechnicianUri
[String]$RemoteTechnicianTunnelSessionsUri = '{0}/tunnel' -f $RemoteTechnicianUri
#------------------------------------
#  Image Streamer (I3S) Management
#------------------------------------
[String]$DeploymentServersUri = '/rest/deployment-servers' # Mapped to Get-HPOVOSDeploymentServer?
[String]$AvailableDeploymentServersUri = '/rest/deployment-servers/image-streamer-appliances' # Mapped to Show-HPOVImageStreamer?
[String]$DeploymentPlansUri = '/rest/os-deployment-plans/' # Mapped to Get-HPOVOsDeploymentPlan
#------------------------------------
#  Physical Resource Management
#------------------------------------
[String]$CClassEnclosureTypeUri = "/rest/enclosure-types/c7000"
[String]$SynergyEnclosureTypeUri = "/rest/enclosure-types/SY12000"
[String]$ServerHardwareUri = "/rest/server-hardware"
[String]$ServerHardwareFirmwareComplianceUri = '{0}/firmware-compliance' -f $ServerHardwareUri
[String]$script:ServerHardwareTypesUri = "/rest/server-hardware-types"
[String]$EnclosuresUri = "/rest/enclosures"
[String]$script:LogicalEnclosuresUri = '/rest/logical-enclosures'
[String]$script:EnclosureGroupsUri = "/rest/enclosure-groups"
[String]$script:EnclosurePreviewUri = "/rest/enclosure-preview"
[String]$VCMigratorUri = "/rest/migratable-vc-domains"
[String]$script:FwUploadUri = "/rest/firmware-bundles"
[String]$ApplianceFwDriversUri = "/rest/firmware-drivers"
[String]$RackManagerUri = '/rest/rack-managers'
[String]$PowerDevicesUri = "/rest/power-devices"
[String]$script:PowerDevicesDiscoveryUri = "/rest/power-devices/discover"
[String]$script:PowerDevicePotentialConnections = "/rest/power-devices/potentialConnections?providerUri="
[String]$script:UnmanagedDevicesUri = "/rest/unmanaged-devices?sort=name:asc"
[PSCustomObject]$MpModelTable = @{
	ilo2 = "RI7";
	ilo3 = "RI9";
	ilo4 = "RI10"
	iLO5 = "RI11"
}
[HashTable]$Script:ServerPowerControlEnum = @{
	
	PressAndHold   = 'PressAndHold';
	MomentaryPress = 'MomentaryPress';
	ColdBoot	   = 'ColdBoot';
	Reset		   = 'Reset'
	
}
[string]$SyngergyEnclosureTypeUri = '/rest/enclosure-types/SY12000'
[string]$C7000EnclosureTypeUri = '/rest/enclosure-types/c7000'
[Hashtable]$EnclosureGroupIpAddressModeEnum = @{
	
	DHCP	    = 'DHCP';
	External    = 'External';
	AddressPool = 'IpPool'
	
}
[Hashtable]$FramePowerModeEnum = @{
	
	RedundantPowerSupply = 'RedundantPowerSupply';
	RedundantPowerFeed   = 'RedundantPowerFeed'
	
}
[Hashtable]$FrameAmbientTemperatureEnum = @{
	
	'ASHRAE_A3' = 'ASHRAE_A3';
	'ASHRAE_A4' = 'ASHRAE_A4';
	'Standard'  = 'Standard';
	'Telco'	    = 'Telco'
}
[Hashtable]$LogicalEnclosureFirmwareUpdateMethodEnum = @{
	EnclosureOnly						  = 'EnclosureOnly';
	SharedInfrastructureOnly			  = 'SharedInfrastructureOnly';
	SharedInfrastructureAndServerProfiles = 'SharedInfrastructureAndServerProfiles'
}
[Hashtable]$LogicalInterconnectUpdateModeEnum = @{
	Orchestrated = 'Orchestrated';
	Parallel	 = 'Parallel'
}
#------------------------------------
#  Storage Resource Management
#------------------------------------
[String]$SasLogicalInterconnectType = 'sas-logical-interconnectV2'
[String]$SasLogicalInterconnectCategory = 'sas-logical-interconnect'
[String]$SasLogicalInterconnectGroupType = 'sas-logical-interconnect-groupV2'
[String]$SasLogicalInterconnectGroupCategory = 'sas-logical-interconnect-groups'
[String]$DriveEnclosureUri = '/rest/drive-enclosures'
[String]$script:SasInterconnectTypeUri = '/rest/sas-interconnect-types'
[String]$script:SasInterconnectsUri = '/rest/sas-interconnects'
[String]$SasLogicalInterconnectsUri = '/rest/sas-logical-interconnects'
[String]$script:SasLogicalInterconnectGroupsUri = '/rest/sas-logical-interconnect-groups'
[String]$StorageSystemsUri = "/rest/storage-systems"
[String]$StorageVolumesUri = "/rest/storage-volumes"
[String]$StorageVolumeFromSnapshotUri = '/rest/storage-volumes/from-snapshot'
[String]$StoragePoolsUri = "/rest/storage-pools"
[String]$ReachableStoragePoolsUri = '/rest/storage-pools/reachable-storage-pools'
[String]$AttachableStorageVolumesUri = '/rest/storage-volumes/attachable-volumes'
[String]$script:StorageVolumeTemplateUri = "/rest/storage-volume-templates"
[string]$script:ApplStorageVolumeTemplateRequiredPolicy = '/rest/global-settings/appliance/global/StorageVolumeTemplateRequired'
[String]$script:fcSanManagerProvidersUri = "/rest/fc-sans/providers" # List available SAN Manager plugins, and create SAN Manager
[Hashtable]$StorageVolumeProvisioningTypeEnum = @{
	'Thin'			    = 'Thin';
	'Full'			    = 'Full';
	'ThinDeduplication' = 'Thin Deduplication'
}
[Hashtable]$SnmpAuthLevelEnum = @{
	None	    = "noauthnopriv";
	AuthOnly    = "authnopriv";
	AuthAndPriv = "authpriv"
}
[Hashtable]$Snmpv3UserAuthLevelEnum = @{
	None	    = "None";
	AuthOnly    = "Authentication";
	AuthAndPriv = "Authentication and privacy"
}
[Hashtable]$SnmpAuthProtocolEnum = @{
	
	'none'   = 'none';
	'md5'    = 'MD5';
	'SHA'    = 'SHA';
	'sha1'   = 'SHA1';
	'sha2'   = 'SHA2';
	'sha256' = 'SHA256';
	'sha384' = 'SHA384';
	'sha512' = 'SHA512'
	
}
[Hashtable]$SnmpPrivProtocolEnum = @{
	'none'    = 'none';
	'aes'	  = "AES128";
	'aes-128' = "AES128";
	'aes-192' = "AES192";
	'aes-256' = "AES256";
	'aes128'  = "AES128";
	'aes192'  = "AES192";
	'aes256'  = "AES256";
	'des56'   = "DES56";
	'3des'    = "3DES";
	'tdea'    = 'TDEA'
}
[Hashtable]$ApplianceSnmpV3PrivProtocolEnum = @{
	'none'   = 'none';
	"des56"  = 'DES';
	'3des'   = '3DES';
	'aes128' = 'AES-128';
	'aes192' = 'AES-192';
	'aes256' = 'AES-256'
}
[String]$script:FcSanManagersUri = "/rest/fc-sans/device-managers" # Created SAN Managers
[String]$script:FcManagedSansUri = "/rest/fc-sans/managed-sans" # Discovered managed SAN(s) that the added SAN Manager will manage
[String]$script:FcZonesUri = '/rest/fc-sans/zones'
[String]$Script:SanEndpoints = '/rest/fc-sans/Endpoints'
[RegEx]$Script:iQNPattern = '^(?:iqn\.[0-9]{4}-[0-9]{2}(?:\.[A-Za-z](?:[A-Za-z0-9\-]*[A-Za-z0-9])?)+(?::.*)?|eui\.[0-9A-Fa-f]{16})'
[RegEx]$StoreServeTargetPortIDPattern = '\d:\d:\d'
[Hashtable]$StorageVolShareableEnum = @{
	
	Private = $false;
	Shared  = $true
	
}
[Hashtable]$StorageSystemFamilyTypeEnum = @{
	StoreVirtual = 'StoreVirtual';
	StoreServ    = 'StoreServ'
}
[Hashtable]$Global:StorageSystemPortModeEnum = @{
	
	AutoSelectExpectedSan = 'Auto';
	Ignore			      = 'Ignore';
	Managed			      = 'Managed'
	
}
[Hashtable]$StorageVolumeProvisioningTypeEnum = @{
	Full = 'Full';
	Thin = 'Thin';
	TPDD = 'Thin'
}
[Hashtable]$DataProtectionLevelEnum = @{
	NetworkRaid0None		 = 'NetworkRaid0None';
	NetworkRaid5SingleParity = 'NetworkRaid5SingleParity';
	NetworkRaid10Mirror2Way  = 'NetworkRaid10Mirror2Way';
	NetworkRaid10Mirror3Way  = 'NetworkRaid10Mirror3Way';
	NetworkRaid10Mirror4Way  = 'NetworkRaid10Mirror4Way';
	NetworkRaid6DualParity   = 'NetworkRaid6DualParity'
}
#------------------------------------
#  Network Resource Management
#------------------------------------
[String]$LogicalInterconnectGroupType = 'logical-interconnect-groupV6'
[String]$LogicalInterconnectGroupCategory = 'logical-interconnect-groups'
[String]$InterconnectLinkTopologies = '/rest/interconnect-link-topologies'
[String]$NetworkSetsUri = "/rest/network-sets"
[String]$NetworkSetType = 'network-setV4'
[String]$EthernetNetworksUri = "/rest/ethernet-networks"
[String]$EthernetNetworkType = "ethernet-networkV4"
[String]$EthernetNetworkBulkType = "bulk-ethernet-networkV1"
[String]$FCNetworksUri = "/rest/fc-networks"
[String]$FCNetworkType = "fc-networkV4"
[String]$FCoENetworksUri = "/rest/fcoe-networks"
[String]$FCoENetworkType = "fcoe-networkV4"
[String]$ConnectionTemplatesUri = "/rest/connection-templates"
[String]$LogicalInterconnectGroupsUri = "/rest/logical-interconnect-groups"
[String]$LogicalInterconnectsUri = "/rest/logical-interconnects"
[String]$InterconnectsUri = "/rest/interconnects"
[String]$InterconnectTypesUri = '/rest/interconnect-types'
[String]$UplinkSetsUri = "/rest/uplink-sets"
[String]$LogicalDownlinksUri = "/rest/logical-downlinks"
[String]$SwitchTypesUri = '/rest/switch-types'
[String]$LogicalSwitchGroupsUri = '/rest/logical-switch-groups'
[String]$LogicalSwitchesUri = '/rest/logical-switches'
[String]$SwitchesUri = '/rest/switches'
[String]$FabricManagersUri = '/rest/fabric-managers'
[string]$DomainFabrics = '/rest/fabrics'
[Hashtable]$LogicalSwitchManagementLevelEnum = @{
	Managed		    = 'BASIC_MANAGED';
	Monitored	    = 'MONITORED';
	ManagedSnmpV3   = 'BASIC_MANAGED';
	MonitoredSnmpV3 = 'MONITORED'
}
[String]$script:ApplianceVmacPoolsUri = '/rest/id-pools/vmac'
[String]$script:ApplianceVmacPoolRangesUri = '/rest/id-pools/vmac/ranges'
[String]$script:ApplianceVwwnPoolsUri = '/rest/id-pools/vwwn'
[String]$script:ApplianceVwwnPoolRangesUri = '/rest/id-pools/vwwn/ranges'
[String]$script:ApplianceVsnPoolsUri = '/rest/id-pools/vsn'
[String]$script:ApplianceVsnPoolRangesUri = '/rest/id-pools/vsn/ranges'
[String]$script:ApplianceIPv4PoolsUri = '/rest/id-pools/ipv4'
[String]$script:ApplianceIPv4PoolRangesUri = '/rest/id-pools/ipv4/ranges'
[String]$script:ApplianceIPv4SubnetsUri = '/rest/id-pools/ipv4/subnets'
[String]$script:ApplianceVmacGenerateUri = '/rest/id-pools/vmac/generate'
[String]$script:ApplianceVwwnGenerateUri = '/rest/id-pools/vwwn/generate'
[String]$script:ApplianceVsnPoolGenerateUri = '/rest/id-pools/vsn/generate'
$MacAddressPattern = @('^([0-9a-f]{2}:){5}([0-9a-f]{2})$')
$WwnAddressPattern = @('^([0-9a-f]{2}:){7}([0-9a-f]{2})$')
$WwnLongAddressPattern = @('^([0-9a-f]{2}:){15}([0-9a-f]{2})$')
[RegEx]$script:ip4regex = "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"
[RegEx]$SnmpV3EngineIdPattern = "^10x([A-Fa-f0-9]{2}){5,32}"
[HashTable]$Global:FCNetworkFabricTypeEnum = @{
	
	FA		     = 'FabricAttach';
	FabricAttach = 'FabricAttach';
	DA		     = 'DirectAttach';
	DirectAttach = 'DirectAttach'
	
}
[Hashtable]$global:GetUplinkSetPortSpeeds = @{
	Speed0M   = "0";
	Speed100M = "100Mb";
	Speed10G  = "10Gb";
	Speed10M  = "10Mb";
	Speed1G   = "1Gb";
	Speed1M   = "1Mb";
	Speed20G  = "20Gb";
	Speed2G   = "2Gb";
	Speed2_5G = "2.5Gb";
	Speed40G  = "40Gb";
	Speed4G   = "4Gb";
	Speed8G   = "8Gb";
	Auto	  = "Auto"
}
[Hashtable]$global:SetUplinkSetPortSpeeds = @{
	'0'    = "Speed0M";
	'100M' = "Speed100M";
	'100'  = "Speed100M";
	'10G'  = "Speed10G";
	'10'   = "Speed10G";
	'10M'  = "Speed10M";
	'1G'   = "Speed1G";
	'1'    = "Speed1G";
	'1M'   = "Speed1M";
	'20G'  = "Speed20G";
	'2G'   = "Speed2G";
	'2'    = "Speed2G";
	'2.5G' = "Speed2_5G";
	'40G'  = "Speed40G";
	'4G'   = "Speed4G";
	'8G'   = "Speed8G";
	'4'    = "Speed4G";
	'8'    = "Speed8G";
	'Auto' = "Auto"
}
[Hashtable]$global:LogicalInterconnectConsistencyStatusEnum = @{
	
	'CONSISTENT'	 = "Consistent";
	'NOT_CONSISTENT' = "Inconsistent with group"
	
}
[Array]$IngressDscpClassMappingEnum = @('DSCP 18, AF21', 'DSCP 20, AF22', 'DSCP 22, AF23', 'DSCP 26, AF31', 'DSCP 28, AF32', 'DSCP 30, AF33', 'DSCP 34, AF41', 'DSCP 36, AF42', 'DSCP 38, AF43', 'DSCP 16, CS2', 'DSCP 24, CS3', 'DSCP 32, CS4', 'DSCP 10, AF11', 'DSCP 12, AF12', 'DSCP 14, AF13', 'DSCP 8, CS1', 'DSCP 0, CS0', 'DSCP 46, EF', 'DSCP 40, CS5', 'DSCP 48, CS6', 'DSCP 56, CS7')
[Hashtable]$Global:UplinkSetNetworkTypeEnum = @{
	
	Ethernet	  = 'Ethernet';
	FibreChannel  = 'FibreChannel';
	Untagged	  = 'Ethernet';
	Tunnel	      = 'Ethernet';
	ImageStreamer = 'Ethernet'
	
}
[Hashtable]$Global:UplinkSetEthNetworkTypeEnum = @{
	
	Ethernet	  = 'Tagged'
	Untagged	  = 'Untagged'
	Tunnel	      = 'Tunnel'
	ImageStreamer = 'ImageStreamer'
	
}
[Hashtable]$Global:LogicalInterconnectGroupRedundancyEnum = @{
	
	HighlyAvailable = 'HighlyAvailable';
	ASide		    = 'NonRedundantASide';
	BSide		    = 'NonRedundantBSide';
	Redundant	    = 'Redundant'
	
}
[Array]$Script:SnmpEneTrapCategoryEnums = @('Other', 'PortStatus', 'PortThresholds')
[Array]$Script:SnmpFcTrapCategoryEnums = @('Other', 'PortStatus')
[Array]$Script:SnmpVcmTrapCategoryEnums = @('Legacy')
[Array]$Script:SnmpTrapSeverityEnums = @('Critical', 'Info', 'Major', 'Minor', 'Normal', 'Unknown', 'Warning')
[Net.IPAddress]$Script:ExcludedIPSubnetID = '172.30.254.0' # Synergy Specific
[Net.IPAddress]$Script:ExcludedIPSubnetEnd = '172.30.254.254' # Synergy Specific
[Hashtable]$EthernetNetworkPurposeEnum = @{
	
	General	       = "General";
	Management	   = "Management";
	VMMigration    = "VMMigration";
	FaultTolerance = "FaultTolerance";
	ISCSI		   = 'ISCSI'
	
}
[String]$FabricManagersUri = '/rest/fabric-managers'
[Array]$FCTrunkCapablePartnumbers = @(
	
	'751465-B21',
	'779227-B21',
	'876259-B21',
	'P08477-B21'
	
)
#------------------------------------
#  Profile Management
#------------------------------------

[String]$ServerProfileType = "ServerProfileV10"
[String]$ServerProfilesCategory = $ResourceCategoryEnum.ServerProfile
[String]$ServerProfileTemplateType = "ServerProfileTemplateV6"
[String]$ServerProfileTemplatesCategory = 'server-profile-templates'
[String]$ServerProfilesUri = "/rest/{0}" -f $ServerProfilesCategory
[String]$ServerProfileTemplatesUri = '/rest/{0}?sort=name:asc' -f $ServerProfileTemplatesCategory
[String]$ServerProfileIndexListUri = "/rest/index/resources?sort=name:asc&category={0}" -f $ServerProfilesCategory
[String]$ServerProfileAvailStorageSystemsUri = '/rest/{0}/available-storage-systems' -f $ServerProfilesCategory
[String]$ServerProfilesAvailableNetworksUri = '/rest/{0}/available-networks' -f $ServerProfilesCategory
[Hashtable]$ServerProfileConnectionBootPriorityEnum = @{
	none		   = 'NotBootable';
	NotBootable    = 'NotBootable';
	Primary	       = 'Primary';
	Secondary	   = 'Secondary';
	IscsiPrimary   = 'Primary';
	IscsiSecondary = 'Secondary';
	LoadBalanced   = 'LoadBalanced'
}
[Hashtable]$ServerProfileSanManageOSType = @{
	CitrixXen  = "Citrix Xen Server 5.x/6.x";
	CitrisXen7 = "Citrix Xen Server 7.x";
	AIX	       = "AIX";
	IBMVIO	   = "IBM VIO Server";
	RHEL4	   = "RHE Linux (Pre RHEL 5)";
	RHEL3	   = "RHE Linux (Pre RHEL 5)";
	RHEL	   = "RHE Linux (5.x, 6.x, 7.x)";
	RHEV	   = "RHE Virtualization (5.x, 6.x)";
	RHEV7	   = "RHE Virtualization 7.x";
	VMware	   = "VMware (ESXi)";
	Win2k3	   = "Windows 2003";
	Win2k8	   = "Windows 2008/2008 R2";
	Win2k12    = "Windows 2012 / WS2012 R2";
	Win2k16    = "Windows Server 2016";
	OpenVMS    = "OpenVMS";
	Egenera    = "Egenera";
	Exanet	   = "Exanet";
	Solaris9   = "Solaris 9/10";
	Solaris10  = "Solaris 9/10";
	Solaris11  = "Solaris 11";
	ONTAP	   = "NetApp/ONTAP";
	OEL	       = "OE Linux UEK (5.x, 6.x)";
	OEL7	   = "OE Linux UEK 7.x";
	HPUX11iv1  = "HP-UX (11i v1, 11i v2)"
	HPUX11iv2  = "HP-UX (11i v1, 11i v2)";
	HPUX11iv3  = "HP-UX (11i v3)";
	SUSE	   = "SuSE (10.x, 11.x, 12.x)";
	SUSE9	   = "SuSE Linux (Pre SLES 10)";
	Inform	   = "InForm"
}
[Hashtable]$ServerProfileConnectionTypeEnum = @{
	
	'ethernet-networks' = 'Ethernet';
	'network-sets'	    = 'Ethernet';
	'fcoe-networks'	    = 'FibreChannel';
	'fc-networks'	    = 'FibreChannel';
	'FC'			    = 'FibreChannel';
	'FibreChannel'	    = 'FibreChannel';
	'FCoE'			    = 'FibreChannel';
	'Eth'			    = 'Ethernet';
	'Ethernet'		    = 'Ethernet';
	'iSCSI'			    = 'iSCSI'
	
}
[Hashtable]$LogicalDiskTypeEnum = @{
	
	'Sas'	  = 'SasHdd';
	'SASHDD'  = 'SasHdd';
	'Sata'    = 'SataHdd';
	'SATAHDD' = 'SataHdd';
	'Sasssd'  = 'SasSsd';
	'Satassd' = 'SataSsd';
	'Auto'    = $Null
	
}
[Hashtable]$ServerProfileFirmwareControlModeEnum = @{
	
	FirmwareOnly		    = 'FirmwareOnly';
	FirmwareAndSoftware	    = 'FirmwareAndOSDrivers';
	FirmwareOffline		    = 'FirmwareOnlyOfflineMode';
	FirmwareAndOSDrivers    = 'FirmwareAndOSDrivers';
	FirmwareOnlyOfflineMode = 'FirmwareOnlyOfflineMode'
	
}
[Hashtable]$ServerProfileFirmareActivationModeEnum = @{
	Immediate    = 'Immediate';
	NotScheduled = 'NotScheduled';
	Scheduled    = 'Scheduled'
}
[Hashtable]$IscsiInitiatorNameAssignmetEnum = @{
	Virtual	    = 'AutoGenerated';
	UserDefined = 'UserDefined'
}
#------------------------------------
#  Cluster Profile Management
#------------------------------------
[String]$ClusterProfileType = 'HypervisorClusterProfileV3'
[String]$ClusterProfilesUri = '/rest/hypervisor-cluster-profiles'
[String]$ClusterHostProfilesUri = '/rest/hypervisor-host-profiles'
[String]$HypervisorManagersUri = '/rest/hypervisor-managers'
[String]$HypervisorClustersUri = '/rest/hypervisor-clusters'
#------------------------------------
#  Datacenter/Facilities
#------------------------------------
[String]$DataCentersUri = '/rest/datacenters'
[String]$DataCenterRacksUri = '/rest/racks'
#------------------------------------
#  Index Search
#------------------------------------
[String]$IndexUri = "/rest/index/resources"
[String]$AssociationsUri = "/rest/index/associations"
[String]$IndexAssociatedResourcesUri = '{0}/resources' -f $AssociationsUri
[String]$AssociationTreesUri = "/rest/index/trees"
#------------------------------------
#  Tasks
#------------------------------------
[String]$AllNonHiddenTaskUri = "/rest/tasks?filter=hidden=$false"
[String]$TasksUri = "/rest/tasks"
[Array]$TaskFinishedStatesEnum = @(
	
	"Error",
	"Warning",
	"Completed",
	"Terminated",
	"Killed"
	
)
#------------------------------------
#  Alerts and Events
#------------------------------------
$AlertsUri = "/rest/alerts"
$script:eventsUri = "/rest/events"
[String]$SmtpConfigUri = "/rest/appliance/notifications/email-config"
[String]$TestNotificationUri = "/rest/appliance/notifications/send-email"
[String]$HtmlPattern = "</?\w+((\s+\w+(\s*=\s*(?:`".*?`|'.*?'|[\^'`">\s]+))?)+\s*|\s*)/?>"
[Hashtable]$SmtpConnectionSecurityEnum = @{
	
	None	 = 'PLAINTEXT';
	Tls	     = 'TLS';
	StartTls = 'STARTTLS'
	
}
#------------------------------------
#  Licenses
#------------------------------------
$ApplianceLicensePoolUri = "/rest/licenses"
#------------------------------------
#  Security
#------------------------------------
[String]$ApplianceSecurityModesUri = '/rest/security-standards/modes'
[String]$ApplianceCurrentSecurityModeUri = '/rest/security-standards/modes/current-mode'
[String]$ApplianceSecurityModeCompatibiltyReportUri = '/rest/security-standards/compatibility-report'
[String]$ApplianceSecurityProtocolsUri = '/rest/security-standards/protocols'
[String]$UserLoginSessionUri = '/rest/sessions'
[String]$ApplianceLoginSessionsUri = '/rest/login-sessions'
[String]$ApplianceLoginSessionsSmartCardAuthUri = '/rest/login-sessions/smartcards'
[String]$UpdateApplianceSessionAuthUri = '/rest/login-sessions/auth-token'
[String]$ActiveUserSessionsUri = '/rest/active-user-sessions'
[String]$ApplianceUserAccountsUri = '/rest/users'
[String]$ApplianceUserAccountRoleUri = "/rest/users/role"
[String]$ApplianceTrustedCertStoreUri = '/rest/certificates'
[string]$ApplianceCertificateValidatorUri = '/rest/certificates/validator-configuration'
[String]$ApplianceCertificateAuthorityUri = '/rest/certificates/ca'
[String]$ApplianceInternalCertificateAuthority = '/rest/certificates/ca?filter=certType:INTERNAL'
[String]$ApplianceTrustedCAValidatorUri = '/rest/certificates/ca/validator'
[String]$ApplianceTrustedSslHostStoreUri = '/rest/certificates/servers'
[String]$ApplianceScmbRabbitmqUri = "/rest/certificates/client/rabbitmq"
[String]$ApplianceRabbitMQKeyPairUri = "/rest/certificates/client/rabbitmq/keypair/default"
[String]$ApplianceRabbitMQKeyPairCertUri = '/rest/certificates/ca/rabbitmq_readonly'
[String]$RetrieveHttpsCertRemoteUri = "/rest/certificates/https/remote/"
[String]$AuthnProvidersUri = '/rest/logindomains'
[String]$Authn2FALoginCertificateConfigUri = '/rest/logindomains/logincertificates'
[String]$AuthnAllowLocalLoginUri = '/rest/logindomains/global-settings/allow-local-login'
[String]$AuthnDefaultLoginDomainUri = '/rest/logindomains/global-settings/default-login-domain'
$script:AuthnProviderValidatorUri = "/rest/logindomains/validator"
[String]$AuthnSettingsUri = "/rest/logindomains/global-settings"
$AuthnDirectoryGroups = "/rest/logindomains/groups"
$Script:AuthnDirectorySearchContext = '/rest/logindomains/contexts'
$AuthnEgroupRoleMappingUri = "/rest/logindomains/grouptorolemapping"
$script:ApplAuditLogsUri = "/rest/audit-logs"
$script:ApplAuditLogDownloadUri = "/rest/audit-logs/download"
$ApplianceRolesUri = '/rest/roles'
$Script:ApplianceLoginDomainDetails = '/rest/logindetails'
[String]$ScopesUri = '/rest/scopes'
[String]$ApplianceServiceAccess = '/rest/appliance/settings/enableServiceAccess'
[String]$ApplianceSshAccess = '/rest/appliance/ssh-access'
[Hashtable]$ScopeCategoryEnum = @{
	
	'enclosures'				  = 'Enclosure';
	'enclosure-groups'		      = 'EnclosureGroup';
	'logical-enclosures'		  = 'LogicalEnclosure';
	'server-hardware'			  = 'ServerHardware';
	'network-sets'			      = 'NetworkSet';
	'interconnects'			      = 'Interconnect';
	'logical-interconnects'	      = 'LogicalInterconnect';
	'logical-interconnect-groups' = 'LogicalInterconnectGroup';
	'ethernet-networks'		      = 'EthernetNetwork';
	'fc-networks'				  = 'FCNetwork';
	'fcoe-networks'			      = 'FCoENetwork';
	'logical-switches'		      = 'LogicalSwitch';
	'logical-switch-groups'	      = 'LogicalSwitchGroup';
	'switches'				      = 'Switch';
	'server-profiles'			  = 'ServerProfile';
	'server-profile-templates'    = 'ServerProfileTemplate';
	'firmware-drivers'		      = 'FirmwareBundle';
	'os-deployment-plans'		  = 'OSDeploymentPlan';
	'storage-pools'			      = 'StoragePool';
	'storage-volumes'			  = 'StorageVolume';
	'storage-volume-templates'    = 'StorageVolumeTemplate';
	'scopes'					  = 'Scope';
	'hypervisor-managers'		  = 'HypervisorManagers'
	'hypervisor-cluster-profiles' = 'ClusterProfile';
	'hypervisor-hosts'		      = 'ClusterNode'
	
}
[Hashtable]$LdapDirectoryAccountBindTypeEnum = @{
	USERACCOUNT    = 'USER_ACCOUNT';
	SERVICEACCOUNT = 'SERVICE_ACCOUNT'
}
[Hashtable]$TwoFactorLocalLoginTypeEnum = @{
	NONE						  = 'NONE';
	APPLIANCECONSOLEONLY		  = 'APPLIANCE_CONSOLE_ONLY';
	APPLIANCE_CONSOLE_ONLY	      = 'APPLIANCECONSOLEONLY';
	NETWORK_AND_APPLIANCE_CONSOLE = 'NETWORKANDAPPLIANCECONSOLE';
	NETWORKANDAPPLIANCECONSOLE    = 'NETWORK_AND_APPLIANCE_CONSOLE'
}
$Script:OrganizationalUnitPattern = '^(?:(?:CN|OU|DC)\=[\w\s]+,)*(?:CN|OU|DC)\=[\w\s]+$'
$CommonNamePattern = '^CN=(.+?),(?:CN|OU)=.+'
$JsonPasswordRegEx = New-Object System.Text.RegularExpressions.Regex ('\"password\"\:[\s]*?\"(.*?)\"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

# Endregion

$WhiteListedURIs = @(
	
	$ApplianceLoginSessionsUri,
	$ApplianceLoginSessionsSmartCardAuthUri,
	$ApplianceUpdateMonitorUri,
	$ApplianceXApiVersionUri,
	"/ui-js/pages/",
	$ApplianceEulaStatusUri,
	$ApplianceEulaSaveUri,
	($ApplianceUserAccountsUri + "/changePassword"),
	"/startstop/rest/component?fields=status",
	$ApplianceStartProgressUri,
	$ApplianceLoginDomainDetails
	
)

$ExtendedTimeoutUris = @(
	$ApplianceSupportDumpUri,
	$ApplianceBackupUri,
	"$LogicalInterconnectsUri/*/support-dumps",
	$ApplianceScmbRabbitmqUri,
	$RemoteSupportUri
)