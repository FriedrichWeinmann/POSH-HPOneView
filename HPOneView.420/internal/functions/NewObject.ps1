function NewObject 
{

	[CmdletBinding ()]
	Param
	(

		[Object]$InputObject, 
		[switch]$FabricManagerClusterNodeInfo,
		[switch]$AddFabricManager,
		[switch]$AddStorageVolume,
		[switch]$AddRackManager,
		[switch]$AlertFilter,
		[switch]$AllApiResponse,
		[switch]$ApplianceCSR,
		[switch]$ApplianceDebug,
		[switch]$ApplianceGlobalCertificateValidationConfig,
		[switch]$ApplianceProxy,
		[switch]$ApplianceSslCertificate,
		[switch]$ApplianceSecurityProtocols,
		[switch]$ApplianceTimeLocale,
		[switch]$ApplianceTrustedCertAuthority,
		[switch]$ApplianceTrustedSslCertificate,
		[switch]$ApplianceVersion,
		[switch]$AuthDirectory,
		[switch]$AuthDirectoryServer,
		[switch]$AuthLoginCredential,
		[switch]$AutoBackupConfig,
		[switch]$BaseTrafficClass,
		[switch]$BulkEthernetNetworks,
		[switch]$CertificateToImport,
		[switch]$CertificateDetails,
		[switch]$ClusterProfileManager,
		[switch]$ClusterProfile,
		[switch]$ClusterVirtualSwitchConfig,
		[switch]$ClusterProfileVirtualSwitchUplink,
		[switch]$ClusterProfileVirtualSwitchPortGroup,
		[switch]$ClusterProfileVirtualSwitchPort,
		[switch]$ConvertSnapshotToVol,
		[switch]$CustomBaselineRestore,
		[switch]$DataCenter,
		[switch]$DataCenterItem,
		[switch]$DefaultBestEffortTrafficClass,
		[switch]$DefaultFCoELosslessQosTrafficClassifiers,
		[switch]$DefaultNoFCoELosslessQosTrafficClassifiers,
		[switch]$DeploymentModeSettings,
		[switch]$DirectoryGroup,
		[switch]$DirectoryGroupPermissions,
		[switch]$DirectoryGroupCredentials,
		[switch]$DownloadFileStatus,
		[switch]$EnclosureGroup,
		[switch]$SynergyEnclosureGroup,
		[switch]$EnclosureGroupPreview,
		[switch]$EnclosureGroupI3SDeploymentSettings,
		[switch]$EnclosureImport,
		[switch]$EnclosureRefresh,
		[switch]$EnclosureRefreshForceOptions,
		[switch]$EphemeralStorageVolume,
		[switch]$EthernetNetwork,
		[switch]$EulaStatus,
		[switch]$ExternalRepository,
		[switch]$FCNetwork,
		[switch]$FCoELossLessTrafficClass,
		[switch]$FCoENetwork,
		[switch]$FCAlias,
		[switch]$FCZone,
		[switch]$GlobalSetting,
		[switch]$IPIDPoolRange,
		[switch]$IDPoolRange,
		[switch]$I3SAdd,
		[switch]$IloRestSession,
		[switch]$IPv4Subnet,
		[switch]$InterconnectBayMapping,
		[switch]$InterconnectMapEntryTemplate,
		[switch]$InsightOnlineRegistration,
		[switch]$IscsiBootEntry,
		[switch]$IscsiIPv4Configuration,
		[switch]$LogicalInterconnectBaseline,
		[switch]$C7kLIG,
		[switch]$SELIG,
		[switch]$SESASLIG,
		[switch]$LiUplinkSetObject,
		[switch]$LigUplinkSetObject,
		[switch]$LicenseKey,
		[switch]$LocationEntry,
		[switch]$LogicalEnclosure,
		[switch]$LogicalEnclosureFirmareUpdate,
		[switch]$LogicalSwitchGroup,
		[switch]$LogicalSwitch,
		[switch]$LogicalSwitchCredentials,
		[switch]$LogicalSwitchSnmpV3Config,
		[switch]$LogialSwitchConnectionProperties,
		[switch]$LogicalSwitchConnectionProperty,
		[switch]$LoginMessageObject,
		[switch]$NetworkSet,
		[switch]$OSDeploymentSettings,
		[switch]$OSDeploymentPlanSetting,
		[switch]$PatchOperation,
		[switch]$Ping,
		[switch]$PowerDeliveryDeviceAdd,
		[switch]$Rack,
		[switch]$RackItem,
		[switch]$RabbitmqCertReq,
		[switch]$RemoteSupportConfig,
		[switch]$RemoteSupportContact,
		[switch]$RemoteSupportPartner,
		[switch]$RemoteSupportSchedule,
		[switch]$RemoteSupportSite,
		[switch]$RemoteSyslog,
		[switch]$ReservedVlanRange,
		[switch]$QosConfiguration,
		[switch]$SanManager,
		[switch]$SanManagerConnectInfo,
		[switch]$ScopeCollection,
		[switch]$ScopeMemberUpdate,
		[switch]$SecurityModeCompatabilityReport,
		[switch]$SelfSignedCert,
		[switch]$ServerImport,
		[switch]$ServerProfile,
		[switch]$ServerProfileBootMode,
		[switch]$ServerProfileBootModeLegacyBios,
		[switch]$ServerProfileEthernetConnection,
		[switch]$ServerProfileIscsiConnection,
		[switch]$ServerProfileFCConnection,
		[switch]$ServerProfileEthBootableConnection,
		[switch]$ServerProfileEthBootableConnectionWithTargets,
		[switch]$ServerProfileIscsiBootableConnectionWithTargets,
		[switch]$ServerProfileFcBootableConnection,
		[switch]$ServerProfileConnectionFcBootTarget,
		[switch]$ServerProfileLocalStorageController,
		[switch]$ServerProfileLocalStorageLogicalDrive,
		[switch]$ServerProfileSasLogicalJBOD,
		[switch]$ServerProfileStorageVolume,
		[switch]$ServerProfileTemplate,
		[switch]$ServerProfileTemplateLocalStorage,
		[switch]$SPTOSDeploymentSettings,
		[switch]$SmtpConfig,
		[switch]$SnmpConfig,
		[switch]$SnmpTrapDestination,
		[switch]$StoragePath,
		[switch]$StorageSystemCredentials,
		[switch]$StorageSystemManagedPort,
		[switch]$StorageVolume,
		[switch]$StorageVolumeTemplate,
		[switch]$StoreVirtualEphemeralVolumeProperties,
		[switch]$StoreServeEphemeralVolumeProperties,
		[switch]$SwitchLogicalLocation,
		[switch]$TemporaryConnection,
		[switch]$TestSmtpConfig,
		[switch]$UpdateAlert,
		[switch]$UplinkSetLocation,
		[switch]$UplinkSetLocationEntry,
		[switch]$UplinkSetLogicalLocation,
		[switch]$UplinkSetLogicalLocationEntry,
		[switch]$UnmanagedDevice,
		[switch]$UserAccount,
		[switch]$UpdateUserPassword,
		[switch]$UpdateToActivePermissions,
		[switch]$VcMigration,
		[switch]$VCMigratorReport,
		[switch]$VolSnapshot

	)

	Begin
	{

		"[{0}] Bound PS Parameters: {1}"  -f $MyInvocation.InvocationName.ToString().ToUpper(), ($PSBoundParameters | out-string) | Write-Verbose

		$Caller = (Get-PSCallStack)[1].Command

		"[{0}] Called from: {1}" -f $MyInvocation.InvocationName.ToString().ToUpper(), $Caller | Write-Verbose

	}

	Process
	{

		switch($PSBoundParameters.Keys)
		{

			'ReservedVlanRange'
			{

				Return [PSCustomObject]@{
					start  = 0;
					length = 0;
					type   = "vlan-pool"
				}

			}

			'AddRackManager'
			{

				return @{
					hostname = $null;
					username = $null;
					password = $null;
					force    = $false
				 }
			}

			'ApplianceSecurityProtocols'
			{

				Return @(  
					@{
						type = "ProtocolV1";
						protocolName = "TLSv1";
						enabled = $false
					},
					@{  
						type = "ProtocolV1";
						protocolName = "TLSv1.1";
						enabled = $false
					},
					@{  
						type = "ProtocolV1";
						protocolName = "TLSv1.2";
						enabled = $false
					}
				)
			}

			'SecurityModeCompatabilityReport'
			{

				return [PSCustomObject]@{

					currentMode = $null
					targetMode  = $null
					
				}

			}

			'LogicalEnclosureFirmareUpdate'
			{
				Return [PSCustomObject]@{

					firmwareBaselineUri                       = $null;
					firmwareUpdateOn                          = "SharedInfrastructureAndServerProfiles";
					forceInstallFirmware                      = $false;
					validateIfLIFirmwareUpdateIsNonDisruptive = $false;
					logicalInterconnectUpdateMode             = "Orchestrated"

				}

			 }

			'AddFabricManager'
			{

				Return [PSCustomObject]@{
					name                         = $null;
					fabricManagerType            = "Cisco ACI";
					userName                     = $null;
					password                     = $null;
					fabricManagerClusterNodeInfo = New-Object 'System.Collections.Generic.List[PSCustomObject]'
					type                         = "FabricManager"
				}
			
			}

			'FabricManagerClusterNodeInfo'
			{

				Return [PSCustomObject]@{

					oobMgmtAddr = $null

				}

			}

			'ClusterProfile'
			{

				Return [PSCustomObject]@{
					type                          = "HypervisorClusterProfileV3";
					name                          = $null;
					mgmtIpSettingsOverride        = [PSCustomObject]@{
						netmask      = $null;
						gateway      = $null;
						dnsDomain    = $null;
						primaryDns   = $null;
						secondaryDns = $null
					};
					hypervisorManagerUri          = $null;
					path                          = $null;
					initialScopeUris              = New-Object 'System.Collections.Generic.List[String]';
					description                   = "";
					hypervisorType                = "Vmware";
					hypervisorClusterSettings     = [PSCustomObject]@{  #// PULL PARAMS FROM Set-HPOVHypervisorManager
						type              = "Vmware";
						drsEnabled        = $true;
						haEnabled         = $false;
						multiNicVMotion   = $false;
						virtualSwitchType = "Standard"
					};
					hypervisorHostProfileTemplate = [PSCustomObject]@{
						serverProfileTemplateUri = $null;
						deploymentPlan           = [PSCustomObject]@{
							serverPassword       = $null
							deploymentCustomArgs = New-Object 'System.Collections.Generic.List[PSCustomObject]';
						};
						hostprefix       = $null;
						virtualSwitches  = New-Object 'System.Collections.Generic.List[PSCustomObject]';
						hostConfigPolicy = [PSCustomObject]@{
							leaveHostInMaintenance = $true
						};
						virtualSwitchConfigPolicy = [PSCustomObject]@{
							manageVirtualSwitches = $true;
							configurePortGroups   = $true
						}
			
					};
					sharedStorageVolumes          = 	New-Object 'System.Collections.Generic.List[PSCustomObject]';			
				
				}

			}

			'ClusterVirtualSwitchConfig'
			{

				Return [PSCustomObject]@{
					name                    = $null;
					virtualSwitchType       = "Standard";
					version                 = $null;
					virtualSwitchPortGroups = New-Object 'System.Collections.Generic.List[PSCustomObject]';
					virtualSwitchUplinks    = New-Object 'System.Collections.Generic.List[PSCustomObject]';
					action                  = "NONE";
					networkUris             = New-Object 'System.Collections.Generic.List[String]';
				}

			}

			'ClusterProfileVirtualSwitchUplink'
			{

				Return [PSCustomObject]@{
					name   = $null;
					mac    = $null;
					vmnic  = $null;
					action = "NONE";
					active = $false
				}

			}

			'ClusterProfileVirtualSwitchPortGroup'
			{

				Return [PSCustomObject]@{
					name        = $null;
					networkUris = New-Object 'System.Collections.Generic.List[String]';
					vlan        = "0";
					virtualSwitchPorts = @(
						
					);
					action = "NONE"
				}

			}

			'ClusterProfileVirtualSwitchPort'
			{

				Return [PSCustomObject]@{
					virtualPortPurpose = New-Object "System.Collection.Generic.List[String]";
					ipAddress          = $null;
					subnetMask         = $null;
					dhcp               = $true;
					action             = "NONE"
				}

			}

			'ServerProfileBootMode'
			{

				return [PSCustomObject]@{

					manageMode    = $false;
					mode          = $null;
					secureBoot    = "Unmanaged";
					pxeBootPolicy = "Auto"
				
				}
						
			}

			'ServerProfileBootModeLegacyBios'
			{

				return [PSCustomObject]@{

					manageMode    = $false;
					mode          = $null;
					secureBoot    = "Unmanaged"
				
				}
						
			}
			
			'ClusterProfileManager'
			{

				return [PSCustomObject]@{

					displayName      = $null;
					name             = $null;
					username         = $null
					password         = $null;
					port             = "443"
					initialScopeUris = New-Object System.Collections.ArrayList;
					type             = "HypervisorManagerV2"
				
				}
						
			}

			'CertificateToImport'
			{

				Return [PSCustomObject]@{

					type = 'CertificateInfoV2';
					certificateDetails = @(NewObject -CertificateDetails)
					
				}

			}

			'CertificateDetails'
			{

				Return [PSCustomObject]@{

					base64Data = $null;
					aliasName  = $null;
					type       = "CertificateDetailV2"
				
				}

			}

			'UpdateToActivePermissions' 
			{

				Return [PSCustomObject]@{

					sessionID = $null;
					permissionsToActivate = New-Object System.Collections.ArrayList

				}

			}

			'ApplianceGlobalCertificateValidationConfig'
			{
				
				Return [PSCustomObject]@{
					type = "CertValidationConfig";
					okToReboot = $False;
					certValidationConfig = @{
		
						'global.validateCertificate'                         = $false;
						'global.enableExpiryCheckForSelfSignedLeafAtConnect' = $false;
						'global.checkCertificateRevocation'                  = $true;
						'global.allow.noCRL'                                 = $true;
						'global.allow.invalidCRL'                            = $true
		
					}
		
				}
	
			}

			'ApplianceTrustedCertAuthority'
			{

				Return [PSCustomObject]@{

					certificateDetails = [PSCustomObject]@{
						aliasName  = $null;
						base64Data = $null;
						type       = "CertificateDetailV2"
					};

					type = "CertificateAuthorityInfo"
			
				}

			}
			
			'IloRestSession'
			{

				Return [PSCustomObject]@{
					
					RootUri        = $null;
					"X-Auth-Token" = $null;
					Location       = $null
				
				}

			}

			'SPTOSDeploymentSettings'
			{

				Return [PSCustomObject]@{

					osCustomAttributes  = $null;
					osDeploymentPlanUri = $null

				}

			}

			'ApplianceSslCertificate'
			{

				Return [PSCustomObject]@{

					type       = "CertificateDataV2";
					base64Data = $null

				}

			}

			'ApplianceTrustedSslCertificate'
			{

				Return [PSCustomObject]@{

					aliasName  = $null;
					base64Data = $null;
					type       = "CertificateDetailV2"

				}

			}

			'ExternalRepository'
			{

				Return [PSCustomObject]@{

					repositoryName = $null;
					userName       = $null;
					password       = $null;
					repositoryURI  = $null;
					repositoryType = "FirmwareExternalRepo";
					base64Data     = $null

				}

			}

			'OSDeploymentPlanSetting'
			{

				Return [PSCustomObject]@{

					name  = $null;
					value = $null

				}

			}

			'OSDeploymentSettings'
			{

				Return [PSCustomObject]@{

					osDeploymentPlanUri = $null;
					osCustomAttributes  = New-Object System.Collections.ArrayList

				}

			}

			'DataCenter'
			{

				Return [PSCustomObject]@{

					name                    = $null;
					coolingCapacity         = 5;
					costPerKilowattHour     = 0.10;
					currency                = 'USD';
					deratingType            = 'NaJp';
					deratingPercentage      = 20.0;
					defaultPowerLineVoltage = 220;
					coolingMultiplier       = 1.5;
					width                   = 0;
					depth                   = 0;
					contents                = New-Object System.Collections.ArrayList						

				}

			}

			'Rack'
			{

				Return [PSCustomObject]@{
					
					name         = $null;
					thermalLimit = $null;
					serialNumber = $null;
					partNumber   = $null;
					model        = $null;
					uHeight      = 0;
					depth        = 0;
					height       = 0;
					width        = 0;
					rackMounts   = New-Object System.Collections.ArrayList

				}

			}

			'DataCenterItem'
			{

				Return [PSCustomObject]@{

					resourceUri = $null;
					rotation    = 0;
					x           = 0;
					y           = 0

				}

			}

			'RackItem'
			{

				Return [PSCustomObject]@{

					mountUri = $null;
					location = 'CenterFront';
					relativeOrder = -1;
					topUSlot = 0;
					uHeight  = 0

				}

			}

			'RemoteSupportSchedule'
			{

				Return [PSCustomObject]@{

					type         = "Schedule";
					taskType     = $null;
					hourOfDay    = $null;
					taskKey      = $null;
					scheduleName = $null;
					repeatOption = $null;
					factory      = $true;
					viewable     = $true;
					serviceName  = $null;
					minute       = $null;
					dayOfMonth   = $null;
					dayOfWeek    = $null;
					enabled      = $true;
					priority     = $null

				}

			}

			'RemoteSupportPartner'
			{

				Return [PSCustomObject]@{

					type        = "ChannelPartner";
					id          = $null;
					default     = $false;
					partnerType = "RESELLER"
				
				}

			}

			'ApplianceProxy'
			{

				Return [PSCustomObject] @{

				    type                  = "ProxyServerV2";
					server                = $null;
					port                  = $null;
					username              = $null;
					password              = $null;
					credUri               = $null;
					communicationProtocol = 'HTTP'

				}

			}

			'InsightOnlineRegistration'
			{

				Return [PSCustomObject]@{
					
					type     = "PortalRegistration";
					userName = "username";
					password = "password"
				
				}

			}

			'RemoteSyslog'
			{

				Return [PSCustomObject]@{

					type                    = "RemoteSyslog";
					sendTestLog             = $false;
					remoteSyslogPort        = "514";
					remoteSyslogDestination = $null;
					enabled                 = $true

				}

			}

			'I3SAdd'
			{

				Return [PSCustomObject]@{

					description      = $null;
					name             = $null;
					mgmtNetworkUri   = $null;
					applianceUri     = $null;
					deplManagersType = 'Image Streamer'

				}

			}

			'LogicalSwitch'
			{
				Return [PSCustomObject]@{

					logicalSwitch = [PSCustomObject]@{
						type = 'logical-switchV4';
						name = $null;
						managementLevel = $null
						logicalSwitchGroupUri = $null;
						switchCredentialConfiguration = New-Object System.Collections.ArrayList
					
					};
					logicalSwitchCredentials = New-Object System.Collections.ArrayList

				}

			}

			'LogicalSwitchCredentials'
			{

				Return [PSCustomObject]@{

					snmpV1Configuration = [PSCustomObject] @{communityString = $null};
					snmpV3Configuration = NewObject -LogicalSwitchSnmpV3Config;
					logicalSwitchManagementHost = $null;
					snmpVersion = "SNMPv1";
					snmpPort = 161

				}
				
			}

			'LogicalSwitchSnmpV3Config'
			{

				Return [PSCustomObject]@{

					authorizationProtocol = $null;
					privacyProtocol = $null;
					securityLevel = $null

				}

			}

			'LogialSwitchConnectionProperties'
			{

				Return [PSCustomObject] @{ connectionProperties = New-Object System.Collections.ArrayList }
				
			}

			'LogicalSwitchConnectionProperty'
			{

				Return [PSCustomObject]@{
				
					propertyName = $null;
					value        = $null;
					valueFormat  = 'Unknown';
					valueType    = $null;
				
				}

			}

			'LogicalSwitchGroup'
			{

				Return [PSCustomObject]@{ 

					type              = "logical-switch-groupV4";
					name              = $null;
					state             = "Active"
					switchMapTemplate = [PSCustomObject]@{

						switchMapEntryTemplates = New-Object System.Collections.ArrayList

					}

				}

			}

			'SwitchLogicalLocation'
			{

				Return [PSCustomObject]@{

					logicalLocation = [PSCustomObject]@{

						locationEntries = New-Object System.Collections.ArrayList
						
					};
					permittedSwitchTypeUri = $null
				}

			}
			
			'ScopeMemberUpdate'
			{

				Return [PSCustomObject]@{

					type                = "ScopeV2";
					addedResourceUris   = New-Object System.Collections.ArrayList;
					removedResourceUris = New-Object System.Collections.ArrayList
								
				}

			}

			'EulaStatus'
			{
			
				Return [PSCustomObject]@{

					EulaAccepted         = $false;
					SupportAccessEnabled = $false

				}
				
			}  
			
			'EnclosureGroupPreview'
			{

				Return [PSCustomObject]@{

					hostname = $null;
					username = $null;
					password = $null;
					logicalInterconnectGroupNeeded = $true;
					ligPrefix = $null

				}

			}

			'FCZone'
			{

				Return [PSCustomObject]@{
				
					Name = $null;
					State = $null;
					Status = $null;
					ManagedSan = $null;
					Members = New-Object System.Collections.ArrayList;
					Created = $null;
					Modified = $null;
					ApplianceConnection = $null	
				
				}

			}

			'FCAlias'
			{

				Return [PSCustomObject]@{
				
					Name = $null;
					WWN = $null;
				
				}

			}

			'UpdateUserPassword'
			{

				Return [PSCustomObject]@{

					type            = 'UserAndRoles';
					currentPassword = $null;
					password        = $null;
					userName        = $Null
				}

			}

			'VCMigratorReport'
			{

				Return [PSCustomObject]@{

					apiVcMigrationReport = @{};
					issueCount           = [int]$null;
					migrationState       = [String]$Null;
					VcemManaged          = [Bool]$False;
					outReport            = New-Object System.Collections.ArrayList

				}

			}

			'EnclosureRefresh'
			{

				Return [PSCustomObject]@{ 

					refreshState        = "RefreshPending"; 
					refreshForceOptions = $null 
				}

			}

			'EnclosureRefreshForceOptions'
			{

				Return [PSCustomObject]@{

					address  = $null;
					username = $null;
					password = $null

				}

			}

			'AutoBackupConfig'
			{

				Return [PSCustomObject]@{

					remoteServerName      = $null;
					remoteServerDir       = '';
					remoteServerPublicKey = $null;
					userName              = $null;
					password              = $null;
					enabled               = $true;
					protocol              = 'SCP';
					scheduleInterval      = 'NONE';
					scheduleDays          = New-Object System.Collections.ArrayList
					scheduleTime          = $null;
					eTag                  = $null

				}     

			}

			'DirectoryGroupCredentials'
			{

				Return [PSCustomObject]@{

					userName = $null;
					password = $null

				}

			}

			'ApplianceTimeLocale'
			{

				Return [PSCustomObject]@{

					type            = 'TimeAndLocale';
					locale          = $null;
					timezone        = 'UTC';
					ntpServers      = New-Object System.Collections.ArrayList
					pollingInterval = $null;

				}

			}

			'RemoteSupportConfig'
			{

				Return [PSCustomObject]@{

					type                = 'Configuration';
					eTag                = $null;
					enableRemoteSupport = $false;
					companyName         = $null;
					marketingOptIn      = $false

				}

			}

			'RemoteSupportContact'
			{

				Return [PSCustomObject]@{

					type           = 'Contact';
					default        = $false;
					alternatePhone = $null;
					email          = $null;
					firstName      = $null;
					lastName       = $null;
					language       = $null;
					notes          = $null;
					primaryPhone   = $null

				}

			}

			'RemoteSupportSite'
			{

				Return [PSCustomObject]@{

					type           = 'Site';
					name           = 'DEFAULT SITE'
					default        = $true;
					city           = $null;
					postalCode     = $null;
					provinceState  = $null;
					streetAddress1 = $null;
					streetAddress2 = $null;
					countryCode    = $null;
					timeZone       = $null

				}

			}

			'SnmpConfig'
			{

				Return [PSCustomObject]@{

					type              = 'snmp-configuration'
					readCommunity     = 'public';
					enabled           = $true;
					systemContact     = $null;
					v3Enabled         = $false;
					snmpUsers         = New-Object System.Collections.ArrayList;
					snmpAccess        = New-Object System.Collections.ArrayList;
					trapDestinations  = New-Object System.Collections.ArrayList

				}
			
			}

			'SnmpTrapDestination'
			{

				Return [PSCustomObject]@{

					trapDestination    = $null;
					communityString    = $null;
					trapFormat         = $null;
					trapSeverities     = New-Object System.Collections.ArrayList;
					vcmTrapCategories  = New-Object System.Collections.ArrayList;
					enetTrapCategories = New-Object System.Collections.ArrayList;
					fcTrapCategories   = New-Object System.Collections.ArrayList;
					userName           = $null;
					inform             = $true;
					engineId           = $null;
					port               = '162';

				}

			}

			'PatchOperation'
			{

				Return [PSCustomObject]@{

					op    = $null;
					path  = $null;
					value = $null

				}

			}

			'IPv4Subnet'
			{

				Return [PSCustomObject]@{

					type           = 'Subnet';
					category       = 'id-range-IPv4-subnet';
					name           = $null;
					networkId      = $null;
					subnetmask     = $null;
					gateway        = $null;
					domain         = $null;
					dnsServers     = New-Object System.Collections.ArrayList;

				}

			}

			'LogicalEnclosure'
			{

				Return [PSCustomObject] @{ 
					
					name                 = $null;
					enclosureUris        = New-Object System.Collections.ArrayList;
					enclosureGroupUri    = $null;
					firmwareBaselineUri  = $null;
					forceInstallFirmware = $false;
					initialScopeUris     = New-Object System.Collections.ArrayList

				}

			}

			'InterconnectMapEntryTemplate'
			{

				Return [PSCustomObject] @{
						
					# LogicalDownlinkUri           = $null;
					permittedInterconnectTypeUri = $null;
					enclosureIndex               = $null;
					logicalLocation = [PSCustomObject]@{

						locationEntries = New-Object System.Collections.ArrayList

					}

				}

			}

			'InterconnectMapEntryTemplate'
			{

				Return [PSCustomObject] @{
						
					logicalDownlinkUri           = $null;
					permittedInterconnectTypeUri = $null;
					enclosureIndex               = $null;
					logicalLocation = [PSCustomObject]@{

						locationEntries = New-Object System.Collections.ArrayList

					}

				}

			}

			'LocationEntry'
			{

				Return [PSCustomObject]@{

					relativeValue = 1;
					type          = $Null

				}

			}

			'LoginMessageObject'
			{

				Return [PSCustomObject]@{

					Message             = $null;
					Acknowledgment      = $null;
					ApplianceConnection = $null

				}

			}

			'ConvertSnapshotToVol'
			{

				Return [PSCustomObject]@{

					properties           = [PSCustomObject] @{

						name             = $null;
						description      = $null;
						provisioningType = 'Thin';
						storagePool      = $null;
						snapshotPool     = $null;
						isShareable      = $false

					};
					snapshotUri          = $null;
					templateUri          = $null;
					isPermanent          = $true;
				  
				}

			}

			'VolSnapshot'
			{

				Return [PSCustomObject]@{

					name        = '{volumeName}_{timestamp}';
					description = $null

				}

			}

			'LogicalInterconnectBaseline'
			{

				Return [PsCustomObject]@{ 
			
					command                 = 'Update'; 
					ethernetActivationType  = 'OddEven';
					ethernetActivationDelay = 5;
					fcActivationType        = 'OddEven';
					fcActivationDelay       = 5;
					sppUri                  = $null; 
					force                   = $false
		
				}

			}

			'StoragePath'
			{

				Return [PSCustomObject]@{

					targetSelector = "Auto";
					targets        = New-Object System.Collections.ArrayList;
					connectionId   = 1;
					isEnabled      = $true

				}

			}

			'LicenseKey'
			{

				Return [PsCustomObject] @{

					type = "LicenseV500";
					key  = $null

				}

			}

			'UnmanagedDevice'
			{

				Return [PSCustomObject]@{ 
				
					name           = [string]$null; 
					model          = [string]$null; 
					height         = [int]1; 
					mac            = [string]$null;
					ipv4Address    = [string]$null;
					ipv6Address    = [string]$null;
					maxPwrConsumed = [int]100 
				
				}

			}

			'RabbitmqCertReq'
			{

				Return [PSCustomObject] @{
		
					commonName = 'default';
					type       = 'RabbitMqClientCertV2'
			
				}

			}

			'AuthLoginCredential'
			{

				Return [PSCustomObject] @{
		
					userName        = $null;
					password        = $null;
					authLoginDomain = $null
			
				}

			}

			'DownloadFileStatus'
			{

				Return [PSCustomObject]@{

					status              = $null;
					file                = $null;
					ApplianceConnection = $null

				}

			}

			'GlobalSetting'
			{

				Return [PSCustomObject]@{
					
					type  = "SettingV2"; 
					name  = $null; 
					value = $null
				
				}

			}

			'StorageVolumeTemplate'
			{

				Return [PSCustomObject]@{
					
					name             = $null;
					description      = $null;
					rootTemplateUri  = $null;
					initialScopeUris = New-Object System.Collections.ArrayList;
					properties       = $null

				}

			}

			'CustomBaselineRestore'
			{

				Return [PSCustomObject]@{

					baselineUri        = $null;
					hotfixUris         = New-Object System.Collections.ArrayList;
					customBaselineName = $null

				}

			}

			'SmtpConfig'
			{

				Return [PSCustomObject]@{
		
					type               = "EmailNotificationV3";
					senderEmailAddress = $null;
					password           = $null;
					smtpServer         = $null;
					smtpPort           = 25;
					smtpProtocol       = 'TLS';
					alertEmailDisabled = $false;
					alertEmailFilters  = New-Object System.Collections.ArrayList
				
				}

			}

			'TestSmtpConfig'
			{

				Return [PSCustomObject]@{
		
					type            = "Email";
					subject         = $null;
					htmlMessageBody = $null;
					textMessageBody = $null;
					toAddress       = New-Object System.Collections.ArrayList
				
				}

			}

			'UpdateAlert'
			{

				Return [PSCustomObject] @{ 
			
					alertState     = $null;
					assignedToUser = $null;
					notes          = $null;
					eTag           = $null
				
				} 

			}

			'SelfSignedCert'
			{
			
				Return [PSCustomObject]@{

					type               = "CertificateDtoV3";
					country            =  $null;
					state              =  $null;
					locality           =  $null;
					organization       =  $null;
					commonName         =  $null;
					organizationalUnit =  $null;
					alternativeName    =  $null;
					contactPerson      =  $null;
					email              =  $null;
					surname            =  $null;
					givenName          =  $null;
					initials           =  $null;
					dnQualifier        =  $null

				}	
			
			}

			'ApplianceCSR'
			{

				Return [PSCustomObject]@{

					type               = "CertificateSigningRequest";
					country            = $null;
					state              = $null;
					locality           = $null;
					organization       = $null;
					commonName         = $null;
					organizationalUnit = $null;
					alternativeName    = $null;
					contactPerson      = $null;
					email              = $null;
					surname            = $null;
					givenName          = $null;
					initials           = $null;
					dnQualifier        = $null;
					unstructuredName   = $null;
					challengePassword  = $null;
					cnsaCertRequested  = $false

				}	

			}

			'AuthDirectory'
			{

				Return [PSCustomObject]@{
					
					type                 = 'LoginDomainConfigV600';
					directoryBindingType = $LdapDirectoryAccountBindTypeEnum['USERACCOUNT'];
					authnType            = "CREDENTIAL";
					authProtocol         = 'AD';
					baseDN               = $null;
					orgUnits             = New-Object System.Collections.ArrayList
					userNamingAttribute  = 'UID';
					name                 = $null;
					credential           = [PSCustomObject]@{
						
						userName = $null; 
						password = $null
					
					};
					directoryServers    = New-Object System.Collections.ArrayList;

				}

			}

			'DirectoryGroup'
			{

				Return [PSCustomObject]@{

					type                     = 'LoginDomainGroupCredentials';
					group2PermissionPerGroup = [PSCustomObject]@{
					
						type        = 'LoginDomainGroupPermission';
						loginDomain = $null;
						egroup      = $null;
						permissions = New-Object System.Collections.ArrayList;

					}
					credentials = NewObject -DirectoryGroupCredentials

				}

			}

			'DirectoryGroupPermissions'
			{

				Return [PSCustomObject]@{
					
					roleName = $null;
					scopeUri = $null

				}

			}

			'AuthDirectoryServer'
			{

				Return [PSCustomObject]@{

					type                                 = 'LoginDomainDirectoryServerInfoDto'
					directoryServerCertificateStatus     = "";
					directoryServerCertificateBase64Data = "";
					serverStatus                         = "";
					directoryServerIpAddress             = $null;
					directoryServerSSLPortNumber         = "636";

				}

			}

			'IPIDPoolRange'
			{

				Return [PsCustomObject]@{ 

					type          = 'Range'; 
					rangeCategory = 'Custom';
					name          = $null;
					enabled       = $true;
					startAddress  = $null; 
					endAddress    = $null;
					subnetUri     = $null

				}

			}

			'IDPoolRange'
			{

				Return [PsCustomObject]@{ 

					type          = 'Range'; 
					rangeCategory = 'Custom';
					name          = $null;
					enabled       = $true;
					startAddress  = $null; 
					endAddress    = $null

				}

			}

			'UserAccount'
			{

				Return [PsCustomObject]@{

					type         = "UserAndPermissions";
					userName     = $null; 
					fullName     = $null; 
					password     = $null; 
					emailAddress = $emailAddress; 
					officePhone  = $null; 
					mobilePhone  = $null; 
					enabled      = $True;
					permissions  = New-Object System.Collections.ArrayList

				}

			}

			'PowerDeliveryDeviceAdd'
			{

				Return [PSCustomObject]@{

					hostname = $null;
					username = $null;
					password = $null;
					force    = $null

				}

			}
			
			'ApplianceDebug'
			{

				Return [PSCustomObject]@{

					scope      = $null;
					loggerName = $null;
					level      = $null

				}

			}

			'AlertFilter'
			{

				Return [PSCustomObject]@{

					filterName      = $null;
					disabled        = $False;
					filter          = $null;
					displayFilter   = $null;
					userQueryFilter = $null;
					emails          = $null;
					scopeQuery      = $null 

				}

			}

			'ServerProfile'
			{

				Return [PSCustomObject]@{

					type                  = $ServerProfileType; 
					name                  = $null; 
					description           = $null; 
					affinity              = $null;
					hideUnusedFlexNics    = $true;
					initialScopeUris      = New-Object System.Collections.ArrayList;
					bios                  = [PSCustomObject]@{

						manageBios         = $false;
						overriddenSettings = $null

					}; 
					firmware                 = [PSCustomObject]@{

						manageFirmware           = $false;
						firmwareBaselineUri      = $null;
						forceInstallFirmware     = $false;
						firmwareInstallType      = 'FirmwareAndOSDrivers';
						firmwareActivationType   = 'Immediate';
						firmwareScheduleDateTime = $null
							
					};
					boot           = [PSCustomObject]@{
					   
						manageBoot = $false; 
						order      = New-Object System.Collections.ArrayList
						   
					};
					bootMode                 = $null;
					localStorage             = [PSCustomObject]@{

						sasLogicalJBODs = New-Object System.Collections.ArrayList; 
						controllers     = New-Object System.Collections.ArrayList

					}
					serialNumberType         = 'Virtual'; 
					macType                  = 'Virtual';
					wwnType                  = 'Virtual';
					connectionSettings       = [PSCustomObject]@{
						connections              = New-Object System.Collections.ArrayList;
					}
					serialNumber             = $null;
					iscsiInitiatorNameType   = 'AutoGenerated'
					serverHardwareUri        = $null;
					serverHardwareTypeUri    = $null;
					serverProfileTemplateUri = $null;
					enclosureBay             = $null;
					enclosureGroupUri        = $null;
					enclosureUri             = $null;
					sanStorage               = $null;
					uuid                     = $null;
				}

			}

			'ServerProfileTemplate'
			{

				Return [PSCustomObject]@{
					
					type                     = $ServerProfileTemplateType; 
					serverProfileDescription = $null;
					serverHardwareTypeUri    = $null;
					enclosureGroupUri        = $null;
					serialNumberType         = 'Virtual'; 
					macType                  = 'Virtual';
					wwnType                  = 'Virtual';
					name                     = $null; 
					description              = $null; 
					affinity                 = $null;
					initialScopeUris         = New-Object System.Collections.ArrayList;
					connectionSettings       = @{

						connections              = New-Object System.Collections.ArrayList;
						manageConnections        = $true

					}
					
					boot                     = [PSCustomObject]@{
							   
						manageBoot = $true; 
						order      = New-Object System.Collections.ArrayList
								   
					};
					bootMode                 = $null;
					firmware                 = [PSCustomObject]@{

						manageFirmware         = $false;
						firmwareBaselineUri    = $null;
						forceInstallFirmware   = $false;
						firmwareInstallType    = 'FirmwareAndOSDrivers';
						firmwareActivationType = 'Immediate'
							
					};
					bios                     = [PSCustomObject]@{

						manageBios         = $false;
						overriddenSettings = New-Object System.Collections.ArrayList

					}; 
					hideUnusedFlexNics       = $true;
					iscsiInitiatorNameType   = "AutoGenerated";
					localStorage             = [PSCustomObject]@{

						sasLogicalJBODs = New-Object System.Collections.ArrayList; 
						controllers     = New-Object System.Collections.ArrayList

					}
					sanStorage               = $null;

				}

			} 

			'ServerProfileTemplateLocalStorage'
			{

				Return [PSCustomObject]@{

					slotNumber          = '0';
					managed             = $true;
					mode                = 'RAID'
					initialize          = $false;
					logicalDrives       = New-Object System.Collections.ArrayList

				}

			}

			'ServerProfileLocalStorageController'
			{

				Return [PSCustomObject]@{

					deviceSlot          = 'Embedded';
					importConfiguration = $false;
					mode                = 'RAID'
					initialize          = $false;
					driveWriteCache     = "Unmanaged";
					logicalDrives       = New-Object System.Collections.ArrayList

				}

			}

			'ServerProfileLocalStorageLogicalDrive'
			{

				Return [PSCustomObject]@{ 

					name              = $null;
					bootable          = $false;
					raidLevel         = $null;
					numPhysicalDrives = $null;
					driveTechnology   = $null;
					sasLogicalJBODId  = $null;
					accelerator       = "Unmanaged"
				
				}

			}

			'ServerProfileSasLogicalJBOD'
			{

				Return [PSCustomObject]@{

					id                = 1;
					deviceSlot        = $null;
					name              = $null
					numPhysicalDrives = 1;
					driveMinSizeGB    = 0;
					driveMaxSizeGB    = 0;
					driveTechnology   = $null;
					eraseData         = $false

				}

			}

			'EnclosureImport'
			{

				Return [PSCustomObject]@{

					hostname             = $null;
					username             = $null;
					password             = $null;
					licensingIntent      = 'OneView';
					force                = $false;
					enclosureGroupUri    = $null;
					firmwareBaselineUri  = $null;
					forceInstallFirmware = $false;
					updateFirmwareOn     = $null;
					state                = $null;
					initialScopeUris     = New-Object System.Collections.ArrayList
				
				}

			}

			'ServerImport'
			{

				Return [PSCustomObject]@{

					hostname             = $null;
					username             = $null;
					password             = $null;
					force                = $false;
					licensingIntent      = 'OneView';
					configurationState   = $null;
					initialScopeUris     = New-Object System.Collections.ArrayList
				
				}

			}

			'StorageSystemCredentials'
			{

				Return [PSCustomObject]@{
					
					hostname = $null; 
					username = $null; 
					password = $null;
					family   = $null
				
				}

			}

			'StorageSystemManagedPort'
			{

				Return [PSCustomObject]@{

					type                = "StorageTargetPortV4"; 
					portName            = $null; 
					name                = $null;
					expectedNetworkUri  = $null; 
					expectedNetworkName = $null;
					actualNetworkUri    = $null; 
					actualNetworkSanUri = $null;
					portWwn             = $null; 
					groupName           = 'Auto'; 
					label               = $null;
					protocolType       = 'FC'

				}

			}

			'StorageVolume'
			{

				Return [PSCustomObject]@{

					properties = [PSCustomObject]@{};
					templateUri = $null;
					isPermanent = $true;
					initialScopeUris = New-Object System.Collections.ArrayList

				}

			}

			'StoreVirtualStorageVolume'
			{

				Return [PSCustomObject]@{

					properties = @{
						name                          = $null;
						description                   = $null;
						storagePool                   = $null;
						size                          = 107374182400;
						provisioningType              = "Thin";
						isShareable                   = $false;
						dataProtectionLevel           = $null
						isAdaptiveOptimizationEnabled = $false
					};
                    templateUri = $null; ;
                    isPermanent = $true;
					initialScopeUris = New-Object System.Collections.ArrayList

				}

			}

			'ServerProfileStorageVolume'
			{

				Return [PsCustomObject]@{
			
					id                     = $null;
					lun                    = $null;
					volumeUri              = $null;
					volumeStoragePoolUri   = $null;
					volumeStorageSystemUri = $null;
					lunType                = 'Auto';
					storagePaths           = New-Object System.Collections.ArrayList;
					bootVolumePriority     = 'NotBootable';
					ApplianceConnection    = $null;

				}   

			}

			'AddStorageVolume'
			{

				Return [PSCustomObject]@{

					description      = $null;
					deviceVolumeName = $null;
					isShareable      = $false;
					name             = $null;
					storageSystemUri = $null;
					initialScopeUris = New-Object System.Collections.ArrayList

				}

			}

			'EphemeralStorageVolume'
			{

				Return [PsCustomObject]@{
			
					id                     = 1
					volumeUri              = $null;
					volumeStorageSystemUri = $null;
					volume                 = [PSCustomObject]@{
						properties       = $null
						templateUri      = $null;
						isPermanent      = $true;
						initialScopeUris = $null
					};
					bootVolumePriority     = 'NotBootable';
					lunType                = 'Auto';
					lun                    = $null;
					ApplianceConnection    = $null;
					storagePaths           = New-Object System.Collections.ArrayList

				}

			}

			'StoreVirtualEphemeralVolumeProperties'
			{

				Return [PSCustomObject]@{
					name                          = $null;
					description                   = $null;
					storagePool                   = $null;
					provisioningType              = 'Thin';
					size                          = '10737418240';
					isShareable                   = $false;
					dataProtectionLevel           = $null;
					isAdaptiveOptimizationEnabled = $false
				}

			}

			'StoreServeEphemeralVolumeProperties'
			{

				Return [PSCustomObject]@{
					name             = $null;
					description      = $null;
					storagePool      = $null;
					provisioningType = 'Thin';
					size             = '10737418240';
					isShareable      = $false;
					snapshotPool     = $null
				}

			}

			'ServerProfileEthernetConnection'
			{

				Return [PSCustomObject]@{
			
					id                  = 1;
					functionType        = 'Ethernet';
					name                = $null;
					portId              = $null; 
					networkUri          = $null; 
					requestedMbps       = 2000; 
					boot                = $null;
					macType             = 'Virtual';
					mac		            = $null;
					requestedVFs        = '0';
					lagName             = $null;
					ApplianceConnection = $null

				}

			}

			'ServerProfileIscsiConnection'
			{

				Return [PSCustomObject]@{
			
					id                  = 1;
					functionType        = 'Ethernet';
					name                = $null;
					portId              = $null; 
					networkUri          = $null; 
					requestedMbps       = 2000; 
					boot                = $null;
					macType             = 'Virtual';
					mac		            = $null;
					ipv4                = $null;
					lagName             = $null;
					ApplianceConnection = $null

				}

			}

			'ServerProfileFCConnection'
			{

				Return [PSCustomObject]@{
			
					id                  = 1;
					functionType        = 'FibreChannel';
					name                = $null;
					portId              = $null; 
					networkUri          = $null; 
					requestedMbps       = 2000; 
					boot                = $null;
					macType             = 'Virtual';
					mac		            = $null;
					wwpnType            = 'Virtual';
					wwnn	            = $null;
					wwpn	            = $null;
					ApplianceConnection = $null

				}

			}

			'ServerProfileEthBootableConnection'
			{

				Return [PSCustomObject]@{

					priority         = 'NotBootable';
					ethernetBootType = "PXE";
					iscsi            = $null

				}

			}

			'ServerProfileEthBootableConnectionWithTargets'
			{

				Return [PSCustomObject]@{

					priority         = 'NotBootable';
					targets          = New-Object System.Collections.ArrayList;
					bootVolumeSource = 'AdapterBIOS';
					ethernetBootType = "PXE";
					iscsi            = $null

				}

			}

			'ServerProfileIscsiBootableConnectionWithTargets'
			{

				Return [PSCustomObject]@{

					priority         = 'NotBootable';
					targets          = New-Object System.Collections.ArrayList;
					bootVolumeSource = 'AdapterBIOS';
					iscsi            = $null

				}

			}

			'ServerProfileFcBootableConnection'
			{

				Return [PSCustomObject]@{

					priority         = 'NotBootable';
					targets          = New-Object System.Collections.ArrayList;
					bootVolumeSource = 'AdapterBIOS'

				}

			}

			'ServerProfileConnectionFcBootTarget'
			{

				Return [PSCustomObject]@{

					arrayWwpn = $null;
					lun       = $null

				}

			}

			'IscsiBootEntry'
			{

				Return [PSCustomObject]@{
						
					initiatorNameSource  = "ProfileInitiatorName";
					firstBootTargetIp    = $null;
					firstBootTargetPort  = $null;
					secondBootTargetIp   = $null;
					secondBootTargetPort = $null;
					chapLevel            = $null;
					initiatorName        = $null;
					bootTargetName       = $null;
					bootTargetLun        = $null;
					chapName             = $null;
					chapSecret           = $null;
					mutualChapName       = $null;
					mutualChapSecret     = $null

				}

			}

			'IscsiIPv4Configuration'
			{

				Return [PSCustomObject]@{
						
					ipAddress       = $null;
					subnetMask      = $null;
					gateway         = $null;
					ipAddressSource = 'UserDefined'

				}

			}

			'SanManager'
			{

				Return [PSCustomObject]@{
			
					"connectionInfo" = New-Object System.Collections.ArrayList
					
				}

			}

			'SanManagerConnectInfo'
			{

				Return [PSCustomObject]@{
				
					name  = $null;
					Value = $null
				
				}

			}

			'EthernetNetwork'
			{

				Return [pscustomobject]@{
							
					type                = $EthernetNetworkType; 
					vlanId              = 1; 
					ethernetNetworkType = 'Tagged'; 
					purpose             = 'General'; 
					name                = $null; 
					smartLink           = $false;
					privateNetwork      = $false;
					subnetUri           = $null;
					initialScopeUris    = New-Object System.Collections.ArrayList

				}

			}

			'BulkEthernetNetworks'
			{

				Return [pscustomobject]@{

					type           = $EthernetNetworkBulkType; 
					vlanIdRange    = $null; 
					purpose        = 'General'; 
					namePrefix     = $null; 
					smartLink      = $false; 
					privateNetwork = $false;
					bandwidth      = [PSCustomObject]@{
									
						typicalBandwidth = 1;
						maximumBandwidth = 10000
									
					};
					initialScopeUris    = New-Object System.Collections.ArrayList

				}

			}

			'FCNetwork'
			{

				[pscustomobject]@{

					type                    = $FCNetworkType; 
					name                    = $Name; 
					linkStabilityTime       = 30; 
					autoLoginRedistribution = $true; 
					fabricType              = 'FabricAttach'; 
					connectionTemplateUri   = $null;
					managedSanUri           = $null;
					initialScopeUris        = New-Object System.Collections.ArrayList
						
				}

			}

			'FCoENetwork'
			{

				Return [pscustomobject]@{
						
					type                  = $FCoENetworkType; 
					name                  = $null; 
					vlanId                = 1; 
					connectionTemplateUri = $null;
					managedSanUri         = $null;
					initialScopeUris      = New-Object System.Collections.ArrayList

				}
				
			}

			'NetworkSet'
			{

				Return [PSCustomObject] @{

					type             = $NetworkSetType; 
					name             = $null; 
					networkUris      = New-Object System.Collections.ArrayList; 
					nativeNetworkUri = $null;
					initialScopeUris = New-Object System.Collections.ArrayList
				
				}

			}

			'SynergyEnclosureGroup'
			{

				Return [PSCustomObject]@{

					name                        = $null;
					interconnectBayMappings     = New-Object System.Collections.ArrayList;
					configurationScript         = $null;
					powerMode                   = 'RedundantPowerFeed';
					ipAddressingMode            = $null;
					ipRangeUris                 = New-Object System.Collections.ArrayList;
					enclosureCount              = 1;
					osDeploymentSettings        = $null;
					initialScopeUris            = New-Object System.Collections.ArrayList;

				}

			}

			'EnclosureGroup'
			{

				Return [PSCustomObject]@{

					name                        = $null;
					interconnectBayMappings     = New-Object System.Collections.ArrayList;
					configurationScript         = $null;
					powerMode                   = 'RedundantPowerFeed';
					enclosureCount              = 1;
					initialScopeUris            = New-Object System.Collections.ArrayList;
					ambientTemperatureMode      = 'Standard'

				}

			}

			'DeploymentModeSettings'
			{

				Return [PSCustomObject]@{

					deploymentModeSettings = $null;
					manageOSDeployment     = $false

				}

			}

			'EnclosureGroupI3SDeploymentSettings'
			{

				Return [PSCustomObject]@{

					deploymentMode       = 'None';
					deploymentNetworkUri = $null

				}

			}

			'InterconnectBayMapping'
			{

				Return [PSCustomObject]@{
					
					enclosureIndex              = 1;
					interconnectBay             = 1; 
					logicalInterconnectGroupUri = $null
				
				}

			}

			'ApplianceVersion'
			{

				Return [PSCustomObject]@{

					applianceName    = $null;
					softwareVersion  = $null; 
					major            = $null;
					minor            = $null;
					xapiVersion      = $null;
					modelNumber      = $null

				}

			}

			'AllApiResponse'
			{

				Return [PSCustomObject]@{

					type        = [string]$null;
					nextPageUri = [string]$null;
					start       = [int]0;
					prevPageUri = [string]$null;
					total       = [int]0;
					count       = [int]0;
					members     = New-Object System.Collections.ArrayList;
					eTag        = [string]$null;
					created     = [string]$null;
					modified    = [string]$null;
					category    = [string]$null;
					uri         = [string]$null

				}

			}

			# Default LIG Object
			"C7KLIG"
			{
			
				Return [PSCustomObject]@{
					name                    = $Null;
					uplinkSets              = New-Object System.Collections.ArrayList; 
					interconnectMapTemplate = [PSCustomObject]@{
						
						interconnectMapEntryTemplates = New-Object System.Collections.ArrayList};

					internalNetworkUris     = New-Object System.Collections.ArrayList; 
					ethernetSettings = [PSCustomObject]@{

						type                        = "EthernetInterconnectSettingsV5";
						enableIgmpSnooping          = $false;
						igmpIdleTimeoutInterval     = 260; 
						enableFastMacCacheFailover  = $true;
						macRefreshInterval          = 5;
						enableNetworkLoopProtection = $false;
						enablePauseFloodProtection  = $false;
						enableRichTLV               = $false;
						enableTaggedLldp            = $false
						
					};
					snmpConfiguration       = $Null;
					qosConfiguration        = [PSCustomObject]@{
						
						type                     = "qos-aggregated-configuration";
						activeQosConfig          = $Null;
						inactiveFCoEQosConfig    = $null;
						inactiveNonFCoEQosConfig = $null

							
					};
					stackingMode            = "Enclosure";
					enclosureType           = "C7000";
					type                    = $LogicalInterconnectGroupType

				}

			}

			"SELIG"
			{
			
				Return [PSCustomObject]@{
					type                    = $LogicalInterconnectGroupType
					name                    = $Null;
					uplinkSets              = New-Object System.Collections.ArrayList; 
					interconnectMapTemplate = [PSCustomObject]@{
						interconnectMapEntryTemplates = New-Object System.Collections.ArrayList
					};
					internalNetworkUris     = New-Object System.Collections.ArrayList; 
					ethernetSettings = [PSCustomObject]@{

						type                        = "EthernetInterconnectSettingsV5";
						enableIgmpSnooping          = $false;
						igmpIdleTimeoutInterval     = 260; 
						enableFastMacCacheFailover  = $true;
						macRefreshInterval          = 5;
						enableNetworkLoopProtection = $false;
						enablePauseFloodProtection  = $false;
						enableRichTLV               = $false;
						enableTaggedLldp            = $false
						
					};
					snmpConfiguration       = $Null;
					qosConfiguration        = [PSCustomObject]@{
						
						type                     = "qos-aggregated-configuration";
						activeQosConfig          = $Null;
						inactiveFCoEQosConfig    = $null;
						inactiveNonFCoEQosConfig = $null

							
					};
					enclosureType      = 'SY12000';
					enclosureIndexes   = New-Object System.Collections.ArrayList;
					interconnectBaySet = 1;
					redundancyType     = 'Redundant'
					
				}

			}

			"SESASLIG"
			{
			
				Return [PSCustomObject]@{
					type                    = "sas-logical-interconnect-groupV2"
					name                    = $Null;
					interconnectMapTemplate = [PSCustomObject]@{
						
						interconnectMapEntryTemplates = New-Object System.Collections.ArrayList};

					enclosureType      = 'SY12000';
					enclosureIndexes   = @(1);
					interconnectBaySet = 1
					
				}

			}
			
			# Default qosConfiguration Object for LIG
			"QosConfiguration"
			{
				
				Return [PSCustomObject]@{
				
					type                       = "QosConfiguration";
					configType                 = "Passthrough";
					qosTrafficClassifiers      = [System.Collections.ArrayList]@()
					uplinkClassificationType   = $Null; # Leave Null to support default 'Passthrough'
					downlinkClassificationType = $Null; # Leave Null to support default 'Passthrough'
				
				}

			}

			'QosIngressClassMapping'
			{

				Return [PSCustomObject]@{
						
					dot1pClassMapping = New-Object System.Collections.ArrayList;
					dscpClassMapping  = New-Object System.Collections.ArrayList
							
				}

			}

			# Default With FCoE Lossless Traffic Classifiers Object
			"DefaultFCoELosslessQosTrafficClassifiers"
			{
			
				Return @(

					#1
					[PSCustomObject]@{ 
					qosTrafficClass = [PSCustomObject]@{
			
						maxBandwidth     = 100;
						bandwidthShare   = "65";
						egressDot1pValue = 0;
						realTime         = $false;
						className        = "Best effort";
						enabled          = $true;
			
					};
							
					qosClassificationMapping = [PSCustomObject]@{
			
						dot1pClassMapping = [System.Collections.ArrayList]@(1,0);
						dscpClassMapping  = [System.Collections.ArrayList]@(
			
							"DSCP 10, AF11",
							"DSCP 12, AF12",
							"DSCP 14, AF13",
							"DSCP 8, CS1",
							"DSCP 0, CS0"
			
						)
			
					}
			
				},
							
					#2
					[PSCustomObject]@{ 
					qosTrafficClass = [PSCustomObject]@{
			
						maxBandwidth     = 100;
						bandwidthShare   = "0";
						egressDot1pValue = 0;
						realTime         = $false;
						className        = "Class1";
						enabled          = $false;
			
					};
								
					qosClassificationMapping = $null
			
				},
				
					#3
					[PSCustomObject]@{ 
					qosTrafficClass = [PSCustomObject]@{
			
						maxBandwidth     = 100;
						bandwidthShare   = "0";
						egressDot1pValue = 0;
						realTime         = $false;
						className        = "Class2";
						enabled          = $false;
			
					};
								
					qosClassificationMapping = $null
			
				},
				
					#4
					[PSCustomObject]@{ 
					qosTrafficClass = [PSCustomObject]@{
			
						maxBandwidth     = 100;
						bandwidthShare   = "0";
						egressDot1pValue = 0;
						realTime         = $false;
						className        = "Class3";
						enabled          = $false;
			
					};
								
					qosClassificationMapping = $null
			
				},
				
					#5
					[PSCustomObject]@{ 
					qosTrafficClass = [PSCustomObject]@{
			
						maxBandwidth     = 100;
						bandwidthShare   = "0";
						egressDot1pValue = 0;
						realTime         = $false;
						className        = "Class4";
						enabled          = $false;
			
					};
								
					qosClassificationMapping = $null
			
				},
				
					#6
					[PSCustomObject]@{ 
					qosTrafficClass = [PSCustomObject]@{
			
						maxBandwidth     = 100;
						bandwidthShare   = "fcoe";
						egressDot1pValue = 3;
						realTime         = $false;
						className        = "FCoE lossless";
						enabled          = $true;
			
					};					
							
					qosClassificationMapping = [PSCustomObject]@{
			
						dot1pClassMapping = [System.Collections.ArrayList]@(3);
						dscpClassMapping  = [System.Collections.ArrayList]@()
			
					}
			
				},
				
					#7
					[PSCustomObject]@{ 
					qosTrafficClass = [PSCustomObject]@{
			
						maxBandwidth     = 100;
						bandwidthShare   = "25";
						egressDot1pValue = 2;
						realTime         = $false;
						className        = "Medium";
						enabled          = $true;
			
					};
								
					qosClassificationMapping = [PSCustomObject]@{
			
						dot1pClassMapping = [System.Collections.ArrayList]@(4,3,2);
						dscpClassMapping  = [System.Collections.ArrayList]@(
			
							"DSCP 18, AF21",
							"DSCP 20, AF22",
							"DSCP 22, AF23",
							"DSCP 26, AF31",
							"DSCP 28, AF32",
							"DSCP 30, AF33",
							"DSCP 34, AF41",
							"DSCP 36, AF42",
							"DSCP 38, AF43",
							"DSCP 16, CS2",
							"DSCP 24, CS3",
							"DSCP 32, CS4"
			
						)
			
					}
			
				},
				
					#8
					[PSCustomObject]@{ 
					qosTrafficClass = [PSCustomObject]@{
			
						maxBandwidth     = 10;
						bandwidthShare   = "10";
						egressDot1pValue = 5;
						realTime         = $true;
						className        = "Real time";
						enabled          = $true;
			
					};
								
					qosClassificationMapping = [PSCustomObject]@{
			
						dot1pClassMapping = [System.Collections.ArrayList]@(5,6,7);
						dscpClassMapping  = [System.Collections.ArrayList]@(
			
							"DSCP 46, EF",
							"DSCP 40, CS5",
							"DSCP 48, CS6",
							"DSCP 56, CS7"
			
						)
			
					}
			
				}
				
				)

			}

			# Default With No FCoE Lossless Traffic Classifiers Object
			"DefaultNoFCoELosslessQosTrafficClassifiers" 
			{
				
				Return @(

					#1
					[PSCustomObject]@{ 
						qosTrafficClass = [PSCustomObject]@{

							maxBandwidth     = 100;
							bandwidthShare   = "65";
							egressDot1pValue = 0;
							realTime         = $false;
							className        = "Best effort";
							enabled          = $true;

						};
								
						qosClassificationMapping = [PSCustomObject]@{

							dot1pClassMapping = [System.Collections.ArrayList]@(1,0);
							dscpClassMapping  = [System.Collections.ArrayList]@(

								"DSCP 10, AF11",
								"DSCP 12, AF12",
								"DSCP 14, AF13",
								"DSCP 8, CS1",
								"DSCP 0, CS0"

							)

						}

					},
											
					#2
					[PSCustomObject]@{ 
						qosTrafficClass = [PSCustomObject]@{

							maxBandwidth     = 100;
							bandwidthShare   = "0";
							egressDot1pValue = 0;
							realTime         = $false;
							className        = "Class1";
							enabled          = $false;

						};
									
						qosClassificationMapping = $null

					},
								
					#3
					[PSCustomObject]@{ 
						qosTrafficClass = [PSCustomObject]@{

							maxBandwidth     = 100;
							bandwidthShare   = "0";
							egressDot1pValue = 0;
							realTime         = $false;
							className        = "Class2";
							enabled          = $false;

						};
									
						qosClassificationMapping = $null

					},
								
									#4
									[PSCustomObject]@{ 
						qosTrafficClass = [PSCustomObject]@{

							maxBandwidth     = 100;
							bandwidthShare   = "0";
							egressDot1pValue = 0;
							realTime         = $false;
							className        = "Class3";
							enabled          = $false;

						};
									
						qosClassificationMapping = $null

					},
								
					#5
					[PSCustomObject]@{ 
						qosTrafficClass = [PSCustomObject]@{

							maxBandwidth     = 100;
							bandwidthShare   = "0";
							egressDot1pValue = 0;
							realTime         = $false;
							className        = "Class4";
							enabled          = $false;

						};
									
						qosClassificationMapping = $null

					},
								
					#6
					[PSCustomObject]@{ 
						qosTrafficClass = [PSCustomObject]@{

							maxBandwidth     = 100;
							bandwidthShare   = "0";
							egressDot1pValue = 0;
							realTime         = $false;
							className        = "Class5";
							enabled          = $false;

						};					
								
						qosClassificationMapping = $null

					},
								
					#7
					[PSCustomObject]@{ 
						qosTrafficClass = [PSCustomObject]@{

							maxBandwidth     = 100;
							bandwidthShare   = "25";
							egressDot1pValue = 2;
							realTime         = $false;
							className        = "Medium";
							enabled          = $true;

						};
									
						qosClassificationMapping = [PSCustomObject]@{

							dot1pClassMapping = [System.Collections.ArrayList]@(4,3,2);
							dscpClassMapping  = [System.Collections.ArrayList]@(

								"DSCP 18, AF21",
								"DSCP 20, AF22",
								"DSCP 22, AF23",
								"DSCP 26, AF31",
								"DSCP 28, AF32",
								"DSCP 30, AF33",
								"DSCP 34, AF41",
								"DSCP 36, AF42",
								"DSCP 38, AF43",
								"DSCP 16, CS2",
								"DSCP 24, CS3",
								"DSCP 32, CS4"

							)

						}

					},
								
					#8
					[PSCustomObject]@{ 
						qosTrafficClass = [PSCustomObject]@{

							maxBandwidth     = 10;
							bandwidthShare   = "10";
							egressDot1pValue = 5;
							realTime         = $true;
							className        = "Real time";
							enabled          = $true;

						};
									
						qosClassificationMapping = [PSCustomObject]@{

							dot1pClassMapping = [System.Collections.ArrayList]@(5,6,7);
							dscpClassMapping  = [System.Collections.ArrayList]@(

								"DSCP 46, EF",
								"DSCP 40, CS5",
								"DSCP 48, CS6",
								"DSCP 56, CS7"

							)

						}

					}
				
				)

			}

			# Default BestEffort Traffic Class
			"DefaultBestEffortTrafficClass"
			{
				
				Return [PSCustomObject]@{ 

					qosTrafficClass = [PSCustomObject]@{

						maxBandwidth     = 100;
						bandwidthShare   = "65";
						egressDot1pValue = 0;
						realTime         = $false;
						className        = "Best effort";
						enabled          = $true;

					};
								
					qosClassificationMapping = [PSCustomObject]@{

						dot1pClassMapping = [System.Collections.ArrayList]@(1,0);
						dscpClassMapping  = [System.Collections.ArrayList]@(

							"DSCP 10, AF11",
							"DSCP 12, AF12",
							"DSCP 14, AF13",
							"DSCP 8, CS1",
							"DSCP 0, CS0"

						)

					}

				}

			}

			# FCoE Lossless Traffic Class
			"FCoELossLessTrafficClass"
			{

				Return [PSCustomObject]@{ 

					qosTrafficClass = [PSCustomObject]@{
				
						maxBandwidth     = 100;
						bandwidthShare   = "fcoe";
						egressDot1pValue = 3;
						realTime         = $false;
						className        = "FCoE lossless";
						enabled          = $true;
				
					};					
								
					qosClassificationMapping = [PSCustomObject]@{
				
						dot1pClassMapping = [System.Collections.ArrayList]@(3);
						dscpClassMapping  = New-Object System.Collections.ArrayList
				
					}
				
				}

			}
			
			#Basic, not enabled Traffic Class
			"BaseTrafficClass"
			{
				
				Return [PSCustomObject]@{ 
					
					qosTrafficClass = [PSCustomObject]@{
					
						maxBandwidth     = 100;
						bandwidthShare   = "0";
						egressDot1pValue = 0;
						realTime         = $false;
						className        = "Class";
						enabled          = $false;
					
					};
									
					qosClassificationMapping = [PSCustomObject]@{
							
						dot1pClassMapping = New-Object System.Collections.ArrayList;
						dscpClassMapping  = New-Object System.Collections.ArrayList
							
					}

				}

			}

			"Ping"
			{

				Return [PSCustomObject]@{

					type        = "PingDto";
					address     = "example.com";
					noOfPackets = 5

				}

			}

			"liUplinkSetObject"
			{
			
				Return [PSCustomObject]@{

					type                           = "uplink-setV5";
					name                           = $Name; 
					networkUris                    = New-Object System.Collections.ArrayList;
					portConfigInfos                = New-Object System.Collections.ArrayList;
					networkType                    = $null; 
					primaryPortLocation            = $null;
					fcNetworkUris                  = New-Object System.Collections.ArrayList;
					fcoeNetworkUris                = New-Object System.Collections.ArrayList;				
					connectionMode                 = $null; 
					ethernetNetworkType            = $null; 
					lacpTimer                      = 'Short';
					logicalInterconnectUri         = $null;
					manualLoginRedistributionState = 'NotSupported';
					fcMode                         = 'NA'

				}
			
			}

			'ligUplinkSetObject'
			{

				Return [PSCustomObject]@{

					logicalPortConfigInfos = New-Object System.Collections.ArrayList;
					networkUris            = New-Object System.Collections.ArrayList;
					name                   = $null; 
					mode                   = 'Auto'; 
					networkType            = "Ethernet";
					primaryPort            = $null;
					ethernetNetworkType    = $null; 
					lacpTimer              = 'Short';
					fcMode                 = 'NA'

				}

			}

			'UplinkSetLogicalLocation'
			{
				
				Return [PSCustomObject]@{
					
					desiredSpeed    = $null;
					logicalLocation = [PSCustomObject]@{
										
						locationEntries =  New-Object System.Collections.ArrayList
					
					}
					
				}

			}

			'UplinkSetLocation'
			{
				
				Return [PSCustomObject]@{

					desiredSpeed = $null;
					location     = [PSCustomObject]@{
										
						locationEntries = New-Object System.Collections.ArrayList

					}
					
				}

			}

			'UplinkSetLogicalLocationEntry'
			{

				Return [PSCustomObject]@{
											
					type          = $Null;
					relativeValue = 1

				}

			}
				
			'UplinkSetLocationEntry'
			{

				Return [PSCustomObject]@{
											
					type  = $Null;
					value = 1

				}

			}

			'VcMigration'
			{

				Return [PSCustomObject]@{

					enclosureGroupUri           = $Null;
					iloLicenseType              = $Null;
					credentials                 = [PSCustomObject]@{
											
						 oaIpAddress            = $Null;
						 oaUsername             = $Null;
						 oaPassword             = $Null;
						 vcmUsername            = $Null;
						 vcmPassword            = $Null;
						 type                   = "EnclosureCredentials"
											
					};				            
					category                    = "migratable-vc-domains";
					type                        = "MigratableVcDomainV300"

				}

			}

		}

	}

}
