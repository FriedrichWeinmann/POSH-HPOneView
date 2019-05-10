function ConvertTo-HPOVPowerShellScript
{

	# .ExternalHelp HPOneView.420.psm1-help.xml

	[CmdletBinding (DefaultParameterSetName = 'Default')]

	Param 
	(
		
		[Parameter (Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Object]$InputObject,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[System.IO.FileInfo]$Export,

		[Parameter (Mandatory = $false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[Switch]$Append

    )
    
    Begin
    {

        $DoubleQuote    = '"'
        $CRLF           = "`r`n"
        $Delimiter      = "\"   # Delimiter for CSV profile file
        $SepHash        = ";"   # USe for multiple values fields
        $Sep            = ";"
        $hash           = '@'
        $SepChar        = '|'
        $CRLF           = "`r`n"
        $OpenDelim      = "{"
        $CloseDelim     = "}" 
        $OpenArray      = "("
        $CloseArray     = ")"
        $CR             = "`n"
        $Comma          = ','
        $Equal          = '='
        $Dot            = '.'
        $Underscore     = '_'
        $Space          = ' '

        $Syn12K         = 'SY12000' # Synergy enclosure type
        [Hashtable]$LogicalDiskCmdletTypeEnum = @{

			SasHdd  = 'SAS';
            SataHdd = 'SATA';
	    	Sas     = 'SASSSD';
	    	SasSsd  = 'SASSSD';
            SataSsd = 'SATASSD';
            NVMeSsd = 'NVMeSas';
            NVMeHdd = 'NVMeSata'

        }

    }

    Process
    {

        $ExportToFile = $PSBoundParameters['Export']

        $ApplianceConnection = $InputObject.ApplianceConnection

        function Insert-BlankLine
        {

            ""

        }

        Function Get-NamefromUri([string]$uri)
        {

            $name = $null

            if (-not [string]::IsNullOrEmpty($Uri)) 
            { 
                
                Try
                {
                
                    $resource = Send-HPOVRequest -Uri $Uri -ApplianceConnection $ApplianceConnection
                
                }
                
                Catch
                {
                
                    $PSCmdlet.ThrowTerminatingError($_)
                
                }
            
            }

            switch ($resource.category)
            {

                'id-range-IPV4-subnet'
                {

                    $name = $resource.networkId

                }

                'storage-systems'
                {

                    $name = $resource.members.displayName

                }

                default
                {

                    $name = $resource.name

                }

            }

            return $name

        }

        Function Generate-CustomVarCode ([String]$Prefix, [String]$Suffix, [String]$Value)
        {

            if (-not $Prefix.StartsWith("$") -and -not $Prefix.StartsWith("#"))
            {

                $Prefix = '${0}' -f $Prefix

            }

            $VarName = '{0}{1}' -f $Prefix, $Suffix

            Return '{0}{1}= {2}' -f $VarName, [String]::Join('', (1..(28 - $VarName.Length) | % { $Space })), $Value

        }

        Function rebuild-fwISO ($BaselineObj)
        {

            # ----------------------- Rescontruct FW ISO filename
            # When uploading the FW ISO file into OV, all the '.' chars are replaced with "_"
            # so if the ISO filename is:        SPP_2018.06.20180709_for_HPE_Synergy_Z7550-96524.iso
            # OV will show $fw.ISOfilename ---> SPP_2018_06_20180709_for_HPE_Synergy_Z7550-96524.iso
            # 
            # This helper function will try to re-build the original ISO filename

            $newstr = $null

            switch ($BaselineObj.GetType().Fullname)
            {

                'HPOneView.Appliance.Baseline'
                {

                    $arrList = New-Object System.Collections.ArrayList

                    $StrArray = $BaselineObj.ResourceId.Split($Underscore)

                    ForEach ($string in $StrArray)
                    {

                        [void]$arrList.Add($string.Replace($dot, $Underscore))

                    }
                    
                    $newstr = "{0}.iso" -f [String]::Join($Underscore, $arrList.ToArray())                

                }

                'HPOneView.Appliance.BaselineHotfix'
                {

                    $newStr     = $BaselineObj.FwComponents.Filename

                }

                default
                {

                    $newstr = $null

                }

            }

			return $newStr
				
		}
		
		Function DisplayOutput ([System.Collections.ArrayList]$code)
		{

			if ($ExportToFile)
			{

				if (-not $Append)
				{

					[System.IO.File]::WriteAllLines($Export, $code, [System.Text.Encoding]::UTF8)

				}

				else
				{

					[System.IO.File]::AppendAllLines([String]$Export, [string[]]$code.ToArray(), [System.Text.Encoding]::UTF8)

				}

			}

			else
			{

				$code.ToArray()

				Insert-BlankLine

			}

		}

        Function Generate-fwBaseline-Script ($InputObject)
        {

            foreach ($fwBase in $InputObject)
            {

                $scriptCode =  New-Object System.Collections.ArrayList

                # - OV strips the dot from the ISOfilename, so we have to re-construct it
                $filename   = rebuild-fwISO -BaselineObj $fwBase

				[void]$scriptCode.Add(('## ------ Upload baseline "{0}"' -f $filename))
				[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'filename' -Value ('"{0}"' -f $filename)))
				[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'isofolder' -Value ('read-host "Provide the folder location for "{0}"' -f $filename)))
				[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'isofile' -Value 'Join-Path $isofolder $filename'))
				[void]$scriptCode.Add('Add-HPOVBaseline -file $isofile')
				
				DisplayOutput -Code $scriptCode

            }

        }

        Function Generate-proxy-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $proxy          = $InputObject
            $server         = $proxy.Server

            if ($server)
            {

                $protocol       = $proxy.protocol 
                $port           = $proxy.port 
                $username       = $proxy.username 
                $server         = $server 

				[void]$scriptCode.Add('## ------ Configure appliance proxy to "{0}"' -f $server)
                $serverParam    = ' -server $server'
                $portParam      = ' -port $port'
                $credParam      = $null
                $userParam      = $null
                $isHttps        = if ($protocol -eq 'Https') {$true} else {$false}
                $protocolParam  = ' -Https:$isHttps'


                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'server' -Value ('"{0}"' -f $server)))
				[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'port' -Value ('{0}' -f $port)))
			
				if (-not [string]::IsNullOrEmpty($username))
                {

		    		[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'username' -Value ('"{0}"' -f $username)))
		    		[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'password' -Value ('Read-Host -prompt "Enter password for user {0} for proxy server" -AsSecureString' -f $username)))

                    $userParam = ' -Username {0} -Password $password' -f $username

                }

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'isHttps' -Value ('${0}' -f $isHttps.ToString())))
                [void]$scriptCode.Add(('Set-HPOVApplianceProxy -hostname $server{0}{1}{2}' -f $userParam, $portParam, $protocolParam))

                DisplayOutput -Code $scriptCode

            }   

        }
        
        Function Generate-scope-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $s = $InputObject

            $name       = $s.name
            $desc       = $s.description
            $members    = $s.members
        
            $descParam = $null
            $descCode  = $null

            [void]$scriptCode.Add('## ------ Create scope {0}' -f $name)
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $name)))

            if ($desc)
            {

                $descParam  =  ' -description $description'
 
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'description' -Value ('"{0}"' -f $desc)))

            }

            if ($s.Members.Count -gt 0)
            {

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'thisScope' -Value ('New-HPOVScope -Name $name {0}' -f $descParam)))

                [void]$scriptCode.Add(('{0}## ------ Create resources to be included in scope {1}' -f $CR, $name))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'resources' -Value 'New-Object System.Collections.ArrayList'))

                foreach ($m in $members)
                {

                    $scopeMemberCode = $scopeMemberType = $null

                    $m_type = $m.type

                    switch ($m_type) 
                    {

                        'EthernetNetwork'           
                        {

                            $scopeMemberCode = 'Get-HPOVNetwork -Name "{0}" -Type Ethernet' -f $m.name
                            
                        }

                        'FCoENetwork'               
                        {

                            $scopeMemberCode = 'Get-HPOVNetwork -Name "{0}" -Type FCoE' -f $m.name
                        
                        }

                        'FCNetwork'
                        {

                            $scopeMemberCode = 'Get-HPOVNetwork -Name "{0}" -Type FC' -f $m.name
                        
                        }

                        'LogicalInterconnectGroup'  
                        {

                            $scopeMemberCode = 'Get-HPOVLogicalInterconnectGroup -Name "{0}"' -f $m.name

                        }

                        'LogicalInterconnect'
                        {

                            $scopeMemberCode = 'Get-HPOVLogicalInterconnect -Name "{0}"' -f $m.name

                        }

                        'LogicalEnclosure'
                        {

                            $scopeMemberCode = 'Get-HPOVLogicalEnclosure -Name "{0}"' -f $m.name

                        }
                                                    
                        'ServerProfileTemplate'
                        {
                            
                            $scopeMemberCode = 'Get-HPOVServerProfileTemplate -Name "{0}"' -f $m.name
                        
                        }

                        'ServerHardware'
                        {

                            $scopeMemberCode = 'Get-HPOVServer -Name "{0}"' -f $m.name
                        
                        }

                        'StorageVolumeTemplate'
                        {

                            $scopeMemberCode = 'Get-HPOVStorageVolumeTemplate -Name "{0}"' -f $m.name
                                                    
                        }

                        'StorageVolume'
                        {

                            $scopeMemberCode = 'Get-HPOVStorageVolume -Name "{0}"' -f $m.name
                        
                        }

                        'StoragePool'
                        {

                            
                            $scopeMemberCode = 'Get-HPOVStoragePool -Name "{0}"' -f $m.name
                            
                        }

                        'FirmwareBundle'
                        {

                            $scopeMemberCode = 'Get-HPOVbaseline -Name "{0}"' -f $m.name
                                                    
                        }

                        default                     {}

                    }                     

                    [void]$scriptCode.Add('[void]$resources.Add({0})' -f $scopeMemberCode)

                }

                [void]$scriptCode.Add('Add-HPOVResourceToScope -Scope $thisScope -InputObject $resources')
            
            }

            else
            {
            
                [void]$scriptCode.Add('New-HPOVScope -Name $name {0}' -f $descParam)
            
            }

            DisplayOutput -Code $scriptCode

        }

        # Local OneView user accounts, with permissions and SBAC
        Function Generate-User-Script ($InputObject)
        {

            $scriptCode       = New-Object System.Collections.ArrayList
            $scopePermissions = New-Object System.Collections.ArrayList
            $permissionsCode  = New-Object System.Collections.ArrayList

            $User = $InputObject

            $userName     = $User.userName
            $fullName     = $User.fullName
            $desc         = $User.description
            $permissions  = $User.permissions
            $emailAddress = $User.emailAddress
            $officePhone  = $User.officePhone
            $mobilePhone  = $User.mobilePhone
        
            $fullNameParam = $permissionsParam = $emailAddressParam = $officePhoneParam = $mobilePhoneParam = $descParam = $null
            $roleParam     = $scopeParam       = $null

            [void]$scriptCode.Add('# ------ Create user {0}' -f $userName)
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'userName' -Value ('"{0}"' -f $userName)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'password' -Value ('Read-Host -Message "Provide the password for {0}"' -f $userName)))

            if ($userName -ne $fullName)
            {

                [void]$scriptCode.Add('$fullName                   = "{0}"' -f $fullName)
                $fullNameParam = ' -Fullname $fullname'

            }

            if (-not [String]::IsNullOrWhiteSpace($emailAddress))
            {

                [void]$scriptCode.Add('$emailAddress               = "{0}"' -f $emailAddress)
                $emailAddressParam = ' -EmailAddress $emailAddress'

            }

            if (-not [String]::IsNullOrWhiteSpace($officePhone))
            {

                [void]$scriptCode.Add('$officePhone                = "{0}"' -f $officePhone)
                $officePhoneParam = ' -OfficePhone $officePhone'

            }

            if (-not [String]::IsNullOrWhiteSpace($mobilePhone))
            {

                [void]$scriptCode.Add('$mobilePhone                = "{0}"' -f $mobilePhone)
                $mobilePhoneParam = ' -MobilePhone $mobilePhone'

            }

            $n = 1

            ForEach ($permission in $permissions)
            {

                # Roles first, which have no scopeUri value
                $ScopePermission = [PSCustomObject]@{Role = $null; Scope = "All"}

                $ScopePermission.Role = $permission.roleName

                if (-not [String]::IsNullOrWhiteSpace($permission.scopeUri))
                {

                    $ScopeName = Get-NamefromUri $permission.scopeUri

                    $ScopePermission.Scope = '$Scope{0}' -f $n

                    $ScopeRoleVarCode = Generate-CustomVarCode -Prefix "Scope" -Suffix $n -Value ('Get-HPOVScope -Name "{0}"' -f $ScopeName)

                    [void]$scriptCode.Add('{0}' -f $ScopeRoleVarCode)

                    $n++
                
                }

                [void]$scopePermissions.Add($ScopePermission)

            }

            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'permissions' -Value '@('))

            $c = 1

            ForEach ($perm in $scopePermissions)
            {

                $eol = ','

                if ($c -eq $n)
                {

                    $eol = $null

                }

               [void]$scriptCode.Add(('    {0}Role = "{1}"; Scope = {2}{3}{4}' -f '@{', $perm.Role, $perm.Scope, '}', $eol))

               $c++

            }

            [void]$scriptCode.Add(')')

            $permissionsParam = ' -Roles $permissions'

            [void]$scriptCode.Add(('New-HPOVUser -Username $userName -Password $password{0}{1}{2}{3}' -f $fullNameParam, $descParam, $emailAddressParam, $officePhoneParam, $mobilePhoneParam, $permissionsParam))

            DisplayOutput -Code $scriptCode

        }

        # User and Directory Group permissions
        Function Generate-RBAC-Script ($InputObject)
        {

            $scriptCode       = New-Object System.Collections.ArrayList
            $scopePermissions = New-Object System.Collections.ArrayList

            $Group = $InputObject

            $groupName   = $Group.egroup
            $dirName     = $Group.loginDomain
            $permissions = $Group.permissions
        
            [void]$scriptCode.Add('# ------ Create authentication directory group {0}' -f $groupName)
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'groupName' -Value ('"{0}"' -f $groupName)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'dirName' -Value ('"{0}"' -f $dirName)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'credentials' -Value ('Get-Credential -Message "Provide {0} authentication directory username and password"' -f $dirName)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'directory' -Value ('Get-HPOVLdapDirectory -Name $dirName')))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'thisGroup' -Value ('Show-HPOVLdapGroups -Directory $directory -GroupName $groupName -Credential $credentials')))

            $n = 1

            ForEach ($permission in $permissions)
            {

                # Roles first, which have no scopeUri value
                $ScopePermission = [PSCustomObject]@{Role = $null; Scope = "All"}

                $ScopePermission.Role = $permission.roleName

                if (-not [String]::IsNullOrWhiteSpace($permission.scopeUri))
                {

                    $ScopeName = Get-NamefromUri $permission.scopeUri

                    $ScopePermission.Scope = '$Scope{0}' -f $n

                    $ScopeRoleVarCode = Generate-CustomVarCode -Prefix "Scope" -Suffix $n -Value ('Get-HPOVScope -Name "{0}"' -f $ScopeName)

                    [void]$scriptCode.Add(('{0}' -f $ScopeRoleVarCode))

                    $n++
                
                }

                [void]$scopePermissions.Add($ScopePermission)

            }

			[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'permissions' -Value '@('))

            $c = 1

            ForEach ($perm in $scopePermissions)
            {

                $eol = ','

                if ($c -eq $n)
                {

                    $eol = $null

                }

                [void]$scriptCode.Add(('    {0}Role = "{1}"; Scope = {2}{3}{4}' -f '@{', $perm.Role, $perm.Scope, '}', $eol))

                $c++

            }

            [void]$scriptCode.Add(')')

            [void]$scriptCode.Add('New-HPOVLdapGroup -Directory $directory -Credential $credentials -Roles $permissions')

            DisplayOutput -Code $scriptCode

        }

        # Directory authentication, including default auth directory and local login policies
        Function Generate-DirectoryAuthentication-Script ($InputObject)
        {

            $scriptCode       = New-Object System.Collections.ArrayList

            $Username           = $serviceAccountParam = $AuthProtocolParam = $null
            $UsrNameAttribParam = $LdapOUsParam        = $null

            $Directory     = $InputObject
            $Name          = $Directory.name
            $AuthProt      = $Directory.authProtocol
            $UsrNameAttrib = $Directory.userNamingAttribute
            $BaseDN        = $Directory.baseDN
            $OrgUnits      = $Directory.orgUnits
            $DirBindType   = $Directory.directoryBindingType
            $DirUsername   = $Directory.credential.userName
            $Servers       = $Directory.directoryServers

            [void]$scriptCode.Add(('# ------ Create authentication directory {0} ({1})' -f $Name, $BaseDN))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'dirName' -Value ('"{0}"' -f $Name)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'baseDN' -Value ('"{0}"' -f $BaseDN)))

            if ($DirBindType -eq 'SERVICE_ACCOUNT')
            {

                $serviceAccountParam = ' -ServiceAccount'
                $Username = $DirUsername

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'credential' -Value ('Get-Credential -Message "Provide authentication credentials for {0} authentication directory." -Username "{0}"' -f $Username)))

            }

            else
            {
            
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'credential' -Value ('Get-Credential -Message "Provide authentication credentials for {0} authentication directory."' -f $Name)))
            
            }

            if ($AuthProt -ne 'AD')
            {

                $AuthProtocolParam  = ' -OpenLDAP'
                $LdapOUsParam       = ' -OrganizationalUnits $ldapOrgUnits'
                $UsrNameAttribParam = ' -UserNamingAttribute $usrNameAttrib'

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ldapOrgUnits' -Value ('"{0}"' -f $OrgUnits)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'usrNameAttrib' -Value ('"{0}"' -f $UsrNameAttrib)))

            }

            else
            {
            
                $AuthProtocolParam = ' -AD'
            
            }

            $n = 1

            ForEach ($server in $Servers)
            {

                $ServerCode = $ServerNameCode = $ServerPortCode = $ServerCertCode = $null

                $ServerNameCode = ' -Hostname "{0}"' -f $server.directoryServerIpAddress
                $ServerPortCode = ' -SSLPort {0}' -f $server.directoryServerSSLPortNumber
                
                if ($server.directoryServerCertificateBase64Data)
                {

                    [void]$scriptCode.Add('# -------- If you wish to provide the certificate in Base64 format from a file, uncomment the following line')
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '#$certificate' -Value 'Get-ChildItem -Path "C:\Path\to\cert.cer"'))
                    [void]$scriptCode.Add('# -------- Comment out the following line to use the existing certificate value.')
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'certificate' -Value ('"{0}"' -f $BaseDN)))

                    $ServerCertCode = ' -Certificate $certificate -TrustLeafCertificate'

                }                

                $ServerCode = 'New-HPOVServer {0}{1}{2}' -f $ServerNameCode, $ServerPortCode, $ServerCertCode

                $ServerCode = Generate-CustomVarCode -Prefix "Server" -Suffix $n -Value $ServerCode

                [void]$scriptCode.Add(('{0}' -f $ServerCode))

                $n++

            }

            [void]$scriptCode.Add('$servers                    = @(')

            $c = 1

            ForEach ($server in $Servers)
            {

                $eol = ','

                if ($c -eq $n)
                {

                    $eol = $null

                }

                [void]$scriptCode.Add('    $Server{0}' -f $c)

                $c++

            }

            [void]$scriptCode.Add(')')

            [void]$scriptCode.Add(('New-HPOVLdapDirectory -Name $dirName{0}{1}{2} -BaseDN $baseDN -Servers $servers -Credential $credentials' -f $AuthProtocolParam, $LdapOUsParam, $UsrNameAttribParam))

            DisplayOutput -Code $scriptCode

        }

        # ///TODO: OVRS, data collection schedule, Contacts, Default data center, and additional data centers with contacts
        Function Generate-RemoteSupport-Script ($InputObject)
        {

            $scriptCode           = New-Object System.Collections.ArrayList

            $RS                   = $InputObject 
            $companyName          = $RS.companyName
            $marketingOptIn       = $RS.marketingOptIn
            $autoEnableDevices    = $RS.autoEnableDevices
            $insightOnlineEnabled = $RS.InsightOnlineEnabled

        }

        Function Generate-snmp-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $snmp            = $InputObject
            $readCommunity   = $snmp.CommunityString 

            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'readCommunity' -Value ('"{0}"' -f $readCommunity)))
            [void]$scriptCode.Add('Set-HPOVSnmpReadCommunity -Name $readCommunity')

            #Trap destinations
            Try
            {
            
                $trapDestinations = Get-HPOVApplianceTrapDestination -ApplianceConnection $ApplianceConnection
            
            }
            
            Catch
            {
            
                $PSCmdlet.ThrowTerminatingError($_)
            
            }            

            foreach ($t in $trapDestinations)
            {

                $communitystr       = $t.communitystring 
                $destinationAddress = $t.DestinationAddress
                $port               = $t.port
                $type               = $t.type
                                
                $destParam = $formatParam = $communityParam = $portParam = $snmpV3UserParam = $null
                $destCode = $formatCode = $communityCode = $portCode = $null
                
                if ($destinationAddress)
                {
                                        
                    $destParam      = ' -destination $destination'
                    $portParam      = ' -port $Port'
                    $formatParam    = ' -SnmpFormat $type'
                    
                    [void]$scriptCode.Add(("#-- `tGenerating {0} Trap destination object for {1}" -f $type, $destinationAddress))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'destination' -Value ('"{0}"' -f $destinationAddress)))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'port' -Value ('{0}' -f $port)))

                    Switch ($t.GetType().Fullname)
                    {

                        'HPOneView.Appliance.SnmpV1TrapDestination'
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'communitystring' -Value ('"{0}"' -f $communitystr)))

                            $communityParam = ' -Community $communitystring'
                            $type           = "SNMPv1"

                        }

                        'HPOneView.Appliance.SnmpV3TrapDestination'
                        {

                            # This needs to be expanded upon to configure SNMPv3 user
                            Try
                            {
                            
                                $snmpv3User = Get-HPOVSnmpV3user -Name $t.SnmpV3User -ApplianceConnection $ApplianceConnection
                            
                            }
                            
                            Catch
                            {
                            
                                $PSCmdlet.ThrowTerminatingError($_)
                            
                            }

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snmpV3User' -Value ('Get-HPOVSnmpV3user -Name "{0}"' -f $t.SnmpV3User)))
                            $snmpV3UserParam = ' -SnmpV3User $snmpV3User'
                            $type            = "SNMPv3"

                        }                        

                    } 

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'type' -Value ('"{0}"' -f $type)))
                    [void]$scriptCode.Add(('New-HPOVSnmpTrapDestination {0}{1}{2}{3}{4}' -f $destParam, $portParam, $formatParam, $communityParam, $snmpV3UserParam))

                }

            }

            DisplayOutput -Code $scriptCode

        }

        Function Generate-snmpV3User-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $user     = $InputObject
            $userName = $user.userName

            $securityLevelParam = $snmpv3UserPrivProtocolParam = $snmpv3UserAuthProtocolParam = $null
            $authProtocolName = $privProtocolName = $null

            $securityLevelName = ($Snmpv3UserAuthLevelEnum.GetEnumerator() | ? Value -eq $user.securityLevel).Name

            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'userName' -Value ('"{0}"' -f $userName)))
            $userNameParam      = ' -Username $userName'

            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'securityLevel' -Value ('"{0}"' -f $securityLevelName)))
            $securityLevelParam = ' -SecurityLevel $securityLevel'

            switch ($user.securityLevel)
            {

                $Snmpv3UserAuthLevelEnum["AuthOnly"]
                {

                    $authProtocolName = ($SnmpAuthProtocolEnum.GetEnumerator() | ? Value -eq $user.authenticationProtocol).Name

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'authProtocol' -Value ('"{0}"' -f $authProtocolName)))

                    $snmpv3UserAuthProtocolParam = ' -AuthProtocol $authProtocol'

                    if ($authProtocolName -ne 'none')
                    {

                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'AuthPassword' -Value ('Read-Host -prompt "Enter authentication password for SNMPv3 user {0}" -AsSecureString' -f $username)))
                        $snmpv3UserAuthProtocolParam += ' -AuthPassword $authPassword'

                    }

                }

                $Snmpv3UserAuthLevelEnum["AuthAndPriv"]
                {

                    $authProtocolName = ($SnmpAuthProtocolEnum.GetEnumerator() | ? Value -eq $user.authenticationProtocol).Name

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'authProtocol' -Value ('"{0}"' -f $authProtocolName)))

                    $snmpv3UserAuthProtocolParam = ' -AuthProtocol $authProtocol'

                    if ($authProtocolName -ne 'none')
                    {

                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'AuthPassword' -Value ('Read-Host -prompt "Enter authentication password for SNMPv3 user {0}" -AsSecureString' -f $username)))
                        $snmpv3UserAuthProtocolParam += ' -AuthPassword $authPassword'

                    }

                    $privProtocolName = ($ApplianceSnmpV3PrivProtocolEnum.GetEnumerator() | ? Value -eq $user.privacyProtocol).Name

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'privProtocol' -Value ('"{0}"' -f $privProtocolName)))

                    $snmpv3UserPrivProtocolParam = ' -PrivProtocol $privProtocol'

                    if ($authProtoprivProtocolNamecolName -ne 'none')
                    {

                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'PrivPassword' -Value ('Read-Host -prompt "Enter privacy password for SNMPv3 user {0}" -AsSecureString' -f $username)))
                        $snmpv3UserPrivProtocolParam += ' -PrivPassword $PrivPassword'

                    }

                }

            }

            [void]$scriptCode.Add(('New-HPOVSnmpV3User -ApplianceSnmpUser{0}{1}{2}{3}' -f $userNameParam, $securityLevelParam, $snmpv3UserAuthProtocolParam, $snmpv3UserPrivProtocolParam))
            
            DisplayOutput -Code $scriptCode

        }

        Function Generate-smtp-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList
        
            $smtp               = $InputObject

            $Email              = $Smtp.senderEmailAddress
            $Server             = $Smtp.smtpServer
            $Port               = $Smtp.smtpPort
            $ConnectionSecurity = ($SmtpConnectionSecurityEnum.GetEnumerator() | ? Value -eq $Smtp.smtpProtocol).Name

            # Code and Parameters
            if (-not $smtp.alertEmailDisabled -and $smtp.smtpServer)
            {

                [void]$scriptCode.Add('# -------------- Attributes for SMTP alerting')       
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'AlertEmailDisabled' -Value '$False'))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'Email' -Value ('"{0}"' -f $Email)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'Server' -Value ('"{0}"' -f $Server)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'Port' -Value ('{0}' -f $Port)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ConnectionSecurity' -Value ('{0}' -f $ConnectionSecurity)))
                [void]$scriptCode.Add('# Omit the following line to if your SMTP server does not require a password.')
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'Password' -Value 'Read-Host "Please enter a password to connect to smtp Server " -AsSecureString'))
                [void]$scriptCode.Add('Set-HPOVSmtpConfig -SenderEmailAddress $Email -password $Password -Server $Server -Port $Port')
                [void]$scriptCode.Add("")

                if ($smtp.alertEmailFilters.Count -gt 0)
                {

                    ForEach ($filter in ($smtp.alertEmailFilters | Sort filterName))
                    {

                        Insert-BlankLine

                        $ScopeMatchPreferenceParam = $smtpAlertNameParam = $smtpAlertEmailsParam = $null
                        
                        [void]$scriptCode.Add(('# -------------- Attributes for SMTP Filter "{0}"' -f $filter.filterName)) 
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $filter.filterName)) )
                        $smtpAlertNameParam = '-Name $name'

                        # Emails
                        $Emails = '"{0}"' -f [String]::Join('", "', $filter.emails)
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'emails' -Value ('{0}' -f $Emails)))
                        $smtpAlertEmailsParam = ' -Emails $emails'

                        # FilterQuery
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'filter' -Value ('"{0}"' -f $filter.filter)))
                        $filterParam = ' -Filter $filter'

                        # ScopeQuery
                        if ($null -ne $filter.scopeQuery)
                        {

                            if ($filter.scopeQuery -match ' AND ')
                            {

                                $ScopeMatchPreference = "AND"

                                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ScopeMatchPreference' -Value ('"{0}"' -f $ScopeMatchPreference)))
                                $ScopeMatchPreferenceParam = ' -ScopeMatchPreference $ScopeMatchPreference'

                            }

                            else
                            {
                            
                                $ScopeMatchPreference = "OR"
                            
                            }

                            $ScopeNames = New-Object System.Collections.ArrayList

                            ForEach ($scope in $filter.scopeQuery.Split(" $ScopeMatchPreference ", [StringSplitOptions]::RemoveEmptyEntries))
                            {

                                $scopeName = $scope.Replace("scope:", $null)

                                [void]$ScopeNames.Add($scopeName)

                            }

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'scope' -Value ('{0}' -f [String]::Join(', ', $ScopeNames.ToArray()))))
                            $smtpAlertEmailsParam = ' -Scope $scope'

                        }

                        [void]$scriptCode.Add(('Add-HPOVSmtpAlertEmailFilter {0}{1}{2}' -f $smtpAlertNameParam, $smtpAlertEmailsParam, $filterParam, $smtpAlertEmailsParam))
                        [void]$scriptCode.Add("")

                    }

                }

            }
        
            DisplayOutput -Code $scriptCode

        }

        Function Generate-TimeLocale-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $timeLocale      = $InputObject
 
            $Locale          = $TimeLocale.Locale
            $ntpServers      = $TimeLocale.NtpServers
            $pollingInterval = $timeLocale.pollingInterval
            $syncWithHost    = $timeLocale.SyncWithHost

            $localeParm        = $ntpParam         = $ntpCode = $null
            $syncWithHostParam = $syncWithHostCode = $null
            $pollingParam      = $pollingCode      = $null

            [void]$scriptCode.Add('# -------------- Attributes for date and time')
            
            $locale            = $locale.Split($dot)[0]

            if ($locale -ne 'en_US')
            {

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'locale' -Value ('"{0}"' -f $locale)))
                $localeParm = ' -Locale $locale'

            }

            # will need to return NTP configuration
            if (-not $syncWithHost)
            {

                if ($ntpServers)
                {

                    $ntpServers = [String]::Join('", "', $ntpServers)
                    $ntpParam = ' -NtpServers $ntpServers'
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ntpServers' -Value ('"{0}"' -f $ntpServers)))

                }

                if ($pollingInterval)
                {

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'pollingInterval' -Value ('{0}' -f $pollingInterval)))
                    $pollingParam = " -PollingInterval `$pollingInterval "

                }

            }

            else
            {
            
                $syncWithHostParam = ' -SyncWithHost'
            
            }

            [void]$scriptCode.Add(('Set-HPOVApplianceDateTime{0}{1}{2}{3}' -f $localeParm, $syncWithHostParam, $ntpParam, $pollingParam))

            DisplayOutput -Code $scriptCode

        }

        Function Generate-AddressPoolSubnet-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $subnet = $InputObject

            $networkID      = $subnet.NetworkID
            $subnetmask     = $subnet.subnetmask
            $gateway        = $subnet.gateway
            $domain         = $subnet.domain
            $dns            = $subnet.dnsservers
            $rangeUris      = $subnet.rangeUris

            [void]$scriptCode.Add('# -------------- Attributes for subnet "{0}"' -f $networkID)
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'networkID' -Value '$networkID'))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'subnetmask' -Value '$subnetmask'))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'networkgatewayID' -Value '$gateway'))

            $networkIdParam     = ' -NetworkID '
            $subnetMaskParam    = ' -Subnetmask $subnetmask'
            $gatewayParam       = ' -Gateway $gateway'

            # Code and attribute parameters
            $dnsParam       = $dnsCode = $null

            if ($dns)
            {

                $dnsServers     = [String]::Join('", "', $dns)

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'dnsServers' -Value ('"{0}"' -f $dnsServers)))
                $dnsParam       = ' -DnsServers $dnsServers'
            
            }

            $domainParam        = $domainCode = $null

            if ($domain)
            {

                $domainParam    =  ' -Domain $domain'
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'domain' -Value ('"{0}"' -f $domain)))

            }
           
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'thisSubnet' -Value ('New-HPOVAddressPoolSubnet{0}{1}{2}{3}{4}' -f $networkIdParam, $subnetMaskParam, $gatewayParam, $dnsParam, $domainParam)))

            foreach ($rangeUri in $rangeUris)
            {

                $range          = send-HPOVRequest -Uri $rangeUri
                $name           = $range.Name 
                $startAddress   = $range.startAddress 
                $endAddress     = $range.endAddress 

                [void]$scriptCode.Add('')
                [void]$scriptCode.Add('# --- Attributes for Address Pool range associated with subnet {0}' -f $networkID)
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value '"{0}"' -f $name))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'startAddress' -Value '"{0}"' -f $startAddress))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'endAddress' -Value '"{0}"' -f $endAddress))
                [void]$scriptCode.Add('New-HPOVAddressPoolRange -IPV4Subnet $thisSubnet -Name $name -start $startAddress -end $endAddress')

            }

            DisplayOutput -Code $scriptCode

        }

        Function Generate-AddressPoolRange-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $range  = $InputObject

            $poolName       = $range.Name  
            $rangeType      = $range.rangeCategory 
            $startAddress   = $range.startAddress
            $endAddress     = $range.endAddress
            $cat            = $range.category

            $rangeTypeParam = $poolTypeParam = $startEndParam = $null

            $poolType       = $cat.Split('-')[-1] 

            [void]$scriptCode.Add('# -------------- Attributes for address pool range {0}' -f $poolType)

            # Custom, non-IPv4 range
            if ($poolType -ne 'IPv4' -and $rangeType -eq 'Custom')
            {  

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'poolType' -Value ('"{0}"' -f $poolType)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'rangeType' -Value ('"{0}"' -f $rangeType)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'startAddress' -Value ('"{0}"' -f $startAddress)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'endAddress' -Value ('"{0}"' -f $endAddress)))
                
                $rangeTypeParam = ' -rangeType $rangeType'
                $poolTypeParam  = ' -poolType $poolType'
                $startEndParam  = ' -start $startAddress -end $endAddress'

            }

            # Auto generated, non-IPv4 range
            elseif ($poolType -ne 'IPv4' -and $rangeType -eq 'Generated')
            {

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'poolType' -Value ('"{0}"' -f $poolType)))
                $poolTypeParam  = ' -poolType $poolType'

            }

            # IPv4 address range
            else
            {
            
                Try
                {
                
                    $AddressPoolSubnetId = Get-NamefromUri $range.subnetUri
                
                }
                
                Catch
                {
                
                    $PSCmdlet.ThrowTerminatingError($_)
                
                }

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'subnet' -Value ('Get-HPOVAddressPoolSubnet -NetworkID {0}' -f $AddressPoolSubnetId)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'startAddress' -Value ('"{0}"' -f $startAddress)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'endAddress' -Value ('"{0}"' -f $endAddress)))
                
                $startEndParam  = ' -IPv4Subnet $subnet -Start $startAddress -End $endAddress'
            
            }

            [void]$scriptCode.Add(('New-HPOVAddressPoolRange{0}{1}{2}' -f $poolTypeParam, $rangeTypeParam, $startEndParam))

            DisplayOutput -Code $scriptCode

        }

        Function Generate-EthernetNetwork-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $net = $InputObject

            # ----------------------- Construct Network information
            $name        = $net.name
            $type        = $net.type.Split("-")[0]   # Value is like ethernet-v30network

            $vLANType    = $net.ethernetNetworkType
            $vLANID      = $net.vLanId

            $pBandwidth  = [string]$net.DefaultTypicalBandwidth
            $mBandwidth  = [string]$net.DefaultMaximumBandwidth
            $smartlink   = if ($net.SmartLink) { $true } else { $false }
            $Private     = if ($net.PrivateNetwork) { $true } else { $false }
            $purpose     = $net.purpose

            [void]$scriptCode.Add('# -------------- Attributes for Ethernet network "{0}"' -f $name)
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $name)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'type' -Value ('"{0}"' -f $type)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'vLANType' -Value ('"{0}"' -f $vLANType)))

            $vLANIDparam = $vLANIDcode = $null

            if ($vLANType -eq 'Tagged')
            { 

                if (($vLANID) -and ($vLANID -gt 0)) 
                {

                    $vLANIDparam = ' -VlanID $VLANID'
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'vLANid' -Value ('{0}' -f $vLANID)))

                }

            }                

            $pBWparam = $pBWCode = $null
            $mBWparam = $mBWCode = $null

            if ($PBandwidth) 
            {

                $pBWparam = ' -TypicalBandwidth $pBandwidth'
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'pBandwidth' -Value ('{0}' -f $pBandwidth)))

            }
    
            if ($MBandwidth) 
            {

                $mBWparam = ' -MaximumBandwidth $mBandwidth'
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'mBandwidth' -Value ('{0}' -f $mBandwidth)))

            }

            $subnetURI   = $net.subnetURI

            $subnetCode  = $subnetIDparam = $null

            if ($subnetURI) 
            {

                Try
                {
                
                    $subnet = Send-HPOVRequest -Uri $subnetURI -Hostname $ApplianceConnection
                
                }
                
                Catch
                {
                
                    $PSCmdlet.ThrowTerminatingError($_)
                
                }

                $ThisSubnetID   = $subnet.NetworkID
                $subnetName     = $subnet.Name

                $subnetIDparam  = ' -Subnet $ThisSubnet'

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'networkID' -Value ('"{0}"' -f $ThisSubnetID)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ThisSubnet' -Value ('Get-HPOVAddressPoolSubnet -NetworkID $networkID')))

            }
            
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'PLAN' -Value ('${0}' -f $Private)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'smartLink' -Value ('${0}' -f $smartLink)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'purpose' -Value ('"{0}"' -f $purpose)))

            [void]$scriptCode.Add(('New-HPOVNetwork -Name $name -Type $Type -PrivateNetwork $PLAN -SmartLink $smartLink -VLANType $VLANType{0}{1}{2}{3} -purpose $purpose' -f $vLANIDparam, $pBWparam, $mBWparam, $subnetIDparam))

            DisplayOutput -Code $scriptCode
   
        }

        Function Generate-NetworkSet-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $ns = $InputObject

            $name               = $ns.name
            $description        = $ns.description
            $PBandwidth         = $ns.TypicalBandwidth 
            $Mbandwidth         = $ns.MaximumBandwidth 
            $untaggednetworkURI = $ns.nativeNetworkUri
            $networkURIs        = $ns.networkUris

            [void]$scriptCode.Add('# -------------- Attributes for Network Set "{0}"' -f $name)
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $name)))
                
            $pBWparam = $pbWCode = $null
            $mBWparam = $mBWCode = $null

            if ($PBandwidth) 
            {

                $pBWparam = ' -TypicalBandwidth $pBandwidth'
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'pBandwidth' -Value ('{0}' -f $pBandwidth)))

            }
            
            if ($MBandwidth) 
            {

                $mBWparam = ' -MaximumBandwidth $mBandwidth'
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'mBandwidth' -Value ('{0}' -f $mBandwidth)))

            }
                
            $untaggedParam  = $untaggednetworkname  =  $untaggednetCode = $null

            if ($untaggednetworkURI) 
            {

                $untaggedParam          =  ' -UntaggedNetwork $untaggednetwork'
                $untaggednetworkname    = Get-NamefromUri -Uri $untaggednetworkURI
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'untaggednetworkname' -Value ('"{0}"' -f $untaggednetworkname)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'untaggednetwork' -Value 'Get-HPOVNetwork -Name $untaggednetworkname'))
                
            }
                
            $netParam = $netCode = $null

            if ($networkURIs) 
            {

                $netParam     = ' -Networks $networks'
                #Serialize Array
                $arr = @()

                foreach ($el in $networkURIs)
                { 

                    $name  = Get-NamefromUri -Uri $el
                    $arr += '"{0}"' -f $name
                        
                }   # Add quote to string

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'networks' -Value ('{0} | Get-HPOVNetwork' -f [String]::Join(', ', $arr))))

            }

            [void]$scriptCode.Add(('New-HPOVNetwork -Name $nsName{0}{1}{2}{3}' -f $pBWparam, $mBWparam, $netParam, $untaggedParam))

            DisplayOutput -Code $scriptCode

        }

        Function Generate-FCNetwork-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $net = $InputObject

            $name                    = $net.name
            $description             = $net.description
            $type                    = $net.type.Split("-")[0]   # Value is 'fcoe-networksV300
            $fabrictype              = $net.fabrictype
            $pBandwidth              = $net.defaultTypicalBandwidth
            $mBandwidth              = $net.defaultMaximumBandwidth
            $sanURI                  = $net.ManagedSANuri
            $linkStabilityTime       = if ($net.linkStabilityTime) { $net.linkStabilityTime} else {30}
            $autologinredistribution = if ($net.autologinredistribution) { $true } else { $false }

	    	[void]$scriptCode.Add('# -------------- Attributes for FibreChannel network "{0}"' -f $name)
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $name)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'type' -Value ('"{0}"' -f $type)))

            # fcoe network
            $VLANID                  = $net.VLANID
            $fabricUri               = $net.fabricUri 

            $pBWparam = $pBWCode = $null
            $mBWparam = $mBWCode = $null

            if ($PBandwidth) 
            {

                $pBWparam = ' -typicalBandwidth $pBandwidth'
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'pBandwidth' -Value ('{0}' -f $pBandwidth)))

            }
    
            if ($MBandwidth) 
            {

                $mBWparam = ' -maximumBandwidth $mBandwidth'
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'mBandwidth' -Value ('{0}' -f $mBandwidth)))

            }

            $FCparam          = $FCcode = $null
            $vLANIDparam      = $vLANIDcode = $null
            $autologinParam   = $autologinCode = $null
            $linkParam        = $linkCode = $null

            if ($type -match 'fcoe') #FCOE network
            {                

                if (($vLANID) -and ($vLANID -gt 0)) 
                {

                    $vLANIDparam =   ' -vLanID $VLANID'
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'vLANid' -Value ('{0}' -f $vLANID)))
                
                }
                        
            }

            else  # FC network
            {
                
                $FCparam          = ' -FabricType $fabricType'
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'fabricType' -Value ('"{0}"' -f $fabricType)))
        
                if ($fabrictype -eq 'FabricAttach')
                {

                    if ($autologinredistribution)
                    {

                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'autologinredistribution' -Value ('${0}' -f $autologinredistribution)))
                        $autologinParam     = ' -AutoLoginRedistribution $autologinredistribution'

                    }

                    if ($linkStabilityTime) 
                    {

                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'LinkStabilityTime' -Value ('{0}' -f $LinkStabilityTime)))
                        $linkParam  = ' -LinkStabilityTime $LinkStabilityTime'

                    }

                    $FCparam              += $autologinParam + $linkParam
            
                }

            }
                

            $sanParam   = $sanCode = $null

            if ($sanURI)
            { 

                Try
                {
                
                    $ManagedSAN = Send-HPOVRequest -Uri $sanURI -Hostname $ApplianceConnection
                
                }
                
                Catch
                {
                
                    $PSCmdlet.ThrowTerminatingError($_)
                
                }
                
                $SANname            = $ManagedSAN.Name 
                $SANmanagerName     = $ManagedSAN.devicemanagerName
        

                $SANparam   = ' -ManagedSAN $managedSAN'

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'SANname' -Value ('"{0}"' -f $SANname)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'managedSAN' -Value ('Get-HPOVManagedSAN -Name $SANname')))

            }

            [void]$scriptCode.Add(('New-HPOVNetwork -Name $name -Type $Type{0}{1}{2}{3}{4}' -f $pBWparam, $mBWparam, $FCparam, $vLANIDparam, $SANparam))

            DisplayOutput -Code $scriptCode

        }

        Function Generate-SanManager-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $SM  = $InputObject

            if ($SM.isInternal)
            {

                # Need to change this to non-terminating error?
                Write-Host "Unable to generate PowerShell Cmdlet for Direct Attach SAN Managers."

            }

            else
            {
            
                $name = $SM.name

                $displayName = $sm.providerDisplayName
                    
                foreach ($CI in $SM.ConnectionInfo)
                {

                    Switch ($CI.Name)
                    {

                        # ------ For HPE and Cisco 
                        'SnmpPort'
                        {

                            $Port = $CI.Value

                        }

                        'SnmpUsername'
                        {

                            $snmpUsername = $CI.Value

                        }

                        'SnmpAuthLevel'
                        { 

                            $v = $CI.Value

                            if ($v -notlike 'AUTH*')
                            {

                                $AuthLevel = 'None'

                            }

                            else 
                            {

                                if ($v -eq 'AUTHNOPRIV')
                                {
                                    
                                    $AuthLevel = 'AuthOnly'

                                }

                                else
                                {

                                    $AuthLevel = 'AuthAndPriv'

                                }

                            }

                        }  

                        'SnmpAuthProtocol'
                        {

                            $AuthProtocol = $CI.Value

                        }

                        'SnmpPrivProtocol'
                        {

                            $PrivProtocol = $CI.Value

                        }

                        #---- For Brocade 
                        'Username'
                        {

                            $username = $CI.Value

                        }

                        'UseSSL'
                        {

                            $UseSSL = if ($CI.Value)
                            {

                                $true

                            }

                            else
                            {

                                $false

                            }   

                        }

                        'Port'
                        {

                            $Port = $CI.Value

                        }

                    }

                }

                $credParam = $credCode = $null
                $privProtocolParam = $privProtocolCode = $null

                [void]$scriptCode.Add('# -------------- Attributes for  San Manager $name')
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $name)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'type' -Value ('"{0}"' -f $displayName)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'port' -Value ('{0}' -f $port)))

                if ($displayName -eq 'Brocade Network Advisor')
                {

                    $credParam = ' -username $username -password password  -useSSL:$useSSL'
                    
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'username' -Value ('"{0}"' -f $username)))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'password' -Value ('Read-Host "Provide password for user "$username" to connect to SANManager" -asSecureString')))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'useSSL' -Value ('${0}' -f $useSSL)))

                }

                else    # Cisco or HPE 
                {

                    $authProtocolParam = ' -SnmpAuthLevel $snmpAuthLevel -Snmpusername $snmpUsername -SnmpAuthPassword $snmpAuthPassword -SnmpAuthProtocol $snmpAuthProtocol'

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snmpUsername' -Value ('"{0}"' -f $snmpUsername)))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snmpAuthLevel' -Value ('"{0}"' -f $authLevel)))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snmpAuthProtocol' -Value ('"{0}"' -f $AuthProtocol)))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snmpAuthPassword' -Value ('Read-Host "Provide authentication password for user $snmpUsername" -asSecureString')))

                    if ($authLevel -eq 'AuthAndPriv')
                    {

                        $privProtocolParam = ' -SnmpPrivPassword $snmpPrivPassword -snmpPrivProtocol $snmpPrivProtocol'

                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snmpPrivProtocol' -Value ('"{0}"' -f $privProtocol)))
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snmpPrivPassword' -Value ('Read-hHst "Provide privacy password" -asSecureString')))

                    }

                    $credParam = $authProtocolParam + $privProtocolParam

                }

                [void]$scriptCode.Add('Add-HPOVSanManager -Hostname $name -Type $type -Port $port{0}' -f $credParam)

                DisplayOutput -Code $scriptCode
            
            }           

        }

        Function Generate-StorageSystem-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $StS = $InputObject

            $StoragePorts   = $PortGroupPorts     = @()
            $PortGroupParam = $StoragePortsParam  = $null

            $hostName            = $Sts.hostname
            $Username            = $Sts.Credentials.username
            $family              = $sts.family
            $DomainName          = if ($family -eq 'StoreServ' ) { $Sts.deviceSpecificAttributes.managedDomain } else {''}

            [void]$scriptCode.Add('# -------------- Attributes for StorageSystem "{0}"' -f $hostname)

            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'hostname' -Value ('"{0}"' -f $hostname)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'family' -Value ('"{0}"' -f $family)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'cred' -Value ('Get-HPOVCredential -Message "Provide the password for {0}" -Username {0}' -f $Username)))

            $portList            = $Sts.Ports | where status -eq 'OK' | sort Name

            foreach ($MP in ($portList | where mode -eq 'Managed')) 
            {

                # 3PAR
                if ($family -eq 'StoreServ')
                { 
                    
                    $Thisname    = $MP.expectedSanName

                    if ($Thisname)
                    {

                        # Need to get the associated FC network to the expectedSanName value

                        Try
                        {
                        
                            $AssociatedFcNetwork = Send-HPOVRequest -Uri $MP.expectedSanUri

                            $AssociatedFcNetworkName = $AssociatedFcNetwork.associatedNetworks.name
                        
                        }
                        
                        Catch
                        {
                        
                            $PSCmdlet.ThrowTerminatingError($_)
                        
                        }

                        $StoragePorts += "'{0}' = '{1}'" -f $MP.Name, $AssociatedFcNetworkName # Build Port syntax '0:1:2'= 'VSAN10'

                    }

                    if ($null -ne $MP.groupName)
                    {

                        $PortGroupParam = ' -PortGroups $portGroups'

                        $PortGroupPorts += "'{0}' = '{1}'" -f $MP.Name, $MP.groupName # Build Port syntax '0:1:2'= 'Portgroup 1'

                    }
                
                }

                # VSA/StoreVirtual
                else 
                { 
                    
                    $Thisname    = $MP.ExpectedNetworkName  

                    if ($Thisname)
                    {

                        $StoragePorts = [PSCustomObject]@{PortName = $MP.Name; NetworkName = $Thisname} # Build Port syntax '192.168.1.1'= 'iSCSI Network'

                    }
                
                }

            }

            if ($DomainName)
            {

                $domainParam     = ' -Domain $domainName'

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'domainName' -Value ('"{0}"' -f $domainName)))

            }

            if ($StoragePorts -and $family -eq 'StoreServ' -and $StoragePorts.Count -gt 0)
            {

                $storagePortsParam  = ' -Ports $storageSystemPorts'

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'storageSystemPorts' -Value ('{0}{1}{2}' -f '@{', [String]::Join("; ", $StoragePorts), '}')))

                if ($PortGroupPorts.Count -gt 0)
                {

                    $PortGroupParam = ' -PortGroups $portGroupPorts'

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'portGroupPorts' -Value ('{0}{1}{2}' -f '@{', [String]::Join("; ", $PortGroupPorts), '}')))

                }
                
            }

            elseif ($StoragePorts -and $family -eq 'StoreVirtual')
            {

                $storagePortsParam  = ' -VIPS $vips'

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ThisiSCSINetwork' -Value ('Get-HPOVNetwork -Type Ethernet -Name "{0}"' -f $StoragePorts.NetworkName)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'vips' -Value ('{0}"{1}" = $ThisiSCSINetwork{2}' -f "@{", $StoragePorts.PortName, "}")))

            }

            [void]$scriptCode.Add(('Add-HPOVStorageSystem -Hostname $hostName -Credential $cred -Family $family{0}{1}{2}' -f $domainParam, $storagePortsParam, $PortGroupParam))
  
    
            DisplayOutput -Code $scriptCode

        }

        Function Generate-StoragePool-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $pool = $InputObject

            if ($pool.state -ne 'Managed')
            {

                Write-Host ("Unable to create a Cmdlet for an unmanaged storage pool, {0}" -f $pool.name)

            }

            else
            {
            
                $name           = $pool.name
                $description    = $pool.description

                # --- Storage System

                $stsName        = Get-NamefromUri -Uri $pool.StorageSystemUri 
        
                [void]$scriptCode.Add('# -------------- Attributes for Storage Pool "{0}"' -f $pool.name)
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$stsName' -Value ('"{0}"' -f $stsName)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$storageSystem' -Value 'Get-HPOVStorageSystem -Name $stsName'))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$pool' -Value (' Get-HPOVStoragePool -Name "{0}" -StorageSystem $storageSystem' -f $pool.name)))
                [void]$scriptCode.Add('Set-HPOVStoragePool -Pool $pool -Managed $True')

                DisplayOutput -Code $scriptCode
            
            }

        }

        Function Generate-StorageVolumeTemplate-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $Template = $InputObject

            $descParam = $PoolParam = $CapacityParam = $StoragePoolParam = $SnapshotPoolParam = $ProvisionTypeParam = $CompressionParam = $ScopeParam = $null
            $DataProtectionLevelParam = $AdaptiveOptimizationParam = $null

            # Common SVT attributes
            $name                = $Template.Name
            $description         = $Template.Description
            $family              = $Template.family
            $stsUri              = $Template.compatibleStorageSystemsUri
 
            # Common SVT properties
            $p                   = $template.Properties
            $size                = $p.size.default / 1GB
            $sizeIsLocked        = $p.size.meta.locked
            $isShareable         = $p.isShareable.default
            $isShareableLocked   = $p.isShareable.meta.locked
            $PoolUri             = $p.storagePool.default
            $poolIsLocked        = $p.storagePool.meta.locked
            $provisionType       = $p.provisioningType.default 
            $provisionTypeLocked = $p.provisioningType.meta.locked
            $stsName             = Get-NamefromUri -Uri $stsUri
            $poolName            = Get-NamefromUri -Uri $PoolUri

            # Common attributes to set
            [void]$scriptCode.Add(('#------ Attributes for storage volume template "{0}" (Family: {1})' -f $name, $family))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $name)))

            if ($description)
            {

                $descParam      = ' -Description $description'
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'description' -Value ('"{0}"' -f $description)))

            }

            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'poolName' -Value ('"{0}"' -f $poolName)))

            Switch ($family)
            {

                'StoreServ'
                {

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'stsName' -Value ('"{0}"' -f $stsName)))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'storagePool' -Value ('Get-HPOVStoragePool -Name $poolName -StorageSystem $stsName')))

                }

                'StoreVirtual'
                {

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'storagePool' -Value ('Get-HPOVStoragePool -Name $poolName')))

                }                

            }           

            $PoolParam = ' -StoragePool $StoragePool'

            if ($poolIsLocked)
            {

                $PoolParam += ' -LockStoragePool' 

            }

            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'capacity' -Value ('{0}' -f $size)))

            $CapacityParam = ' -Capacity $capacity'

            if ($sizeIsLocked)
            {
                
                $CapacityParam += ' -LockCapacity'

            }

            if ($isShareable)
            {

                $ProvisionTypeParam = ' -Shared'

                if ($isShareableLocked)
                {

                    $ProvisionTypeParam += ' -LockProvisionMode'

                }

            }            

            # family specific properties
            switch ($family)
            {

                'StoreServ'
                {

                    $SnapshotUri          = $p.snapshotPool.default 
                    $snpshotPoolIsLocked  = $p.snapshotPool.meta.locked
                    $isDeduplicated       = $p.isDeduplicated.default
                    $isDeduplicatedLocked = $p.isDeduplicated.meta.locked
                    $enableCompression    = $p.enableCompression.default
                    $isCompressionLocked  = $p.enableCompression.meta.locked

                    if ($SnapshotUri -ne $PoolUri)
                    {

                        $snapshotPoolName = Get-NamefromUri -Uri $snapshotUri

                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snapShotPoolName' -Value ('"{0}"' -f $snapshotPoolName)))
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snapShotPool' -Value ('Get-HPOVStoragePool -Name $snapShotPoolName -StorageSystem $stsName')))

                        $SnapshotPoolParam = ' -SnapshotStoragePool $snapShotPool'

                        if ($snpshotPoolIsLocked)
                        {

                            $SnapshotPoolParam += ' -LockSnapshotStoragePool'

                        }

                    }

                    else
                    {
                    
                        $snapshotName        = $poolName
                    
                    }

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'enableDeduplication' -Value ('${0}' -f $isDeduplicated)))

                    $DeduplicateParam = ' -EnableDeduplication $enableDeduplication'
                    
                    if ($isDeduplicatedLocked)
                    {

                        $DeduplicateParam += ' -LockEnableDeduplication'

                    }

                    if (-not [String]::IsNullOrWhiteSpace($enableCompression))
                    {

                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'enableCompression' -Value ('${0}' -f $enableCompression)))

                        $CompressionParam = ' -EnableCompression $enableCompression'

                        if ($isCompressionLocked)
                        {

                            $CompressionParam += ' -LockEnableCompression'

                        }

                    }

                }

                'StoreVirtual'
                {

                    $dataProtectionLevel           = $p.dataProtectionLevel.default
                    $dataProtectionLevelLocked     = $p.dataProtectionLevel.meta.locked
                    $isAdaptiveOptimizationEnabled = $p.isAdaptiveOptimizationEnabled.default
                    $isAdaptiveOptimizationLocked  = $p.isAdaptiveOptimizationEnabled.meta.locked

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'dataProtectionLevel' -Value ('"{0}"' -f $dataProtectionLevel)))

                    $DataProtectionLevelParam = ' -DataProtectionLevel $dataProtectionLevel'

                    if ($dataProtectionLevelLocked)
                    {

                        $DataProtectionLevelParam += ' -LockProtectionLevel'

                    }

                    if ($isAdaptiveOptimizationEnabled)
                    {

                        $AdaptiveOptimizationParam = ' -EnableAdaptiveOptimization'
                        
                    }                    

                    if ($isAdaptiveOptimizationEnabled)
                    {

                        $AdaptiveOptimizationParam += ' -LockAdaptiveOptimization'

                    }

                }

            }

            # Scopes
            Try
            {
            
                $ResourceScope = Send-HPOVRequest -Uri $Template.scopesUri -Hostname $ApplianceConnection
            
            }
            
            Catch
            {
            
                $PSCmdlet.ThrowTerminatingError($_)
            
            }

            $n = 1

            if (-not [String]::IsNullOrEmpty($ResourceScope.scopeUris))
            {

                ForEach ($scopeUri in $ResourceScope.scopeUris)
                {

                    $scopeName = Get-NamefromUri -Uri $scopeUri

                    $ScopeVarName = 'Scope'
                    $Value        = 'Get-HPOVScope -Name "{0}"' -f $scopeName

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix $ScopeVarName -Suffix $n -Value $Value))

                    $n++

                }

                $ScopeParam = ' -Scope {0}' -f ([String]::Join(', ', (1..($n - 1) | % { '$Scope{0}' -f $_}))) 

            }
            
            [void]$scriptCode.Add(('New-HPOVStorageVolumeTemplate -Name $name{0}{1}{2}{3}{4}{5}{6}{7}{8}' -f $descParam, $PoolParam, $CapacityParam, $ProvisionTypeParam, $SnapshotPoolParam, $CompressionParam, $DataProtectionLevelParam, $AdaptiveOptimizationParam, $ScopeParam))
                
            DisplayOutput -Code $scriptCode

        }

        Function Generate-StorageVolume-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $SV   = $InputObject

            $name               = $SV.name
            $description        = $SV.description
            $poolUri            = $SV.storagePoolUri
            $size               = $SV.provisionedCapacity / 1GB
            $volTemplateUri     = $SV.volumeTemplateUri
            $provisionType      = $SV.provisioningType
            $isShareable        = $SV.isShareable
            $p                  = $SV.deviceSpecificAttributes
                $isCompressed   = $p.isCompressed
                $isDeduplicated = $p.isDeduplicated
                $snapshotUri    = $p.snapshotPoolUri

            $descParam = $PoolParam = $CapacityParam = $StoragePoolParam = $SnapshotPoolParam = $ProvisionTypeParam = $CompressionParam =$DeduplicateParam = $ScopeParam = $null
            $DataProtectionLevelParam = $AdaptiveOptimizationParam = $null

            [void]$scriptCode.Add('#------ Attributes for storage volume "{0}"' -f $name)
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $name)))

            if ($description)
            {

                $descParam      = " -Description `$description "
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'description' -Value ('"{0}"' -f $description)))

            }

            $volumeParam = $storagePoolCode = $null

            if ($volTemplateUri)
            {

                $volumeParam     = ' -VolumeTemplate $volumeTemplate'
                $volTemplateName = Get-NamefromUri -Uri $volTemplateUri  

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'volumeTemplateName' -Value ('"{0}"' -f $volTemplateName)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'volumeTemplate' -Value ('Get-HPOVStorageVolumeTemplate -Name $volTemplateName')))

            }

            else # volume created without template
            {

                Try
                {
                
                    $pool = Send-HPOVRequest -Uri $PoolUri -Hostname $ApplianceConnection
                    $sts  = Send-HPOVRequest -Uri $pool.storageSystemUri -Hostname $ApplianceConnection
                
                }
                
                Catch
                {
                
                    $PSCmdlet.ThrowTerminatingError($_)
                
                }

                $poolName = $pool.name
                $family   = $sts.family

                $volumeParam        = '-StoragePool $storagePool -capacity $size -ProvisioningType $provisioningType'

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'capacity' -Value ('{0}' -f $size)))

                $CapacityParam = ' -Capacity $capacity'

                if ($isShareable)
                {

                    $ProvisionTypeParam = ' -Shared'

                } 

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'provisioningType' -Value ('"{0}"' -f $provisionType)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'poolName' -Value ('"{0}"' -f $poolName)))

                $storagePoolCode = Generate-CustomVarCode -Prefix 'storagePool' -Value 'Get-HPOVStoragePool -Name $poolName'

                Switch ($family)
                {

                    'StoreServ'
                    {

                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'stsName' -Value ('"{0}"' -f $sts.name)))
                        $storagePoolCode += ' -StorageSystem $stsName'

                        [void]$scriptCode.Add($storagePoolCode)

                        if ($poolUri -ne $snapshotUri)
                        {

                            $snapshotPoolName = Get-NamefromUri -Uri $snapshotUri

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snapShotPoolName' -Value ('"{0}"' -f $snapshotPoolName)))
                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snapShotPool' -Value 'Get-HPOVStoragePool -Name $snapShotPoolName -StorageSystem $stsName'))

                            $SnapshotPoolParam = ' -SnapshotStoragePool $snapShotPool'

                        }

                        $isDeduplicated       = $p.isDeduplicated
                        $enableCompression    = $p.isCompressed
                        
                        if ($isDeduplicated)
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'enableDeduplication' -Value ('${0}' -f $isDeduplicated)))

                            $DeduplicateParam = ' -EnableDeduplication $enableDeduplication'

                        }                        
                    
                        if ($enableCompression)
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'enableCompression' -Value ('${0}' -f $enableCompression)))

                            $CompressionParam = ' -EnableCompression $enableCompression'

                        }

                    }

                    'StoreVirtual'
                    {

                        [void]$scriptCode.Add($storagePoolCode)

                        $dataProtectionLevel = $p.dataProtectionLevel
                        $isAdaptiveOptimizationEnabled = $p.isAdaptiveOptimizationEnabled

                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'dataProtectionLevel' -Value ('"{0}"' -f $dataProtectionLevel)))

                        $DataProtectionLevelParam = ' -DataProtectionLevel $dataProtectionLevel'

                        if ($isAdaptiveOptimizationEnabled)
                        {

                            $AdaptiveOptimizationParam = ' -EnableAdaptiveOptimization'
                        
                        }                        

                    }                

                }                

            }

            # Scopes
            Try
            {
            
                $ResourceScope = Send-HPOVRequest -Uri $SV.scopesUri -Hostname $ApplianceConnection
            
            }
            
            Catch
            {
            
                $PSCmdlet.ThrowTerminatingError($_)
            
            }

            $n = 1

            if (-not [String]::IsNullOrEmpty($ResourceScope.scopeUris))
            {

                ForEach ($scopeUri in $ResourceScope.scopeUris)
                {

                    $scopeName = Get-NamefromUri -Uri $scopeUri

                    $ScopeVarName = 'Scope'
                    $Value        = 'Get-HPOVScope -Name "{0}"' -f $scopeName

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix $ScopeVarName -Suffix $n -Value $Value))

                    $n++

                }

                $ScopeParam = ' -Scope {0}' -f ([String]::Join(', ', (1..($n - 1) | % { '$Scope{0}' -f $_}))) 

            }

            [void]$scriptCode.Add(('New-HPOVStorageVolume -Name $name{0}{1}{2}{3}{4}{5}{6}{7}{8}' -f $volumeParam, $descParam, $CapacityParam, $ProvisionTypeParam, $DeduplicateParam, $CompressionParam, $DataProtectionLevelParam, $AdaptiveOptimizationParam, $ScopeParam))

            DisplayOutput -Code $scriptCode

        }

        Function Generate-LogicalInterConnectGroup-Script ($InputObject) 
        {
            
            $scriptCode =  New-Object System.Collections.ArrayList

            $ICModuleTypes               = @{
                "VirtualConnectSE40GbF8ModuleforSynergy" =  "SEVC40f8" ;
                "Synergy20GbInterconnectLinkModule"      =  "SE20ILM";
                "Synergy10GbInterconnectLinkModule"      =  "SE10ILM";
                "VirtualConnectSE16GbFCModuleforSynergy" =  "SEVC16GbFC";
                "Synergy12GbSASConnectionModule"         =  "SE12SAS";
                "571956-B21"                             =  "FlexFabric";
                "455880-B21"                             =  "Flex10";
                "638526-B21"                             =  "Flex1010D";
                "691367-B21"                             =  "Flex2040f8";
                "572018-B21"                             =  "VCFC20";
                "466482-B21"                             =  "VCFC24";
                "641146-B21"                             =  "FEX"
            }

            $FabricModuleTypes           = @{
                "VirtualConnectSE40GbF8ModuleforSynergy"    =  "SEVC40f8" ;
                "Synergy12GbSASConnectionModule"            =  "SAS";
                "VirtualConnectSE16GbFCModuleforSynergy"    =  "SEVCFC";
            }

            $ICModuleToFabricModuleTypes = @{
                "SEVC40f8"                                  = "SEVC40f8" ;
                'SE20ILM'                                   = "SEVC40f8" ;
                'SE10ILM'                                   = "SEVC40f8" ;
                "SEVC16GbFC"                                = "SEVCFC" ;
                "SE12SAS"                                   = "SAS"
            }

            $UnsupportedLigTypes = 'FEX', 'SAS'

            $LigType = $ScopeParam = $QosParam = $null

            $lig     = $InputObject

            $name          = $lig.Name
            $enclosureType = $lig.enclosureType
            $description   = $lig.description
            $uplinkSets    = $lig.uplinksets | sort Name
            $qos           = $lig.qosConfiguration.activeQosConfig

            switch ($lig.category)
            {

                'sas-logical-interconnect-groups'
                {

                    $LigType = 'SAS'

                }

                'logical-interconnect-groups'
                {

                    $LigType = 'EthernetFC'

                    $snmp                   = $lig.snmpConfiguration
                    $Telemetry              = $lig.telemetryConfiguration
                        $sampleCount            = $Telemetry.sampleCount
                        $sampleInterval         = $Telemetry.sampleInterval

                    # The following is only applicable to Ethernet LIG, not FC or SAS
                    $internalNetworkUris    = $lig.internalNetworkUris
                    $fastMacCacheFailover   = $lig.ethernetSettings.enableFastMacCacheFailover
                    $macrefreshInterval     = $lig.ethernetSettings.macRefreshInterval
                    $igmpSnooping           = $lig.ethernetSettings.enableIGMPSnooping
                    $igmpIdleTimeout        = $lig.ethernetSettings.igmpIdleTimeoutInterval
                    $networkLoopProtection  = $lig.ethernetSettings.enablenetworkLoopProtection
                    $PauseFloodProtection   = $lig.ethernetSettings.enablePauseFloodProtection
                    $redundancyType         = $lig.redundancyType
                    $EnableRichTLV          = $lig.EthernetSettings.enableRichTLV
                    $LDPTagging             = $lig.EthernetSettings.enableTaggedLldp
                    
                }

            }

            [void]$scriptCode.Add('# -------------- Attributes for Logical Interconnect Group "{0}"' -f $name)
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $name)))
            
            $FrameCount = $InterconnectBaySet = $frameCountParam = $null
            $intnetParam = $null

            # ----------------------------
            #     Find Interconnect devices
            $Bays         = New-Object System.Collections.ArrayList
            $UpLinkPorts  = New-Object System.Collections.ArrayList
            $Frames       = New-Object System.Collections.ArrayList

            $LigInterconnects = $lig.interconnectMapTemplate.interconnectMapEntryTemplates | Where-Object { -not [String]::IsNullOrWhiteSpace($_.permittedInterconnectTypeUri) }

            $BayHashtable = New-Object System.Collections.Specialized.OrderedDictionary

            foreach ($ligIC in $LigInterconnects)
            {

                # -----------------
                # Locate the Interconnect device and its position
                $ICTypeuri  = $ligIC.permittedInterconnectTypeUri

                if ($enclosureType -eq $Syn12K)
                {

                    $ICtypeName   = (Get-NamefromUri -Uri $ICTypeUri).Replace(' ',$null) # remove Spaces
                    $ICmoduleName = $ICModuleTypes[$ICtypeName]

                    $BayNumber   = ($ligIC.logicalLocation.locationEntries | Where-Object Type -eq "Bay").RelativeValue
                    $FrameNumber = [math]::abs(($ligIC.logicalLocation.locationEntries | Where-Object Type -eq "Enclosure").RelativeValue)

                    $fabricModuleType = $ICModuleToFabricModuleTypes[$ICmoduleName] 

                    if (-not ($BayHashtable.GetEnumerator() | ? Name -eq "Frame$FrameNumber"))
                    {

                        $BayHashtable.Add("Frame$FrameNumber", (New-Object Hashtable))

                    }

                    # Use this hashtable to build the final string value for scriptCode
                    $BayHashtable."Frame$FrameNumber".Add("Bay$BayNumber", $ICmoduleName)

                }

                else # C7K
                {

                    Try
                    {
                    
                        $PartNumber   = (Send-HPOVRequest -Uri $ICTypeuri).partNumber
                    
                    }
                    
                    Catch
                    {
                    
                        $PSCmdlet.ThrowTerminatingError($_)
                    
                    }

                    if ("FEX" -eq $ICModuleTypes[$PartNumber])
                    {

                        $LigType = 'FEX'

                    }

                    $ICmoduleName = $ICModuleTypes[$PartNumber]
                    $BayNumber    = ($ligIC.logicalLocation.locationEntries | Where-Object Type -eq "Bay").RelativeValue

                    [void]$Bays.Add(('Bay{0} = "{1}"' -f $BayNumber, $ICmoduleName)) # Format is xx=Flex Fabric

                }
            
            }

            if ($enclosureType -eq $Syn12K -and $UnsupportedLigTypes -notcontains $LigType)
            {

                $FrameCount = $lig.EnclosureIndexes.Count

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'frameCount' -Value ('{0}' -f $FrameCount)))

                $frameCountParam = ' -FrameCount $frameCount'

            }

            # ----------------------------
            #     Find Internal networks
            $intNetworks = New-Object System.Collections.ArrayList
            $intNetworkNames = New-Object System.Collections.ArrayList
            
            foreach ($uri in $internalNetworkUris)
            {

                Try
                {
                
                    $net = Send-HPOVRequest -Uri $uri -Hostname $ApplianceConnection
                
                }
                
                Catch
                {
                
                    $PSCmdlet.ThrowTerminatingError($_)
                
                }

                $netname = "'{0}'" -f $net.name

                [void]$intNetworkNames.Add($netname)
                [void]$intNetworks.Add($net)

            }

            #Code and parameters

            [Array]::Sort($Bays)

            $BayConfig    = New-Object System.Collections.ArrayList

            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'bayConfig' -Value '@{'))

            if ($enclosureType -eq $Syn12K)  # Synergy
            {

                # $BayConfigperFrame = New-Object System.Collections.ArrayList
                $SynergyCode       = New-Object System.Collections.ArrayList
                $CurrentFrame      = $null

                $InterconnectBaySet = $lig.interconnectBaySet

                $f = 1

                # Process Bays parameter
                foreach ($b in ($BayHashtable.GetEnumerator() | Sort Name))
                {

                    [void]$scriptCode.Add(("`t{0} = @{1}" -f $b.Name, $OpenDelim))

                    $endDelimiter = $SepHash

                    if ($f -eq $BayHashtable.Count)
                    {

                        $endDelimiter = $null

                    }

                    $_b = 1

                    # Loop through ports
                    ForEach ($l in ($b.Value.GetEnumerator() | Sort Name))
                    {

                        $subEndDelimiter = $SepHash

                        if ($_b -eq $b.Value.Count)
                        {

                            $subEndDelimiter = $null

                        }

                        [void]$scriptCode.Add(("`t`t{0} = '{1}'{2}" -f $l.Name, $l.Value, $subEndDelimiter))

                        $_b++

                    }

                    [void]$scriptCode.Add(("`t{0}{1}" -f $CloseDelim, $endDelimiter))

                    $f++

                }

                [void]$scriptCode.Add('}')

                if ($redundancyType)
                {

                    $redundancyParam = ' -fabricredundancy $redundancyType'

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'redundancyType' -Value ('"{0}"' -f $redundancyType)))

                }

                $FabricModuleTypeParam  = ' -FabricModuleType $fabricModuleType'
                $ICBaySetParam          = ' -InterConnectBaySet $InterconnectBaySet'

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'fabricModuleType' -Value ('"{0}"' -f $fabricModuleType)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'InterconnectBaySet' -Value ('{0}' -f $InterconnectBaySet)))

                # Clear out parameters used for Synergy
                $PauseFloodProtectionParam = $macRefreshIntervalParam = $fastMacCacheParam = $null
            
            }

            else # C7K
            {

                $_b = 1

                ForEach ($b in $Bays)
                {

                    $endDelimiter = $SepHash

                    if ($_b -eq $Bays.Count)
                    {

                        $endDelimiter = $null

                    }

                    [void]$scriptCode.Add(("`t{0}{1}" -f $b, $endDelimiter))

                    $_b++

                }

                [void]$scriptCode.Add('}')
                           
                #Parameters valid only for C7000
                if ($UnsupportedLigTypes -notcontains $LigType)
                {

                    if ($fastMacCacheFailover)
                    {
                    
                        $macRefreshIntervalParam = $macRefreshIntervalCode = $null

                        if ($macRefreshInterval)
                        {

                            $macRefreshIntervalParam = " -macRefreshInterval `$macReFreshInterval "

                            $scriptCode.Add((Generate-CustomVarCode -Prefix 'macRefreshInterval' -Value ('$macRefreshInterval')))

                        }

                        $fastMacCacheParam = ' -enableFastMacCacheFailover:$fastMacCacheFailover {0}' # + $FastMacCacheIntervalParam

                    }    
    
                    $PauseFloodProtectionParam = " -enablePauseFloodProtection:`$pauseFloodProtection "

                }
                
                # -------Clear out parameters used for Synergy
                $RedundancyParam        = $null
                $FabricModuleTypeParam  = $null
                $FrameCountParam        = $ICBaySetParam = $null
        
            }            

            # Code and Parameters
            $igmpParam = $networkLoopProtectionParam = $EnhancedLLDPTLVParam = $LDPtaggingParam = $null

            # ---- Bay config
            $baysParam              = ' -Bays $bayConfig'

            if ($UnsupportedLigTypes -notcontains $LigType)
            {

                $igmpIdleTimeoutParam = $igmpIdleTimeoutCode = $intnetParam = $intnetCode = $snmpParam = $null

                if ($igmpSnooping)
                {

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'igmpSnooping' -Value ('${0}' -f $igmpSnooping)))

                    if ($igmpIdletimeOut)
                    { 

                        $igmpIdleTimeoutParam = ' -IgmpIdleTimeOutInterval $igmpIdleTimeout'
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'igmpIdletimeOut' -Value ('{0}' -f $igmpIdletimeOut)))

                    }

                    $igmpParam                  = ' -enableIGMP:$igmpSnooping {0};' -f $igmpIdleTimeoutParam   

                }

                if ($networkLoopProtection)
                {

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'networkLoopProtection' -Value ('${0}' -f $networkLoopProtection)))
                    $networkLoopProtectionParam = ' -enablenetworkLoopProtection:$networkLoopProtection'

                }

                if ($LDPTagging)
                {

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'LDPtagging' -Value ('${0}' -f $LDPtagging)))
                    $LDPtaggingParam            = ' -EnableLLDPTagging:$LDPtagging'

                }

                if ($EnableRichTLV)
                {

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'EnableRichTLV' -Value ('${0}' -f $EnableRichTLV)))
                    $EnhancedLLDPTLVParam       = ' -enableEnhancedLLDPTLV:$EnableRichTLV'

                }

                if ($intNetworkNames.Count -gt 0)
                {

                    $intNetParam            = ' -InternalNetworks $intNetnames'
                    
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'intNetnames' -Value ('{0} | Get-HPOVNetwork ' -f [String]::Join($Comma, $intNetworkNames.ToArray()))))

                }  

                if ($snmp)
                {

                    $isV1Snmp           = $snmp.enabled
                    $isV3Snmp           = $snmp.v3Enabled

                    if ($isV1Snmp -or $isV3Snmp)
                    {

                        $readCommunityParam = $snmpParam = $contactParam = $snmpV3UsersParam = $accessListParam = $informParam = $null

                        $trapdestParam = ' -TrapDestinations $trapDestinations'

                        $readCommunity    = $snmp.readCommunity 
                        $contact          = $snmp.systemContact
                        $snmpUsers        = $snmp.snmpUsers
                        $accessList       = $snmp.snmpAccess
                        $trapdestinations = $snmp.trapDestinations

                        [void]$scriptCode.Add('#-- Generating snmp object for LIG')
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'readCommunity' -Value ('"{0}"' -f $readCommunity)))
                        $readCommunityParam = ' -ReadCommunity $readCommunity'                        

                        if ($isV1Snmp)
                        {

                            $snmpParam += ' -SnmpV1'

                        }

                        if ($isV3Snmp)
                        {

                            $snmpParam += ' -SnmpV3'

                        }

                        if ($Contact)
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'contact' -Value ('"{0}"' -f $contact)))
                            $contactParam = ' -Contact $contact'

                        }

                        $SnmpV3UsersProcessed = New-Object System.Collections.ArrayList

                        $u = 1
                        # Process trap destinations
                        foreach ($t in $trapdestinations)
                        {

                            $destParam = $communityStrParam = $portParam = $trapFormatParam = $severityParam = $vcmCategoryParam = $enetCategoryParam = $fcCateoryParam = $snmpUserParam = $engineIdParam = $null

                            $destination        = $t.trapDestination
                            $communityString    = $t.communityString
                            $trapFormat         = $t.trapFormat
                            $severities         = $t.trapSeverities
                            $vcmTrapCategories  = $t.vcmTrapCategories
                            $enetTrapCategories = $t.enetTrapCategories
                            $fcTrapCategories   = $t.fcTrapCategories
                            $port               = $t.port
                            $snmpUserName       = $t.userName
                            $snmpUserEngineId   = $t.engineId
                            $inform             = $t.inform

                            [void]$scriptCode.Add('#--   Generating Trap destination object for "{0}" ' -f $destination)
                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'destination' -Value ('"{0}"' -f $destination)))
                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'trapFormat' -Value ('"{0}"' -f $trapFormat)))
                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'port' -Value ('{0}' -f $port)))

                            $destParam       = ' -destination $destination'
                            $trapFormatParam = ' -SnmpFormat $trapformat'
                            $portParam       = ' -Port $port'
                            
                            # Need to ccreate new SNMPv3 user param for each trap destination
                            if ($trapFormat -match 'SNMPv3')
                            {

                                if (-not ($SnmpV3UsersProcessed | ? Name -eq $snmpUserName))
                                {

                                    $authProtParam = $privProtParam = $null

                                    $securitylevel = 'None'
                                    
                                    $snmpv3UserDetails = $snmpUsers | ? snmpV3UserName -eq $snmpUserName

                                    $snmpV3AuthProtocol    = $snmpv3UserDetails.v3AuthProtocol
                                    $snmpv3PrivacyProtocol = $snmpv3UserDetails.v3PrivacyProtocol

                                    [void]$scriptCode.Add('#--   Generating SNMPv3 user "{0}"' -f $snmpUserName)
                                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'userName' -Value ('"{0}"' -f $snmpUserName)))

                                    $snmpUserNameParam = ' -Username $userName'

                                    if ($snmpV3AuthProtocol -ne 'NA')
                                    {

                                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'authProtocol' -Value ('"{0}"' -f $snmpV3AuthProtocol)))
                                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'authPassword' -Value ('Read-Host -AsSecureString -Message "Provide password for Authentication Protocol."' -f $destination)))

                                        $authProtParam = ' -AuthProtocol $authProtocol -AuthPassword $authPassword'

                                        $securitylevel = 'AuthOnly'

                                        if ($snmpv3PrivacyProtocol -ne 'NA')
                                        {

                                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'privProtocol' -Value ('"{0}"' -f $snmpv3PrivacyProtocol)))
                                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'privPassword' -Value ('Read-Host -AsSecureString -Message "Provide password for Privacy Protocol."' -f $destination)))

                                            $privProtParam = ' -PrivProtocol $privProtocol -PrivPassword $privPassword'
                                            
                                            $securitylevel = 'AuthAndPriv'

                                        }

                                    }

                                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'securityLevel' -Value ('"{0}"' -f $securitylevel)))
                                    $securityLevelParam = ' -SecurityLevel $securityLevel'

                                    $VarName = 'snmpv3User'
                                    $Value = 'New-HPOVSnmpV3User{1}{2}{3}{4}' -f $u, $snmpUserNameParam, $securityLevelParam, $authProtParam, $privProtParam

                                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix $VarName -Suffix $u -Value $Value))

                                    $snmpV3UserParamVarName = '${0}{1}' -f $VarName, $u
                                    
                                    [void]$SnmpV3UsersProcessed.Add(@{name = $snmpUserName; varName = ('snmpv3User{0}' -f $u)})

                                    $u++

                                }
                                
                                else
                                {
                                
                                    $snmpV3UserParamVarName = '${0}' -f ($SnmpV3UsersProcessed | ? name -eq $snmpUserName).varName
                                
                                }

                                $snmpUserParam = ' -SnmpV3User {0}' -f $snmpV3UserParamVarName

                            }

                            if ($inform)
                            {
                            
                                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'inform' -Value ('"{0}"' -f 'Inform')))

                                if ($trapFormat -match 'SNMPv3')
                                {

                                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'engineId' -Value ('"{0}"' -f $snmpUserEngineId)))
                                    $engineIdParam = ' -EngineID $engineId'

                                }
                            
                            }

                            else
                            {
                            
                                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'inform' -Value ('"{0}"' -f 'Trap')))
                            
                            }

                            $informParam    = ' -NotificationType $inform'
                            
                            [void]$scriptCode.Add(('$trapDestinations           += New-HPOVSnmpTrapDestination{0}{1}{2}{3}{4}{5}' -f $destParam, $portParam, $communityParam, $FormatParam, $snmpUserParam, $informParam, $engineIdParam))

                        }

                        if ($SnmpV3UsersProcessed.Count -gt 0)
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'snmpv3Users' -Value ('@(${0})' -f [string]::Join(', $', $SnmpV3UsersProcessed.varName))))

                             $snmpV3UsersParam = ' -Snmp3Users $snmpv3Users'

                        }

                        if ($accessList)
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'accessList' -Value ('@("{0}")' -f [String]::Join('", "', $accessList))))

                            $accessListParam = ' -AccessList $accessList'

                        }

                        [void]$scriptCode.Add(('$snmpConfig                += New-HPOVSnmpConfiguration{0}{1}{2}{3}{4}{5}' -f $readCommunityParam, $snmpParam, $contactParam, $trapdestParam, $snmpV3UsersParam, $accessListParam))

                    }

                }

                if ($qos.configType -ne 'Passthrough')
                {

                    $qosConfigType = $qos.configType
                    $uClassType    = $qos.uplinkClassificationType
                    $dClassType    = $qos.downlinkClassificationType

                    [void]$scriptCode.Add('#--   Generating QoS Configuration "{0}" ' -f $qosConfigType)
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'qosConfigType' -Value ('"{0}"' -f $qosConfigType)))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'uClassType' -Value ('"{0}"' -f $uClassType)))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'dClassType' -Value ('"{0}"' -f $dClassType)))

                    $q = 1

                    ForEach ($trafficClass in $qos.qosTrafficClassifiers)
                    {

                        $ingressDot1pClassMappingParam = $ingressDscpClassMappingParam = $null

                        $className                = $trafficClass.qosTrafficClass.className
                        $realTime                 = $trafficClass.qosTrafficClass.realTime
                        $bandwidthShare           = $trafficClass.qosTrafficClass.bandwidthShare
                        $maxBandwidth             = $trafficClass.qosTrafficClass.maxBandwidth
                        $egressDot1pValue         = $trafficClass.qosTrafficClass.egressDot1pValue
                        $isEnabled                = $trafficClass.qosTrafficClass.enabled
                        $ingressDot1pClassMapping = $trafficClass.qosClassificationMapping.dot1pClassMapping
                        $ingressDscpClassMapping  = $trafficClass.qosClassificationMapping.dscpClassMapping

                        [void]$scriptCode.Add('#---- Generating QoS Traffic Class Mapping "{0}" ' -f $className)
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'dClanamessType' -Value ('"{0}"' -f $className)))
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'realTime' -Value ('${0}' -f $realTime)))
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'bandwidthShare' -Value ('{0}' -f $bandwidthShare)))
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'maxBandwidth' -Value ('{0}' -f $maxBandwidth)))
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'egressDot1pValue' -Value ('{0}' -f $egressDot1pValue)))

                        if ($null -ne $ingressDot1pClassMapping)
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ingressDot1pClassMapping' -Value ('{0}' -f [String]::Join(', ', $ingressDot1pClassMapping))))

                            $ingressDot1pClassMappingParam = ' -IngressDot1pClassMapping $ingressDot1pClassMapping'

                        }
                        
                        if ($null -ne $ingressDscpClassMapping)
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ingressDscpClassMapping' -Value ('"{0}"' -f [String]::Join('", "', $ingressDscpClassMapping))))

                            $ingressDscpClassMappingParam = ' -IngressDscpClassMapping $ingressDscpClassMapping'

                        }
                        
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'isEnabled' -Value ('${0}' -f $isEnabled)))

                        $VarName = 'trafficClass'
                        $Value = 'New-HPOVQosTrafficClass -Name $name -MaxBandwidth $maxBandwidth -BandwidthShare -RealTime:$realTime -EgressDot1pValue $egressDot1pValue{0}{1} -Enabled:$isEnabled' -f $ingressDot1pClassMappingParam, $ingressDscpClassMappingParam

                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix $VarName -Suffix $q -Value $Value))

                        $q++

                    }

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'QosConfig' -Value ('New-HPOVQosConfig -ConfigType {0} -UplinkClassificationType {1} -UplinkClassificationType {2} -TrafficClassifiers {3}' -f $qosConfigType, $uClassType, $dClassType, ([String]::Join(', ', (1..($q - 1) | % { '$trafficClass{0}' -f $_}))))))
                    $QosParam = ' -QosConfiguration $QosConfig'

                }

            }

            # Scopes
            Try
            {
            
                $ResourceScope = Send-HPOVRequest -Uri $lig.scopesUri -Hostname $ApplianceConnection
            
            }
            
            Catch
            {
            
                $PSCmdlet.ThrowTerminatingError($_)
            
            }

            $n = 1

            if (-not [String]::IsNullOrEmpty($ResourceScope.scopeUris))
            {

                ForEach ($scopeUri in $ResourceScope.scopeUris)
                {

                    $scopeName = Get-NamefromUri -Uri $scopeUri

                    $ScopeVarName = 'Scope'
                    $Value = 'Get-HPOVScope -Name "{0}"' -f $scopeName

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix $ScopeVarName -Suffix $n -Value $Value))

                    $n++

                }

                $ScopeParam = ' -Scope {0}' -f ([String]::Join(', ', (1..($n - 1) | % { '$Scope{0}' -f $_}))) 

            }

            [void]$scriptCode.Add(('{0}New-HPOVLogicalInterconnectGroup -Name $name -Bays $bayConfig{1}{2}{3}{4}{5}{6}{7}{8}{9}{10}' -f $LigVariable, $FabricModuleTypeParam, $FrameCountParam, $ICBaySetParam, $igmpParam, $intNetParam, $networkLoopProtectionParam, $EnhancedLLDPTLVParam, $LDPtaggingParam, $QosParam, $ScopeParam))

            DisplayOutput -Code $scriptCode
            
            # Process Uplink Sets
            Generate-uplinkSet-Script -InputObject $lig

            Insert-BlankLine

        }

        Function Generate-uplinkSet-Script ($InputObject)
        {

            $uplinkSets = $parentType = $RootLocationInfos = $subLocationInfo = $parentName = $enclosureType = $null
            $scriptCode = New-Object System.Collections.ArrayList

            switch ($InputObject.type)
            {

                {$_ -match 'uplink-set'}
                {

                    $parentType        = 'LogicalInterconnect'
                    $RootLocationInfos = 'portConfigInfos'
                    $subLocationInfo   = 'location'

                    Try
                    {
                
                        $parent = Send-HPOVRequest -Uri $InputObject.logicalInterconnectUri -Hostname $ApplianceConnection

                        $parentName    = $parent.name
                        $enclosureType = $parent.enclosureType
                        $interconnects = $parent.interconnectMap.interconnectMapEntries
                
                    }
                
                    Catch
                    {
                
                        $PSCmdlet.ThrowTerminatingError($_)
                
                    }

                    $uplinkSets = $InputObject

                }

                # Not supported
                {$_ -match 'sas-logical-interconnect'}
                {

                    $parentType        = 'SasLogicalInterconnectGroup'

                }

                default
                {

                    $parentType        = 'LogicalInterconnectGroup'
                    $RootLocationInfos = 'logicalPortConfigInfos'
                    $subLocationInfo   = 'logicalLocation'

                    $parent = $InputObject                        
            
                    $parentName    = $parent.Name
                    $enclosureType = $parent.enclosureType
                    $uplinkSets    = $parent.uplinkSets | sort-object Name
                    $interconnects = $parent.interconnectMapTemplate.interconnectMapEntryTemplates

                }

            }

            foreach ($upl in $uplinkSets)
            {

                $uplName            = $Upl.name
                $upLinkType         = if ($Upl.networkType -eq "Ethernet") { $Upl.ethernetNetworkType } else { $Upl.networkType }
                $ethMode            = $Upl.mode
                $networkURIs        = $upl.networkUris

                [void]$scriptCode.Add(('# -------------- Attributes for Uplink Set "{0}" associated to {1} "{2}"' -f $uplName, $parentType, $parentName))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $uplName)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'uplinkType' -Value ('"{0}"' -f $uplinkType)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'parentName' -Value ('"{0}"' -f $parentName)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'parent' -Value ('Get-HPOV{0} -Name $parentName' -f $parentType)))

                switch ($parentType)
                {

                    'LogicalInterconnect'
                    {

                        $uplLogicalPorts  = $Upl.portConfigInfos
                        $LocationPropName = 'location'
                        $ValuePropName    = 'value'

                    }

                    'LogicalInterconnectGroup'
                    {

                        $uplLogicalPorts  = $Upl.logicalportconfigInfos
                        $LocationPropName = 'logicalLocation'
                        $ValuePropName    = 'relativeValue'
                        
                    }

                }

                # ----------------------------
                # Find networks
                $netNamesArray = New-Object System.Collections.ArrayList
                $networkNames  = $null

                switch ($upl.networkType)
                {

                    'Ethernet'
                    {

                        $nativeNetURI = $Upl.nativeNetworkUri
                        $netTagtype   = $Upl.ethernetNetworkType
                        $lacpTimer    = $Upl.lacpTimer

                        if ($Null -ne $nativeNetURI)
                        {
                
                            $nativeNetname = Get-NamefromUri -Uri $nativeuri

                        }

                        foreach ($neturi in $networkUris)
                        {

                            $netName = Get-NamefromUri -Uri $neturi
                            [void]$netNamesArray.Add($netName)

                        }

                        foreach ($fcoeNetUri in $fcoeNetworkUris)
                        {

                            $netName = Get-NamefromUri -Uri $fcoeNetUri
                            [void]$netNamesArray.Add($netName)

                        }

                    }

                    'FibreChannel'
                    {

                        $fcMode  = $upl.fcMode

                        # //TODO: Is this even correct??
                        $fcSpeed = if ($Upl.FCSpeed) { $Upl.FCSpeed } else { 'Auto' }

                        foreach ($fcNetUri in $fcNetworkUris)
                        {

                            $netName = Get-NamefromUri -Uri $fcNetUri
                            [void]$netNamesArray.Add($netName)

                        }

                    }

                }
                    
                # ----------------------------
                #     Find uplink ports
                $UpLinkArray = New-Object System.Collections.ArrayList

                foreach ($logicalPort in $uplLogicalPorts)
                {
                    
                    $Speed          = $UpLinkLocation = $Port = $icm = $null

                    $ThisBayNumber  = ($logicalPort.$LocationPropName.locationEntries | ? Type -eq 'Bay').$ValuePropName
                    $ThisPortNumber = ($logicalPort.$LocationPropName.locationEntries | ? Type -eq 'Port').$ValuePropName
                    $ThisEnclosure  = ($logicalPort.$LocationPropName.locationEntries | ? Type -eq 'Enclosure').$ValuePropName

                    # Loop through Interconnect Map Entry Template items looking for the provided Interconnet Bay number
                    ForEach ($l in $interconnects) 
                    {

                        $ThisIcmEnclosureLocation = ($l.$LocationPropName.locationEntries | ? { $_.type -eq "Enclosure" -and $_.$ValuePropName -eq $ThisEnclosure}).$ValuePropName
                        $ThisIcmBayLocation       = ($l.$LocationPropName.locationEntries | ? { $_.type -eq "Bay" -and $_.$ValuePropName -eq $ThisBayNumber}).$ValuePropName

                        if ($enclosureType -eq $Syn12K) 
                        {

                            if ($ThisIcmBayLocation -and $l.enclosureIndex -eq $ThisEnclosure) 
                            {
										
                                $permittedInterconnectTypeUri = $l.permittedInterconnectTypeUri

                            }

                        }

                        else
                        {
                        
                            if ($l.$LocationPropName.locationEntries | Where-Object { $_.type -eq "Bay" -and $_.$ValuePropName -eq $ThisBayNumber }) 
                            {
										
                                $permittedInterconnectTypeUri = $l.permittedInterconnectTypeUri

                            }
                                                    
                        }
                        
                    } 

                    Try
                    {
                    
                        $PermittedInterConnectType = Send-HPOVRequest $permittedInterconnectTypeUri -Hostname $ApplianceConnection
                    
                    }
                    
                    Catch
                    {
                    
                        $PSCmdlet.ThrowTerminatingError($_)
                    
                    }
                    
                    # 1. Find port numbers and port names from permittedInterconnectType
                    $PortInfos     = $PermittedInterConnectType.PortInfos

                    # 2. Find Bay number and Port number on uplinksets
                    $ICLocation    = $icm.$RootLocationInfos.$subLocationInfo
                    $ICBay         = ($ICLocation | Where-Object Type -eq "Bay").$ValuePropName
                    $ICEnclosure   = ($IClocation | Where-Object Type -eq "Enclosure").$ValuePropName

                    # 3. Get faceplate port name
                    $ThisPortName   = ($PortInfos    | Where-Object PortNumber -eq $ThisPortNumber).PortName

                    if ($ThisEnclosure -eq -1)    # FC module
                    {

                        $UpLinkLocation = "Bay{0}:{1}" -f $ThisBayNumber, $ThisPortName   # Bay1:1
                    
                    }

                    else  # Synergy Frames or C7000
                    {

                        if ($enclosureType -eq $Syn12K) 
                        {

                            $UpLinkLocation = "Enclosure{0}:Bay{1}:{2}" -f $ThisEnclosure, $ThisBayNumber, $ThisPortName.Replace(":", ".")   # Enclosure#:Bay#:Q1.3; In $PortInfos, format is Q1:4, output expects Q1.4
                        
                        }

                        else # C7000
                        {

                            $UpLinkLocation = "Bay{0}:{1}" -f $ThisBayNumber, $ThisPortName.Replace(":", ".")   # Bay#:Q1.3; In $PortInfos, format is Q1:4, output expects Q1.4
                        
                        }

                    }

                    [void]$UpLinkArray.Add($UpLinkLocation)

                }

                $UpLinkArray.Sort()

                # Uplink Ports
                $uplinkPortParam    = $uplinkPortCode    = $null

                if ($UplinkArray) 
                {

                    $uplinkPortParam    = ' -UplinkPorts $uplinkPorts'
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'uplinkPorts' -Value ('"{0}"' -f [String]::Join('", "', $UpLinkArray.ToArray()))))

                }
                    
                # Networks
                $uplNetworkParam    = $uplNetworkCode = $null
                if ($netNamesArray.Count -gt 0)
                { 

                    $uplNetworkParam    = ' -Networks $networks'
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'networks' -Value ('"{0}" | Get-HPOVNetwork' -f [String]::Join('", "', $netNamesArray.ToArray()))))

                }
                
                $lacpTimerParam  =  $netAttributesParam = $uplNativeNetParam = $null

                # Uplink Type
                if ($uplinkType -eq 'FibreChannel')
                {

                    $netAttributesParam     = ' -fcUplinkSpeed $FCSpeed'
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'fcSpeed' -Value ('"{0}"' -f $fcSpeed)))

                }

                else # Ethernet-type
                {

                    if ($null -ne $nativeNetname)
                    {

                        $uplNativeNetParam = " -nativeEthnetwork $nativenetwork"
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'nativeNetwork' -Value ('Get-HPOVNetwork -Name "{0}"' -f $nativeNetname)))

                    }

                    if ($ethMode -ne 'Audo')
                    {

                        $netAttributesParam += ' -EthMode $ethMode'
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ethMode' -Value ('"{0}"' -f $ethMode)))
                        
                    }

                    if ($lacpTimer) 
                    {

                        $netAttributesParam += ' -lacptimer $lacpTimer'                        
                        [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'lacpTimer' -Value ('"{0}"' -f $lacpTimer)))

                    }

                }

                [void]$scriptCode.Add(('New-HPOVUplinkSet -InputObject $parent -Name $name -Type $uplinkType{0}{1}{2}{3}' -f $uplNetworkParam, $netAttributesParam, $uplinkPortParam, $uplNativeNetParam))

            }

            DisplayOutput -Code $scriptCode

        }

        Function Generate-EnclosureGroup-Script ($InputObject)
        {
            
            $scriptCode = New-Object System.Collections.ArrayList

            $EG     = $InputObject

            $name                   = $EG.name
            $description            = $EG.description
            $enclosureCount         = $EG.enclosureCount
            $powerMode              = $EG.powerMode
            $scopesUri              = $EG.scopesUri

            $manageOSDeploy         = $EG.osDeploymentSettings.manageOSDeployment
            $deploySettings         = $EG.osDeploymentSettings.deploymentModeSettings
            $deploymentMode         = $deploySettings.deploymentMode

            $ipV4AddressType        = $EG.ipAddressingMode
            $ipRangeUris            = $EG.ipRangeUris
            $ICbayMappings          = $EG.interConnectBayMappings | ? { $null -ne $_.logicalInterconnectGroupUri } | sort enclosureIndex, interconnectBay
            $EnclosurCount          = $EG.enclosureCount
            $enclosuretype          = $EG.enclosureTypeUri.Split('/')[-1]

            [void]$scriptCode.Add('# -------------- Attributes for enclosure group "{0}"' -f $name)
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $name)))

            # --- Find Enclosure Bay Mapping
            ###

            $enclosureCountParam = $IPv4AddressTypeParam = $ligMappingParam  = $null

            if ($ICbayMappings)
            {
                
                $BayHashtable = New-Object System.Collections.Specialized.OrderedDictionary

                $l = 1

                ForEach ($LIG in $ICBayMappings)
                {

                    $FrameID = $null

                    $thisLIGName = Get-NamefromUri -Uri $LIG.logicalInterconnectGroupURI

                    $LigVarName = '$lig{0}' -f $l

                    # Multi or specific frame configuration
                    if (-not [String]::IsNullOrEmpty($LIG.enclosureIndex))
                    {
                        
                        $FrameID     = 'Frame{0}' -f $LIG.enclosureIndex

                        if (-not ($BayHashtable.GetEnumerator() | ? Name -eq $FrameID))
                        {

                            $BayHashtable.Add($FrameID, (New-Object System.Collections.ArrayList))

                        }

                        if (-not ($BayHashtable.GetEnumerator() | ? Name -eq $FrameID).Value -eq $LigVarName)
                        {

                            # Use this hashtable to build the final string value for scriptCode
                            [Void]$BayHashtable.$FrameID.Add($LigVarName)
                    
                            $Value = 'Get-HPOVLogicalInterconnectGroup -Name "{0}"' -f $thisLIGName

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix $LigVarName -Value $Value))

                            $l++

                        }                        

                    }

                    else
                    {
                    
                        if (-not ($BayHashtable.GetEnumerator() | ? Name -eq $thisLIGName).Value -eq $LigVarName)
                        {

                            # Use this hashtable to build the final string value for scriptCode
                            [Void]$BayHashtable.Add($thisLIGName, $LigVarName)

                            $Value = 'Get-HPOVLogicalInterconnectGroup -Name "{0}"' -f $thisLIGName

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix $LigVarName -Value $Value))

                            $l++

                        }   
                    
                    }

                }

                if ($BayHashtable)
                {

                    $ligMappingParam        =  ' -LogicalInterconnectGroupMapping $LigMapping'

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'LigMapping' -Value '@{'))

                    $c = 1

                    ForEach ($l in $BayHashtable.GetEnumerator())
                    {

                        $endDelimiter = $SepHash

                        if ($c -eq $BayHashtable.Count)
                        {

                            $endDelimiter = $null

                        }

                        if ($l.Name.StartsWith("Frame"))
                        {

                            [void]$scriptCode.Add(("`t{0} = '{1}'{2}" -f $l.Name, [String]::Join("', '", $l.Value.ToArray()), $endDelimiter))

                        }

                        else
                        {

                            [void]$scriptCode.Add(("`t{0}{1}" -f $l.Value, $endDelimiter))
                        
                        }

                        $c++

                    }

                    [void]$scriptCode.Add('}')

                }
            
            }

            $addressPoolParam       = $null

            if ($enclosuretype -eq $SYN12K)
            {

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'enclosureCount' -Value ('{0}' -f $enclosureCount)))
                $enclosureCountParam    = ' -EnclosureCount $enclosureCount'

                #---- IP Address Pool
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ipV4AddressType' -Value ('"{0}"' -f $ipV4AddressType)))
                $addressPoolParam = ' -IPv4AddressType $ipV4AddressType'

                if($ipV4AddressType -eq 'IpPool')
                {

                    $RangeNames = New-Object System.Collections.ArrayList

                    foreach ($uri in $ipRangeUris)
                    {

                        $rangeName          = Get-NamefromUri -Uri $uri
                        [void]$RangeNames.Add('{0}' -f $rangeName)
                    
                    }

                    $addressPoolParam += ' -addressPool $addressPool'
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'addressPoolNames' -Value ('"{0}"' -f [String]::Join('", "', $RangeNames.ToArray()))))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'addressPool' -Value ('$addressPoolNames | % { Get-HPOVAddressPoolRange | ? name -eq $_ }')))
                    
                }

            }

            # --- OS Deployment with IS
            $OSdeploymentParam           = $null

            if ($manageOSDeploy)
            {

                $OSdeploymentParam      = ' -DeploymentNetworkType $deploymentMode'

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'deploymentMode' -Value ('"{0}"' -f $deploymentMode)))

                if ($deploymentMode -eq 'External')
                {

                    $deploynetworkname      = Get-NamefromUri -Uri $deploySettings.deploymentNetworkUri
                    $OSdeploymentParam     += ' -deploymentnetwork $deploymentnetwork'

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'deploynetworkname' -Value ('"{0}"' -f $deploynetworkname )))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'deploymentnetwork' -Value ('Get-HPOVnetwork -Name $deploynetworkname')))

                }

            }

            $powerModeParam = $null

            if ($null -ne $powerMode)
            {

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'powerMode' -Value ('"{0}"' -f $powerMode)))
                $powerModeParam         = ' -PowerRedundantMode $powerMode'

            }

            # Get the EG configuration script to add as a parameter
            Try
            {
            
                $uri = $EG.uri + '/script'
                $egScript = Send-HPOVRequest -Uri $uri -Hostname $ApplianceConnection
            
            }
            
            Catch
            {
            
                $PSCmdlet.ThrowTerminatingError($_)
            
            }

            $ConfigScriptParam = $null

            if ($null -ne $egScript)
            {

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'confScript' -Value ("'{0}'" -f $egScript)))
                $ConfigScriptParam = ' -ConfigurationScript $confScript'

            }

            # Scopes
            Try
            {
            
                $ResourceScope = Send-HPOVRequest -Uri $scopesUri -Hostname $ApplianceConnection
            
            }
            
            Catch
            {
            
                $PSCmdlet.ThrowTerminatingError($_)
            
            }

            $n = 1
            
            $ScopeParam = $null

            if (-not [String]::IsNullOrEmpty($ResourceScope.scopeUris))
            {

                ForEach ($scopeUri in $ResourceScope.scopeUris)
                {

                    $scopeName = Get-NamefromUri -Uri $scopeUri

                    $ScopeVarName = 'Scope'
                    $Value = 'Get-HPOVScope -Name "{0}"' -f $scopeName

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix $ScopeVarName -Suffix $n -Value $Value))

                    $n++

                }

                $ScopeParam = ' -Scope {0}' -f ([String]::Join(', ', (1..($n - 1) | % { '$Scope{0}' -f $_}))) 

            }

            [void]$scriptCode.Add(('New-HPOVEnclosureGroup -Name $name{0}{1}{2}{3}{4}{5}{6}' -f $enclosureCountParam, $liGMappingParam, $addressPoolParam, $OSdeploymentParam, $powerModeParam, $ConfigScriptParam, $ScopeParam))

            DisplayOutput -Code $scriptCode

        }

        Function Generate-LogicalEnclosure-Script ($InputObject)
        {
        
            $scriptCode =  New-Object System.Collections.ArrayList

            $LE     = $InputObject

            $name          = $LE.name
            $enclUris      = $LE.enclosureUris
            $EncGroupUri   = $LE.enclosuregroupUri
            $FWbaselineUri = $LE.firmware.firmwareBaselineUri
            $FWinstall     = $LE.firmware.forceInstallFirmware
            $scopesUri     = $LE.scopesUri

            $EGName        = Get-NamefromUri -Uri $EncGroupUri
            $enclNames     = ($enclUris | % { Get-NamefromUri -Uri $_ })

            $egParam       = ' -EnclosureGroup $eg'
            $enclParam     = ' -Enclosure ($enclosures | Select -First 1)'

            [void]$scriptCode.Add('# -------------- Attributes for logical enclosure "{0}"' -f $name)
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$name' -Value ('"{0}"' -f $name)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$egName' -Value ('"{0}"' -f $egName)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$eg' -Value ('Get-HPOVEnclosureGroup -Name $egName')))      
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$enclNames' -Value ('"{0}"' -f [String]::Join('", "', $enclNames))))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$enclosures' -Value '$enclNames | % { Get-HPOVenclosure -Name $_ }'))
                
            $fwparam = $null
            
            if ($FWbaselineUri)
            {

                $fwName  = Get-NamefromUri -Uri $FWbaselineUri
                $fwparam = ' -FirmwareBaseline $fwBaseline -ForceFirmwareBaseline $fwInstall'

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$fwName' -Value ('"{0}"' -f $fwName)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$fwBaseline' -Value 'Get-HPOVBaseline -SPPname $fwName'))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$fwInstall' -Value ('${0}' -f $fwInstall)))

            }

            # Scopes
            $ScopeParam = $null

            Try
            {
            
                $ResourceScope = Send-HPOVRequest -Uri $scopesUri -Hostname $ApplianceConnection
            
            }
            
            Catch
            {
            
                $PSCmdlet.ThrowTerminatingError($_)
            
            }

            $n = 1

            if (-not [String]::IsNullOrEmpty($ResourceScope.scopeUris))
            {

                ForEach ($scopeUri in $ResourceScope.scopeUris)
                {

                    $scopeName = Get-NamefromUri -Uri $scopeUri

                    $ScopeVarName = 'Scope'
                    $Value = 'Get-HPOVScope -Name "{0}"' -f $scopeName

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix $ScopeVarName -Suffix $n -Value $Value))

                    $n++

                }

                $ScopeParam = ' -Scope {0}' -f ([String]::Join(', ', (1..($n - 1) | % { '$Scope{0}' -f $_}))) 

            }

            [void]$scriptCode.Add(('New-HPOVLogicalEnclosure -Name $name{0}{1}{2}{3}' -f $enclParam, $egParam, $fwParam, $ScopeParam))
        
            DisplayOutput -Code $scriptCode

        }

        Function Generate-ProfileTemplate-Script ($InputObject)
        {

            $scriptCode =  New-Object System.Collections.ArrayList

            $Type = ($ResourceCategoryEnum.GetEnumerator() | ? value -eq $InputObject.category).Name

            $name               = $InputObject.Name   
            $description        = $InputObject.Description 
            $spDescription      = $InputObject.serverprofileDescription
            $shtUri             = $InputObject.serverHardwareTypeUri
            $egUri              = $InputObject.enclosureGroupUri
            $sptUri             = $InputObject.serverProfileTemplateUri
            $serverUri          = $InputObject.serverHardwareUri
            $enclosureUri       = $InputObject.enclosureUri
            $enclosureBay       = $InputObject.enclosureBay
            $affinity           = $InputObject.affinity 
            $hideFlexNics       = $InputObject.hideUnusedFlexNics
            $macType            = $InputObject.macType
            $wwnType            = $InputObject.wwnType
            $snType             = $InputObject.serialNumberType       
            $iscsiType          = $InputObject.iscsiInitiatorNameType 
            $osdeploysetting    = $InputObject.osDeploymentSettings
            $scopesUri          = $InputObject.scopesUri

            [void]$scriptCode.Add(('# -------------- Attributes for {0} "{1}"' -f $Type, $name))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$name' -Value ('"{0}"' -f $name)))

            # Param and code
            Try
            {
            
                $sht     = Send-HPOVRequest -Uri $shtUri -Hostname $ApplianceConnection
                $shtName = $sht.name
            
            }
            
            Catch
            {
            
                $PSCmdlet.ThrowTerminatingError($_)
            
            }
            
            # ------- Descriptions
            $descriptionParam   = $spdescriptionParam = $null
            
            if ($description)
            {

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$description' -Value ('"{0}"' -f $description)))
                $descriptionParam = ' -Description $description'

            }

            if ($spdescription)
            {

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$spdescription' -Value ('"{0}"' -f $spdescription)))
                $spdescriptionParam = ' -ServerProfileDescription $spdescription '
                
            }

            # ------- Server hardware assigned
            $serverAssignParam = $null

            if (-not [String]::IsNullOrWhiteSpace($serverUri))
            {

                $serverName = Get-NamefromUri -uri $serverUri

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$server' -Value ('Get-HPOVServer -Name "{0}"' -f $serverName)))

                $serverAssignParam = ' -AssignmentType Server -Server $server'

            }

             # -------- SHT and EG
            $shtParam = $egParam = $null

            if ([String]::IsNullOrWhiteSpace($serverUri))
            {

                if ($Type -eq 'ServerProfile' -and [String]::IsNullOrWhiteSpace($enclosureUri))
                {

                    $serverAssignParam = ' -AssignmentType Unassigned'

                }

                elseif ($Type -eq 'ServerProfile' -and -not [String]::IsNullOrWhiteSpace($enclosureUri))
                {

                    $enclosureName = Get-NamefromUri -uri $enclosureUri

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'enclosure' -Value ('Get-HPOVEnclosure -Name "{0}"' -f $enclosureName)))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'bay' -Value $enclosureBay))
                    $serverAssignParam = ' -AssignmentType Bay -Enclosure $enclosure -Bay $bay' 

                }

                # ------- SHT
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$shtName' -Value ('"{0}"' -f $shtName)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$sht' -Value 'Get-HPOVServerHardwareType -Name $shtName'))

                $shtParam = ' -ServerHardwareType $sht'

                # ------- EG, if BL or SY, and only needed if SPT or unassigned server profile
                if (-not [String]::IsNullOrWhiteSpace($egUri))
                {
            
                    Try
                    {
                
                        $eg = Send-HPOVRequest -Uri $egUri -Hostname $ApplianceConnection
                        $egName = $eg.name
                
                    }
                
                    Catch
                    {
                
                        $PSCmdlet.ThrowTerminatingError($_)
                
                    }

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$egName' -Value ('"{0}"' -f $egName)))
                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$eg' -Value 'Get-HPOVEnclosureGroup -Name $egName'))

                    $egParam = ' -EnclosureGroup $eg'
            
                }

            }

            # ------- Affinity
            $affinityParam = $null

            if (-not [String]::IsNullOrWhiteSpace($affinity))
            {

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$affinity' -Value ('"{0}"' -f $affinity)))

                $affinityParam = ' -Affinity $affinity'

            }

            # ------- Firmware
            $fwParam = $fwCode = $null

            $fw          = $InputObject.firmware
            $isFwManaged = $fw.manageFirmware

            if ($isFWmanaged)
            {

                $FwCode, $fwParam = Generate-ManageFirmware-Script -Fw $fw

                ForEach ($line in $FwCode.ToArray())
                {

                    [void]$scriptCode.Add($line)

                }
                
            }

            # ------- Network Connections
            $ConnectionsParam   = $null
            $ConnectionSettings = $InputObject.connectionSettings
            $ListofConnections  = $ConnectionSettings.connections
            $ConnectionVarNames = New-Object System.Collections.ArrayList

            if ($ConnectionSettings.manageConnections -and $ListofConnections.Count -gt 0)
            {

                ForEach ($c in $ListofConnections)
                {

                    $conCode, $varstr = Generate-NetConnection-Script -Conn $c -MacAssignType $InputObject.macType -WwnAssignType $InputObject.wwnType

                    ForEach ($line in $conCode.ToArray())
                    {

                        [void]$scriptCode.Add($line)

                    }

                    [void]$ConnectionVarNames.Add($varstr)

                }

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$connections' -Value ([String]::Join(', ', $ConnectionVarNames.ToArray()))))
                
                $ConnectionsParam = ' -Connections $connections'
            
            }

            elseif (-not $ConnectionSettings.manageConnections)
            {
            
                $ConnectionsParam = ' -ManageConnections $False'
            
            }

            # ---------- OS Deployment Settings
            $osDeploymentParam = $null

            if (-not [String]::IsNullOrWhiteSpace($osdeploysetting.osDeploymentPlanUri))
            {

                [void]$scriptCode.Add('# -------------- Attributes for OS deployment settings')

                $osDeploymentParam = ' -OSDeploymentPlan $osDeploymentPlan -OSDeploymentPlanAttributes $planAttribs'

                $osDeployPlanUri = $osdeploysetting.osDeploymentPlanUri
                $planAttributes = $osdeploysetting.osCustomAttributes | Sort Name

                $deployPlanName = Get-NamefromUri -Uri $osDeployPlanUri

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'planName' -Value ('"{0}"' -f $deployPlanName)))
				[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'osDeploymentPlan' -Value 'Get-HPOVOsDeploymentPlan -Name $planName'))   
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'planAttribs' -Value 'Get-HPOVOsDeploymentPlanAttribute -InputObject $osDeploymentPlan'))
                
                ForEach ($attrib in $planAttributes)
                {

                    # Set value
                    if ($attrib.Name -match 'Password')
                    {

                        $value = 'Read-Host -Prompt "Provide required password"'

                    }

                    else
                    {

                        $value = '"{0}"' -f $attrib.Value

                    }

					[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'CustomAttribs' -Value '@()'))
                    [void]$scriptCode.Add(('($planAttribs | Where-Object name -eq "{0}").value = {1}' -f $attrib.Name, $value))

                    # Save into new array
                    [void]$scriptCode.Add(('$CustomAttribs     += $planAttribs | Where-Object name -eq "{0}"' -f $attrib.Name))

                }

            }

            # ------- Local Storage Connections
            $LOCALStorageParam = $null
            $ListofControllers                  = $InputObject.localStorage

            if ($ListofControllers.controllers.Count -gt 0)
            {

                $LOCALStorageCode, $vars      = Generate-LocalStorageController-Script -LocalStorageConfig $ListofControllers

                ForEach ($line in $LOCALStorageCode.ToArray())
                {

                    [void]$scriptCode.Add($line)

                }

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'controllers' -Value ('{0}' -f [String]::Join(', ', $vars.ToArray()))))
                
                $LOCALStorageParam              = ' -LocalStorage -StorageController $controllers'
                
            }

            # ---------- SAN storage Connection
            $SANStorageParam = $null

            $SANStorageCfg  = $InputObject.SanStorage
            $ManagedStorage = $InputObject.SanStorage.manageSanStorage

            if ($ManagedStorage)
            {

                $hostOSType       = $ServerProfileSanManageOSType[$SANStorageCfg.hostOSType]
                $IsManagedSAN     = $SANStorageCfg.manageSanStorage
                $volumeAttachment = $SANStorageCfg.volumeAttachments

                [void]$scriptCode.Add('# -------------- Attributes for SAN Storage')
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'osType' -Value ('"{0}"' -f $hostOSType)))

                $SANStorageCode, $vars      = Generate-SANStorage-Script -SANStorageConfig $SANStorageCfg

                ForEach ($line in $SANStorageCode.ToArray())
                {

                    [void]$scriptCode.Add($line)

                }

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'volumeAttachments' -Value ('{0}' -f [String]::Join(', ', $vars.ToArray()))))
                
                $SANStorageParam              = ' -SanStorage -HostOsType $osType -StorageVolume $volumeAttachments'

            }

            # ---------- Boot Settings
            $bootManageParam = $null

            $bo                 = $InputObject.boot
            $isManageBoot       = $bo.manageBoot

            $bm                 = $InputObject.bootMode
            $isbootOrderManaged = $bm.manageMode

            if ($isManageBoot)
            {

                [void]$scriptCode.Add('# -------------- Attributes for BIOS Boot Mode settings')

                $bootMode       = $bm.mode
                $pxeBootPolicy  = $bm.pxeBootPolicy
                $secureBoot     = $bm.secureBoot

                # Set BIOS Boot Mode, PXE boot policy and secure boot
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'manageboot' -Value ('${0}' -f $isManageBoot)))
                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'biosBootMode' -Value ('"{0}"' -f $bootMode)))

                $bootManageParam = ' -ManageBoot $manageboot -BootMode $biosBootMode'

                if (-not [String]::IsNullOrWhiteSpace($bootPXE))
                {

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'pxeBootPolicy' -Value ('"{0}"' -f $pxeBootPolicy)))

                    $bootManageParam += ' -PxeBootPolicy $pxeBootPolicy'

                }

                if ($secureBoot -ne 'Unmanaged')
                {

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'secureBoot' -Value ('"{0}"' -f $secureBoot)))

                    $bootManageParam += ' -SecureBoot $secureBoot'

                }

            }

            if ($isbootOrderManaged)
            {

                [void]$scriptCode.Add('# -------------- Attributes for BIOS order settings')

                $bootOrder = '"{0}"' -f [String]::Join('", "', $bo.order)

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'bootOrder' -Value ('{0}' -f $bootOrder)))

                $bootManageParam = ' -BootOrder $bootOrder'

            }

            # ---------- BIOS Settings
            $biosParam = $null

            $bios = $InputObject.bios

            $isBiosManaged      = $bios.manageBios

            if ($isBiosManaged)
            {

                $biosParam = ' -Bios'

                $biosSettings   = $bios.overriddenSettings

                if ($biosSettings.Count -gt 0)
                {
                    [void]$scriptCode.Add('# -------------- Attributes for BIOS settings')

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'biosSettings' -Value ('@{0}' -f $OpenArray)))

                    $_b = 1

                    ForEach ($b in $biosSettings)
                    {

                        $endDelimiter = $Comma

                        if ($_b -eq $biosSettings.Count)
                        {

                            $endDelimiter = $null

                        }

                        [void]$scriptCode.Add(("`t@{0}id = '{1}'; value = '{2}'{3}{4}" -f $OpenDelim, $b.id, $b.value, $CloseDelim, $endDelimiter))

                        $_b++

                    }

                    [void]$scriptCode.Add($CloseArray)
                
                    $biosParam += ' -BootSettings $biosSettings'

                }

            }

            # ---------- Advanced Settings 
            $AdvancedSettingsParam    = $null
            $hideUnusedFlexNics       = $InputObject.hideUnusedFlexNics
            $macType                  = $InputObject.macType
            $wwnType                  = $InputObject.wwnType
            $serialNumberType         = $InputObject.serialNumberType
            $iscsiInitiatorNameType   = $InputObject.iscsiInitiatorNameType

            $AdvancedSettings = New-Object System.Collections.ArrayList

            if ($hideFlexNics -and $sht.capabilities -contains 'VCConnections')
            {

                [void]$AdvancedSettings.Add('hideFlexNics')
                
            }

            if ($macType -ne 'Virtual' -and $sht.capabilities -contains 'VirtualMAC')
            {

                [void]$AdvancedSettings.Add('macType')

            }

            if ($wwnType -ne 'Virtual' -and $sht.capabilities -contains 'VirtualWWN')
            {

                [void]$AdvancedSettings.Add('wwnType')

            }

            if ($serialNumberType -ne 'Virtual' -and $sht.capabilities -contains 'VirtualUUID')
            {

                [void]$AdvancedSettings.Add('serialNumberType')

            }

            if ($iscsiInitiatorNameType -ne 'AutoGenerated' -and $sht.capabilities -contains 'VCConnections')
            {

                [void]$AdvancedSettings.Add('iscsiInitiatorNameType')

            }

            if ($AdvancedSettings.Count -gt 0)
            {

                [void]$scriptCode.Add('# -------------- Attributes for advanced settings')

                ForEach ($advSetting in $AdvancedSettings)
                {

                    switch ($advSetting)
                    {

                        'hideFlexNics'
                        {

                            $AdvancedSettingsParam += ' -HideUnusedFlexNics $true'

                        }

                        'macType'
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'macType' -Value ('"{0}"' -f $macType)))                            
                            $AdvancedSettingsParam += ' -MacAssignment $macType'

                        }

                        'wwnType'
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'wwnType' -Value ('"{0}"' -f $wwnType)))   
                            $AdvancedSettingsParam += ' -WwnAssignment $wwnType'

                        }

                        'serialNumberType'
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'serialNumberType' -Value ('"{0}"' -f $serialNumberType)))  
                            $AdvancedSettingsParam += ' -SnAssignment $serialNumberType'
                            
                        }

                        'iscsiInitiatorNameType'
                        {

                            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'iscsiInitiatorType' -Value ('"{0}"' -f $iscsiInitiatorNameType)))  
                            $AdvancedSettingsParam += ' -IscsiInitiatorNameAssignmet $iscsiInitiatorType'

                        }

                    }

                }

            }

            # Scopes
            $ScopeParam = $null

            Try
            {
            
                $ResourceScope = Send-HPOVRequest -Uri $scopesUri -Hostname $ApplianceConnection
            
            }
            
            Catch
            {
            
                $PSCmdlet.ThrowTerminatingError($_)
            
            }

            $n = 1

            if (-not [String]::IsNullOrEmpty($ResourceScope.scopeUris))
            {

                ForEach ($scopeUri in $ResourceScope.scopeUris)
                {

                    $scopeName = Get-NamefromUri -Uri $scopeUri

                    $ScopeVarName = 'Scope'
                    $Value = 'Get-HPOVScope -Name "{0}"' -f $scopeName

                    [void]$scriptCode.Add((Generate-CustomVarCode -Prefix $ScopeVarName -Suffix $n -Value $Value))

                    $n++

                }

                $ScopeParam = ' -Scope {0}' -f ([String]::Join(', ', (1..($n - 1) | % { '$Scope{0}' -f $_}))) 

            }

            [void]$scriptCode.Add(('New-HPOV{0} -Name $name{1}{2}{3}{4}{5}{6}{7}{8}{9}{10}{11}{12}{13}{14}{15}' -f $Type, $descriptionParam, $spdescriptionParam, $serverAssignParam, $shtParam, $egParam, $affinityParam, $osDeploymentParam, $fwParam, $ConnectionsParam, $LOCALStorageParam, $SANStorageParam, $bootManageParam, $biosParam, $AdvancedSettingsParam, $ScopeParam))
        
            DisplayOutput -Code $scriptCode

		}
		
		Function Generate-osDeploymentServer-Script ($InputObject)
		{

			$scriptCode =  New-Object System.Collections.ArrayList   

			foreach ($osds in $InputObject)
			{

				$name                       = $osds.name
				$description                = $osds.description
				$mgmtNetworkUri             = $osds.mgmtNetworkUri
				$primaryActiveApplianceUri  = $osds.primaryActiveAppliance

				Try
				{

					$i3sAppliance               = Send-HPOVRequest -uri $primaryActiveApplianceUri

				}

				Catch
				{

					$PSCmdlet.ThrowTerminatingError($_)

				}
				
				$i3sApplianceName           = $i3sAppliance.cimEnclosureName

				$mgmtNetworkName            = Get-NameFromUri -uri $mgmtNetworkUri
				
				[void]$scriptCode.Add(('# -------------- Attributes for OS Deployment Server {0}' -f $name))
				[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'name' -Value ('"{0}"' -f $name)))
				[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ManagementNetwork' -Value ('Get-HPOVNetwork -Name "{0}" -Type Ethernet' -f $mgmtNetworkName)))
				[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ImageStreamerApplianceName' -Value ('"{0}"' -f $i3sApplianceName)))
				[void]$scriptCode.Add((Generate-CustomVarCode -Prefix 'ImageStreamerAppliance' -Value ('Get-HPOVImageStreamerAppliance | where cimEnclosurename -eq $ImageStreamerApplianceName')))
				
				$descriptionParam = ""

				if (-not [String]::IsNullOrWhiteSpace($description))
				{

					[void]$scriptCode.Add((enerate-CustomVarCode -Prefix 'description' -Value ('"{0}"' -f $description)))
					$descriptionParam       = ' -description $description'

				}

				[void]$scriptCode.Add(('New-HPOVOSDeploymentServer -Name $name -ManagementNetwork $ManagementNetwork -InputObject $ImageStreamerAppliance{0} ' -f $descriptionParam))
				
				DisplayOutput -Code $scriptCode

			}
			
		}

        # Internal helper
        Function Generate-ManageFirmware-Script
        {

            Param
            (

                $fw

            )

            $FwManagedCode = New-Object System.Collections.ArrayList
            $FwParam       = $null

            $fwInstallType  = $fw.firmwareInstallType
            $fwForceInstall = $fw.forceInstallFirmware
            $fwActivation   = $fw.firmwareActivationType
            $fwSchedule     = $fw.firmwareScheduleDateTime
            $fwBaseUri      = $fw.firmwareBaselineUri

            $sppName  = Get-NamefromUri -Uri $fwBaseUri

            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$sppName' -Value ('"{0}"' -f $sppName)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$fwBaseline' -Value 'Get-HPOVbaseline -SPPname $sppName'))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$fwInstallType' -Value ('"{0}"' -f $fwInstallType)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$fwForceInstall' -Value ('${0}' -f $fwforceInstall)))
            [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$fwActivation' -Value ('"{0}"' -f $fwActivation)))

            $fwParam = ' -firmware -Baseline $fwbaseline -FirmwareInstallMode $fwInstallType -ForceInstallFirmware:$fwForceInstall -FirmwareActivationMode $fwActivation'

            if (-not [string]::IsNullOrEmpty($fwSchedule))
            {

                [void]$scriptCode.Add((Generate-CustomVarCode -Prefix '$fwSchedule' -Value ('"{0}"' -f $fwSchedule)))
                $FwParam += ' -FirmwareActivateDateTime $fwSchedule'

            }

            Return $FwManagedCode, $FwParam

        }

        # Internal helper
        Function Generate-NetConnection-Script 
        {

            Param 
            (
            
                $Conn,

                $MacAssignType,

                $WwnAssignType
                
            )

            $NetworkTypeEnum = @{

                'ethernet-networks' = 'Get-HPOVNetwork -Type Ethernet';
                'fc-networks'       = 'Get-HPOVNetwork -Type FibreChannel';
                'network-sets'      = 'Get-HPOVNetworkSet'

            }
            
            $ScriptConnection   = New-Object System.Collections.ArrayList

            $connID             = $Conn.id
            $connName           = $Conn.name
            $ConnType           = $Conn.functionType
            $netUri             = $Conn.networkUri
            $portID             = $Conn.portID
            $requestedVFs       = $Conn.requestedVFs
            $bootSettings       = $Conn.boot

            $ConnectionVarName = '$Conn{0}' -f $connID

            Try
            {
            
                $thisNetwork = Send-HPOVRequest -Uri $netUri -Hostname $ApplianceConnection
            
            }
            
            Catch
            {
            
                $PSCmdlet.ThrowTerminatingError($_)
            
            }                

            $netName        = $thisNetwork.name 

            [void]$ScriptConnection.Add('# -------------- Attributes for connection "{0}"' -f $connID)
            [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$connID' -Value $ConnID))

            $connNameParam = $null

            if (-not [String]::IsNullOrWhiteSpace($connName))
            {

                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$connName' -Value ('"{0}"' -f $ConnName)))
                $connNameParam = ' -Name $connName'

            }

            [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$connType' -Value ('"{0}"' -f $ConnType)))
            [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$netName' -Value ('"{0}"' -f $netName)))
            [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$ThisNetwork' -Value ('{0} -Name $netName' -f $NetworkTypeEnum[$thisNetwork.category])))  # Will return the correct Get-HPOV Cmdlet name and syntax
            [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$portID' -Value ('"{0}"' -f $PortID)))
            
            $mac = $macParam = $null

            if ($MacAssignType -eq "UserDefined")
            {   

                $macParam      = ' -MacAssignment UserDefined'

                # Not sure why these replace statements are here.
                $mac           = $Conn.mac #-replace '[0-9a-f][0-9a-f](?!$)', '$&:'

                # Specific to handle SPT versus SP.  SPT will not have a MAC address value within the connection
                if (-not [String]::IsNullOrWhiteSpace($mac))
                {

                    $macParam += ' -mac $mac'
                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$mac' -Value ('"{0}"' -f $mac)))

                }

            }
        
            $wwpn         = $wwnn = $wwwnParam = $null

            if ($WwnAssignType -eq "UserDefined")
            {   

                # Not sure why these replace statements are here.
                $mac      = $Conn.mac  #-replace '[0-9a-f][0-9a-f](?!$)', '$&:'   # Format 10:00:11
                $wwpn     = $Conn.wwpn #-replace '[0-9a-f][0-9a-f](?!$)', '$&:'
                $wwnn     = $Conn.wwnn #-replace '[0-9a-f][0-9a-f](?!$)', '$&:'
                $wwnParam = ' -WwnAssignment UserDefined'

                if (-not [String]::IsNullOrWhiteSpace($wwpn))
                {

                    $wwnParam += ' -Wwpn $wwpn -Wwnn $wwnn'

                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$wwpn' -Value ('"{0}"' -f $wwpn)))
                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$wwnn' -Value ('"{0}"' -f $wwnn)))

                }
                
            }

            $requestedMbps      = $Conn.requestedMbps

            if ($null -eq $requestedMbps)
            {

                $requestedMbps = '"Auto"'
            
            }
            
            $allocatededMbps    = $Conn.allocatedMbps
            $maximumMbps        = $Conn.maximumMbps

            $mbpsParam = $mbpsCode = $null

            $mbpsParam          = ' -RequestedBW $requestedMbps'
            [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$requestedMbps' -Value ('{0}' -f $requestedMbps)))

            # ---- lag
            $lagName  = $Conn.lagName

            $lagParam = $null

            if ($lagName)
            {

                $lagParam            = ' -LagName $lagName'
                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$lagName' -Value ('"{0}"' -f $lagName)))
                
            }

            #--- Virtual Functions
            $requestedVfsParam = $null

            if (($requestedVFs -gt 0 -or $requestedVFs -eq 'Auto') -and $bootSettings.ethernetBootType -ne 'iSCSI' -and $ConnType -ne 'iSCSI')
            {

                if ($requestedVFs -eq 'Auto')
                {

                    $requestedVFs = '"{0}"' -f $requestedVFs

                }

                $requestedVfsParam   = ' -Virtualfunctions $requestedVFs'
                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$requestedVFs' -Value ('{0}' -f $requestedVFs)))
                    
            }

            $bootSettingsParam  = $bootTargetParam = $null
            
            $bootPriority       = $bootSettings.priority   
            $bootVolumeSource   = $bootSettings.bootVolumeSource

            if ($bootPriority -ne 'NotBootable')
            {

                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$bootPriority' -Value ('"{0}"' -f $bootPriority)))
                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$volSource' -Value ('"{0}"' -f $bootVolumeSource)))

                $bootSettingsParam = ' -Bootable -Priority $bootPriority -BootVolumeSource $volSource'

                if ($bootVolumeSource -eq 'UserDefined')
                {

                    switch ($ConnType)
                    {

                        'FibreChannel'
                        {

                            ForEach ($target in $bootSettings.targets)
                            {

                                $bootTarget = [regex]::Replace($target.arrayWwpn, '[0-9a-f][0-9a-f](?!$)', '$&:')
                                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$bootTarget' -Value ('"{0}"' -f $bootTarget)))

                                $targetLun = $target.lun
                                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$targeLun' -Value ('{0}' -f $targetLun)))

                                $bootTargetParam = ' -TargetWwpn $bootTarget -LUN $targetLun'

                            }
                            
                        }

                        # Both HW and SW iSCSI connection support
                        default
                        {

                            # Where address policy for connection resides
                            $ipv4Settings = $Conn.ipv4
                            $addressSource = $ipv4Settings.ipAddressSource
                            $IPv4address   = $ipv4Settings.address
                            $IPv4Subnet    = $ipv4Settings.subnetMask
                            $IPv4gateway   = $ipv4Settings.gateway

                            [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$addressSource' -Value ('"{0}"' -f $addressSource)))

                            $bootTargetParam = ' -IscsiIPv4AddressSource $addressSource'

                            if ($addressSource -eq 'UserDefined')
                            {

                                if (-not [String]::IsNullOrWhiteSpace($IPv4address))
                                {

                                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$IPv4address' -Value ('"{0}"' -f $IPv4address)))
                                
                                    $bootTargetParam += ' -IscsiIPv4Address $IPv4address'

                                }

                                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$IPv4Subnet' -Value ('"{0}"' -f $IPv4Subnet)))
                                
                                $bootTargetParam += ' -IscsiIPv4SubnetMask $IPv4Subnet'

                                if (-not [String]::IsNullOrWhiteSpace($IPv4gateway))
                                {

                                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$IPv4gateway' -Value ('"{0}"' -f $IPv4gateway)))
                                
                                    $bootTargetParam += ' -IscsiIPv4Gateway $IPv4gateway'

                                }

                            }

                            # Where boot target and CHAP settings reside
                            $iSCSISettings        = $bootSettings.iscsi
                            $initiatorSource      = $iSCSISettings.initiatorNameSource
                            $initiatorName        = $iSCSISettings.initiatorName
                            $bootTargetIqn        = $iSCSISettings.bootTargetName
                            $bootTargetLun        = $iSCSISettings.bootTargetLun
                            $firstBootTargetIP    = $iSCSISettings.firstBootTargetIp
                            $firstBootTargetPort  = $iSCSISettings.firstBootTargetPort
                            $secondBootTargetIP   = $iSCSISettings.secondBootTargetIP
                            $secondBootTargetPort = $iSCSISettings.secondBootTargetPort
                            $chapLevel            = $iSCSISettings.chapLevel
                            $chapName             = $iSCSISettings.chapName
                            $mutualChapName       = $iSCSISettings.mutualChapName

                            # Initiator Name
                            if (-not [String]::IsNullOrWhiteSpace($initiatorName) -and $initiatorSource -eq 'UserDefined')
                            {

                                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$profileInitiatorName' -Value ('"{0}"' -f $initiatorName)))
                                
                                $bootTargetParam += ' -ISCSIInitatorName $profileInitiatorName'

                            }

                            # Target IQN and LUN
                            if (-not [String]::IsNullOrWhiteSpace($bootTargetIqn))
                            {

                                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$bootTargetIqn' -Value ('"{0}"' -f $bootTargetIqn)))
                                
                                $bootTargetParam += ' -IscsiBootTargetIqn $bootTargetIqn'

                                if (-not [String]::IsNullOrWhiteSpace($bootTargetLun))
                                {

                                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$bootTargetLun' -Value ('"{0}"' -f $bootTargetLun)))
                                
                                    $bootTargetParam += ' -LUN $bootTargetLun'

                                }

                            }

                            # First boot target IP
                            if (-not [String]::IsNullOrWhiteSpace($firstBootTargetIP))
                            {

                                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$firstBootTargetIP' -Value ('"{0}"' -f $firstBootTargetIP)))
                                
                                $bootTargetParam += ' -IscsiPrimaryBootTargetAddress $firstBootTargetIP'

                                if ($firstBootTargetPort -ne 3260)
                                {

                                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$firstBootTargetPort' -Value ('{0}' -f $firstBootTargetPort)))
                                
                                    $bootTargetParam += ' -IscsiPrimaryBootTargetPort $firstBootTargetPort'

                                }

                            }

                            # Second boot target IP
                            if (-not [String]::IsNullOrWhiteSpace($secondBootTargetIP))
                            {

                                [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$secondBootTargetIP' -Value ('"{0}"' -f $secondBootTargetIP)))
                                
                                $bootTargetParam += ' -IscsiSecondaryBootTargetAddress $secondBootTargetIP'

                                if ($firstBootTargetPort -ne 3260)
                                {

                                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$secondBootTargetPort' -Value ('{0}' -f $secondBootTargetPort)))
                                
                                    $bootTargetParam += ' -IscsiSecondaryBootTargetPort $secondBootTargetPort'

                                }

                            }

                            # CHAP settings
                            if ($chapLevel -ne 'None')
                            {

                                # Only needed for SPT
                                if (-not [String]::IsNullOrWhiteSpace($chapName))
                                {

                                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$chapName' -Value ('"{0}"' -f $chapName)))

                                    $bootTargetParam += ' -ChapName $chapName'

                                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$chapSecret' -Value 'Read-Host -AsSecureString -Prompt "Provide CHAP password"'))

                                    $bootTargetParam += ' -ChapSecret $chapSecret'

                                }

                                # Needed for SPT or if not MutualChap policy
                                if (-not [String]::IsNullOrWhiteSpace($mutualChapName))
                                {

                                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$mutualChapName' -Value ('"{0}"' -f $mutualChapName)))

                                    $bootTargetParam += ' -MutualChapName $mutualChapName'

                                    [void]$ScriptConnection.Add((Generate-CustomVarCode -Prefix '$mutualChapSecret' -Value 'Read-Host -AsSecureString -Prompt "Provide mutual CHAP password"'))

                                    $bootTargetParam += ' -MutualChapSecret $mutualChapSecret'

                                }

                            }

                        }

                    }
                    
                }

            }

            $Value = 'New-HPOVServerProfileConnection -ConnectionID $connID{0} -ConnectionType $connType -Network $ThisNetwork -PortId $portID{1}{2}{3}{4}{5}{6}{7}' -f $connNameParam, $macParm, $wwnParam, $requestedVFsParam, $mbpsParam, $lagParam, $bootSettingsParam, $bootTargetParam
            $Cmd = Generate-CustomVarCode -Prefix $ConnectionVarName -Value $Value
        
            [void]$ScriptConnection.Add($Cmd)

            Return $ScriptConnection, $ConnectionVarName

        }

        # Internal helper
        Function Generate-LocalStorageController-Script 
        {

            Param 
            ( 
                
                $LocalStorageConfig
            
            )

            $LDAcceleratorEnum = @{

                ControllerCache = 'Enabled';
                IOBypass        = 'SsdSmartPath';
                None            = 'Disabled';
                Unmanaged       = 'Unmanaged'

            }

            $ScriptController        = New-Object System.Collections.ArrayList
            $ControllerVarNames      = New-Object System.Collections.ArrayList

            $SasLogicalJBODs = $LocalStorageConfig.sasLogicalJBODs

            $c = 1
            $l = 1  # Needed here so that LogicalDiskVarName num doesn't overlap with other controllers present with their own logical disks

            ForEach ($controller in $LocalStorageConfig.controllers)
            {

                $LogicalDiskVarNames = New-Object System.Collections.ArrayList

                $deviceSlot    = $controller.deviceSlot
                $mode          = $controller.mode
                $initialize    = $controller.initialize
                $writeCache    = $controller.driveWriteCache
                $importCfg     = $controller.importConfiguration
				$logicalDrives = $controller.logicalDrives

                $ControllerVarName = '$controller{0}' -f $c

                [void]$ControllerVarNames.Add($ControllerVarName)

                if ($importCfg)
                {

                    $importCfgParam = ' -ImportExistingConfiguration'

                }

                else
                {
                
                    ForEach ($ld in $logicalDrives)
                    {

		    			$writeCacheParam = $initializeParam = $importCfgParam = $LogicalDisksParam = $null

                        $LogicalDiskVarName = '$LogicalDisk{0}' -f $l

                        [void]$LogicalDiskVarNames.Add($LogicalDiskVarName)

                        $name             = $ld.name
                        $RaidLevel        = $ld.raidLevel
                        $bootable         = $ld.bootable
                        $numPhysDrives    = $ld.numPhysicalDrives
                        $driveTech        = if ([String]::IsNullOrWhiteSpace($ld.driveTechnology)) { 'Auto' } else { $LogicalDiskCmdletTypeEnum[$ld.driveTechnology] }
                        $accelerator      = $ld.accelerator
                        $sasLogicalJbodId = $ld.sasLogicalJBODId
                        $sasLogicalJbod   = $SasLogicalJBODs | ? { $_.deviceSlot -eq $deviceSlot -and $_.id -eq $sasLogicalJbodId }

                        # Look for immediate attached disks, not D3940
                        if (-not [String]::IsNullOrEmpty($name) -and [String]::IsNullOrEmpty($sasLogicalJbodId))
                        {

                            if ($null -eq $driveTech)
                            {

                                $driveTech = 'Auto'

                            }

                            [void]$ScriptController.Add(('# -------------- Attributes for logical disk "{0}({1})"' -f $name, $RaidLevel))
                            [void]$ScriptController.Add((Generate-CustomVarCode -Prefix "ldName" -Value ('"{0}"' -f $name)))
                            [void]$ScriptController.Add((Generate-CustomVarCode -Prefix "raidLevel" -Value ('"{0}"' -f $RaidLevel)))
                            [void]$ScriptController.Add((Generate-CustomVarCode -Prefix "numPhysDrives" -Value ('{0}' -f $numPhysDrives)))
                            [void]$ScriptController.Add((Generate-CustomVarCode -Prefix "driveTech" -Value ('"{0}"' -f $driveTech)))

                            $LogicalDiskParams = ' -Raid $raidLevel -NumberofDrives $numPhysDrives -DriveType $driveTech'

                            if ($bootable)
                            {

                                $LogicalDiskParams += ' -Bootable $True'

                            }

                            if ($accelerator -ne 'Unmanaged')
                            {

                                [void]$ScriptController.Add((Generate-CustomVarCode -Prefix "accelerator" -Value ('"{0}"' -f $LDAcceleratorEnum[$accelerator])))

                                $LogicalDiskParams += ' -Accelerator $accelerator'

                            }

                            # Internal drive configuration, so use -StorageLocation Internal 
                            if ($deviceSlot -match 'Mezz')
                            {

                                [void]$ScriptController.Add((Generate-CustomVarCode -Prefix "location" -Value 'Internal'))

                                $LogicalDiskParams += ' -StorageLocation $location'

                            }

                        }

                        # Synergy D3940 RAID disks
                        else
                        {

                            $sasLJBODName          = $sasLogicalJbod.name
                            $sasLJBODNumPhysDrives = $sasLogicalJbod.numPhysicalDrives
                            $sasLJBODMinDriveSize  = $sasLogicalJbod.driveMinSizeGB
                            $sasLJBODMaxDriveSize  = $sasLogicalJbod.driveMaxSizeGB
                            $sasLJBODdriveTech     = if ([String]::IsNullOrWhiteSpace($sasLogicalJbod.driveTechnology)) { 'Auto' } else { $LogicalDiskCmdletTypeEnum[$sasLogicalJbod.driveTechnology] }
                            $sasLJBODeraseData     = $sasLogicalJbod.eraseData
                    
                            [void]$ScriptController.Add(('# -------------- Attributes for RAID logical JBOD "{0}" ({1})' -f $sasLJBODName, $deviceSlot))
                            [void]$ScriptController.Add((Generate-CustomVarCode -Prefix "ldname" -Value ('"{0}"' -f $sasLJBODName)))
                            [void]$ScriptController.Add((Generate-CustomVarCode -Prefix "numPhysDrives" -Value ('{0}' -f $sasLJBODNumPhysDrives)))

			    			[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "minDriveSize" -Value ('{0}' -f $sasLJBODMinDriveSize)))
			    			[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "maxDriveSize" -Value ('{0}' -f $sasLJBODMaxDriveSize)))
 			    			[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "driveTech" -Value ('"{0}"' -f $sasLJBODdriveTech)))
						
 			    			$LogicalDiskParams += ' -MinDriveSize $minDriveSize -MaxDriveSize $maxDriveSize -DriveType $driveTech'

                            if ($sasLJBODeraseData)
                            {

                                [void]$ScriptController.Add((Generate-CustomVarCode -Prefix "eraseDataOnDelete" -Value ('${0}' -f $sasLJBODeraseData)))

                                $LogicalDiskParams += ' -EraseDataOnDelete $eraseDataOnDelete' 

                            }
                        
                        }

                        $Value = 'New-HPOVServerProfileLogicalDisk -Name $ldName{0}' -f $LogicalDiskParams
                        $Cmd = Generate-CustomVarCode -Prefix $LogicalDiskVarName -Value $Value
    
                        [void]$ScriptController.Add($Cmd)

                        $l++

    				}
					
					# Exclusively for D3940 Logical JBOD within the controller
					ForEach ($sasJBOD in ($SasLogicalJBODs | Where deviceSlot -eq $deviceSlot))
					{

						$LogicalDiskParams = $null

						$LogicalDiskVarName = '$LogicalDisk{0}' -f $l

									[void]$LogicalDiskVarNames.Add($LogicalDiskVarName)

						$sasLJBODName          = $sasJBOD.name
						$sasLJBODNumPhysDrives = $sasJBOD.numPhysicalDrives
						$sasLJBODMinDriveSize  = $sasJBOD.driveMinSizeGB
						$sasLJBODMaxDriveSize  = $sasJBOD.driveMaxSizeGB
						$sasLJBODdriveTech     = $LogicalDiskCmdletTypeEnum[$sasJBOD.driveTechnology]
						$sasLJBODeraseData     = $sasJBOD.eraseData

						[void]$ScriptController.Add(('# -------------- Attributes for logical JBOD "{0}" ({1})' -f $sasLJBODName, $deviceSlot))
						[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "ldname" -Value ('"{0}"' -f $sasLJBODName)))
						[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "numPhysDrives" -Value ('{0}' -f $sasLJBODNumPhysDrives)))

						[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "minDriveSize" -Value ('{0}' -f $sasLJBODMinDriveSize)))
						[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "maxDriveSize" -Value ('{0}' -f $sasLJBODMaxDriveSize)))
						[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "driveTech" -Value ('"{0}"' -f $sasLJBODdriveTech)))
									
						$LogicalDiskParams += ' -MinDriveSize $minDriveSize -MaxDriveSize $maxDriveSize -DriveType $driveTech'

						if ($sasLJBODeraseData)
						{

							[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "eraseDataOnDelete" -Value ('${0}' -f $sasLJBODeraseData)))

							$LogicalDiskParams += ' -EraseDataOnDelete $eraseDataOnDelete' 

						}

						$Value = 'New-HPOVServerProfileLogicalDisk -Name $ldName{0}' -f $LogicalDiskParams
						$Cmd = Generate-CustomVarCode -Prefix $LogicalDiskVarName -Value $Value
	
						[void]$ScriptController.Add($Cmd)

						$l++

					}
								
				}
				
				[void]$ScriptController.Add(('# -------------- Attributes for controller "{0}" ({1})' -f $deviceSlot, $mode))
				[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "deviceSlot" -Value ('"{0}"' -f $deviceSlot)))
				[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "controllerMode" -Value ('"{0}"' -f $mode)))
							
				[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "LogicalDisks" -Value ('{0}' -f [String]::Join(', ', $LogicalDiskVarNames.ToArray()))))

				$LogicalDisksParam = ' -LogicalDisk $LogicalDisks'

				if ($writeCache -ne 'Unmanaged' -and -not [String]::IsNullOrEmpty($writeCache))
				{

				[void]$ScriptController.Add((Generate-CustomVarCode -Prefix "writeCache" -Value ('"{0}"' -f $writeCache)))
				$writeCacheParam = ' -WriteCache $writeCache'

			}

			if ($initialize)
			{

				$initializeParam = ' -Initialize'

			}


			$Value = 'New-HPOVServerProfileLogicalDiskController -ControllerID $deviceSlot -Mode $controllerMode{0}{1}{2}{3}' -f $writeCacheParam, $initializeParam, $importCfgParam, $LogicalDisksParam
			$Cmd = Generate-CustomVarCode -Prefix $ControllerVarName -Value $Value
			
			[void]$ScriptController.Add($Cmd)

			$c++                

			}
			
            Return $ScriptController, $ControllerVarNames

        }

        # Internal helper
        Function Generate-SANStorage-Script  
        {

            Param 
            ( 
                
                $SANStorageConfig

            )

            $SanStorageCode    = New-Object System.Collections.ArrayList
            $VolAttachVarNames = New-Object System.Collections.ArrayList

            $IsManagedSAN       = $SANStorageConfig.manageSanStorage
            $volumeAttachment   = $SANStorageConfig.volumeAttachments

            $_v = 1

            $volIdParam = $lunParam = $lunTypeParam = $null

            foreach ($vol in $volumeAttachment)
            {

                $lunParam = $volumeParam = $null

                $VarName = '$volume{0}' -f $_v

                [void]$VolAttachVarNames.Add($VarName)

                $volID              = $vol.id
                $isBootVolume       = if ($vol.bootVolumePriority -eq 'Bootable') { $True } else { $False }
                $lunType            = $vol.lunType

                # Lets see if volume name can be added here.  If existing vol, volume name is not present in attachment, need to get volume from volumeUri
                [void]$SanStorageCode.Add('# ----------- SAN volume attributes for volume ID "{0}"' -f $volID)
                [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'volId' -Value ('{0}' -f $volID)))
                [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'lunIdType' -Value ('"{0}"' -f $lunType)))
                $lunParam       = ' -VolumeID $volId -LunIDType $lunIdType'

                if ($lunType -ne 'Auto')
                {

                    $lunID          = $vol.lun

                    [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'lunID' -Value ('{0}' -f $lunID)))
                    $lunParam       += ' -lunID $lunID'

                }

                # Perminent storage vol
                if (-not [String]::IsNullOrWhiteSpace($vol.volumeUri))
                {

                    Try
                    {
                    
                        $volAttachment = Send-HPOVRequest -Uri $vol.volumeUri -Hostname $ApplianceConnection
                    
                    }
                    
                    Catch
                    {
                    
                        $PSCmdlet.ThrowTerminatingError($_)
                    
                    }

                    $volName           = $volProperty.name

                    [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'volName' -Value ('"{0}"' -f $volName)))
                    [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix $VarName -Value 'Get-HPOVStorageVolume -Name $volName'))

                    $volumeParam = ' -Volume {0}' -f $VarName

                }

                # Dynamic private volume
                else
                {
                
                    # Common ephemeral volume settings
                    $volProperty    = $vol.volume.properties
                    $isPermanent    = $vol.volume.isPermanent
                    $name           = $volProperty.name
                    $size           = $volProperty.size / 1GB
                    $isDeduplicated = $volProperty.isDeduplicated
                    $provisionType  = $volProperty.provisioningType
                    $storagePoolUri = $volProperty.storagePool
                    
                    $templateUri    = $vol.volume.templateUri 

                    [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'volName' -Value ('"{0}"' -f $name)))
                    $volumeParam = ' -Name $volName'

                    Try
                    {
                    
                        $template = Send-HPOVRequest -Uri $templateUri -Hostname $ApplianceConnection
                    
                    }
                    
                    Catch
                    {
                    
                        $PSCmdlet.ThrowTerminatingError($_)
                    
                    }

                    $isRoot = $template.isRoot

                    # Administrator SVT, not storage system SVT
                    if (-not $isRoot)
                    {

                        $volTemplateName = $template.name

                        [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'volTemplateName' -Value ('"{0}"' -f $volTemplateName)))
                        [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'volumeTemplate' -Value 'Get-HPOVStorageVolumeTemplate -Name $volTemplateName'))

                        $volumeParam += ' -VolumeTemplate $volumeTemplate'
                        
                    }

                    # Ephemeral volume with parameters
                    else 
                    {

                        # Get storage pool object
                        Try
                        {
                        
                            $storagePool   = Send-HPOVRequest -Uri $storagePoolUri -Hostname $ApplianceConnection
                            $storageSystem = Send-HPOVRequest -Uri $storagePool.storageSystemUri -Hostname $ApplianceConnection
                        
                        }
                        
                        Catch
                        {
                        
                            $PSCmdlet.ThrowTerminatingError($_)
                        
                        }

                        $storagePoolName = $storagePool.name

                        # Get storage system name from pool
                        $storageSystemName = $storageSystem.name

                        $volTemplateParam = $volTemplateCode = $null

                        [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'capacity' -Value ('{0}' -f $size)))
                        [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'provisionType' -Value ('"{0}"' -f $provisionType)))
                        [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'storagePoolName' -Value ('"{0}"' -f $storagePoolName)))
                        [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'storageSystemName' -Value ('"{0}"' -f $storageSystemName)))
                        [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'storagePool' -Value 'Get-HPOVStoragePool -Name $storagePoolName -StorageSystem $storageSystemName'))

                        $volumeParam += ' -Capacity $capacity -ProvisioningType $provisionType -StoragePool $storagePool'

                        switch ($storageSystem.family)
                        {

                            'StoreServ'
                            {

                                $snapshotStoragePoolUri = $volProperty.snapshotPool

                                if ($snapshotStoragePoolUri -ne $storagePoolUri)
                                {

                                    # Get snapshot storage pool object
                                    Try
                                    {
                        
                                        $snapshotStoragePool = Send-HPOVRequest -Uri $snapshotStoragePoolUri -Hostname $ApplianceConnection
                        
                                    }
                        
                                    Catch
                                    {
                        
                                        $PSCmdlet.ThrowTerminatingError($_)
                        
                                    }

                                    [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'snapshotPoolName' -Value ('"{0}"' -f $snapshotStoragePool.name)))
                                    [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'snapshotStoragePool' -Value 'Get-HPOVStoragePool -Name $snapshotPoolName -StorageSystem $storageSystemName'))

                                    $volumeParam += ' -SnapshotStoragePool $snapshotStoragePool'

                                }

                            }

                            'StoreVirtual'
                            {

                                $dataProtectionLevel = $volProperty.dataProtectionLevel
                                $isAOEnabled         = $volProperty.isAdaptiveOptimizationEnabled

                                [void]$SanStorageCode.Add((Generate-CustomVarCode -Prefix 'dataProtectionLevel' -Value ('"{0}"' -f $dataProtectionLevel)))

                                $volumeParam += ' -DataProtectionLevel $dataProtectionLevel'

                                if ($isAOEnabled)
                                {

                                    $volumeParam += ' -EnableAdaptiveOptimization'
                    
                                }    

                            }

                        }

                    }

                    Write-Host "isPermanent: " $isPermanent
                    if ($isPermanent)
                    {

                        $volumeParam += ' -Permanent'

                    }

                    $_v++
                
                }
                
                $Value = 'New-HPOVServerProfileAttachVolume{0}{1}{2}' -f $lunParam, $volumeParam, $null
                
                $Cmd = Generate-CustomVarCode -Prefix $VarName -Value $Value
        
                [void]$SanStorageCode.Add($Cmd)

            }

            return $SanStorageCode, $VolAttachVarNames

        }

        switch ($InputObject.GetType().FullName)
        {

            {$_ -match 'HPOneView.Appliance.Baseline'}
            {

                Generate-fwBaseline-Script              -InputObject $InputObject

            }

            'HPOneView.Appliance.ProxyServer'
            {

                Generate-proxy-Script                   -InputObject $InputObject 

            }

            'HPOneView.Appliance.ScopeCollection'
            {

                Generate-Scope-Script                   -InputObject $InputObject

            }

            'HPOneView.Appliance.SnmpReadCommunity'
            {
                
                Generate-Snmp-Script                    -InputObject $InputObject

            }

            'HPOneView.Appliance.SnmpV3User'
            {

                Generate-snmpV3User-Script              -InputObject $InputObject

            }

            'HPOneView.Appliance.ApplianceLocaleDateTime'
            {

                Generate-TimeLocale-Script              -InputObject $InputObject

            }

            'HPOneView.Storage.StoragePool'
            {

                Generate-StoragePool-Script             -InputObject $InputObject

            }

            default
            {

                switch ($InputObject.type)
                {

                    'EmailNotificationV3'
                    {

                        Generate-smtp-Script              -InputObject $InputObject

                    }

                    'Subnet'
                    {

                        Generate-AddressPoolSubnet-Script -InputObject $InputObject

                    }

                    'Range'
                    {

                        Generate-AddressPoolRange-Script  -InputObject $InputObject

                    }

                    {$_ -match 'ethernet-network'}
                    {

                        Generate-EthernetNetwork-Script   -InputObject $InputObject

                    }

                    {$_ -match 'network-set'}
                    {

                        Generate-NetworkSet-Script   -InputObject $InputObject

                    }

                    {$_ -match 'fcoe-network' -or $_ -match 'fc-network'}
                    {

                        Generate-FCNetwork-Script         -InputObject $InputObject

                    }

                    {$_ -match 'FCDeviceManager'}
                    {

                        Generate-SanManager-Script        -InputObject $InputObject

                    }

                    {$_ -match 'StorageSystem'}
                    {

                        Generate-StorageSystem-Script         -InputObject $InputObject

                    }

                    {$_ -match 'StorageVolumeTemplate'}
                    {

                        Generate-StorageVolumeTemplate-Script -InputObject $InputObject; Break

                    }

                    {$_ -match 'StorageVolume'}
                    {

                        Generate-StorageVolume-Script -InputObject $InputObject; Break

                    }

                    {$_ -match 'UserAndPermissions'}
                    {

                        Generate-User-Script -InputObject $InputObject

                    }

                    {$_ -match 'LoginDomainGroupPermission'}
                    {

                        Generate-RBAC-Script -InputObject $InputObject

                    }

                    {$_ -match 'LoginDomainConfig'}
                    {

                        Generate-DirectoryAuthentication-Script  -InputObject $InputObject

                    }

                    # {$_ -match 'Configuration'}
                    # {

                    #     Generate-RemoteSupport-Script -InputObject $InputObject

                    # }

                    {$_ -match 'logical-interconnect-group'}
                    {

                        Generate-LogicalInterConnectGroup-Script -InputObject $InputObject

                    }

                    {$_ -match 'enclosure'}
                    {
                        
                        switch ($InputObject.category)
                        {

                            'enclosure-groups'
                            {

                                Generate-EnclosureGroup-Script           -InputObject $InputObject

                            }

                            'logical-enclosures'
                            {

                                if (($ConnectedSessions | ? Name -eq $InputObject.ApplianceConnection.Name).ApplianceType -ne 'Composer')
                                {
                                    
                                    $ErrorRecord = New-Object Management.Automation.ErrorRecord (New-Object HPOneview.Appliance.ComposerNodeException ('The ApplianceConnection {0} is not a Synergy Composer.  The logical enclosure resource and this Cmdlet is only supported with Synergy Composers.' -f $ApplianceConnection)), 'InvalidOperation', 'InvalidOperation', 'ApplianceConnection'

                                    $PSCmdlet.WriteError($ErrorRecord)

                                }

                                else
                                {
                                
                                    Generate-LogicalEnclosure-Script         -InputObject $InputObject
                                
                                }

                            }

                            default
                            {

                                if ($InputObject.enclosureType -eq 'C7000')
                                {

                                    Try
                                    {
                        
                                        $EnclosureGroup = Send-HPOVRequest -Uri $InputObject.enclosureGroupUri -Hostname $ApplianceConnection
                        
                                    }
                        
                                    Catch
                                    {
                        
                                        $PSCmdlet.ThrowTerminatingError($_)
                        
                                    }

                                    Generate-EnclosureGroup-Script           -InputObject $EnclosureGroup

                                }

                                else
                                {
                        
                                    Try
                                    {
                        
                                        $LogicalEnclosure = Send-HPOVRequest -Uri $InputObject.logicalEnclosureUri -Hostname $ApplianceConnection
                        
                                    }
                        
                                    Catch
                                    {
                        
                                        $PSCmdlet.ThrowTerminatingError($_)
                        
                                    }

                                    Generate-LogicalEnclosure-Script         -InputObject $LogicalEnclosure
                        
                                }

                            }

                        }

                        break

                    }

                    {$_ -match 'server'}
                    {

                        switch ($InputObject.category)
                        {

                            'server-profiles'
                            {

                                Generate-ProfileTemplate-Script -InputObject $InputObject
                                
                            }

                            'server-profile-templates'
                            {

                                Generate-ProfileTemplate-Script -InputObject $InputObject

                            }

                            # Generate Profile script code
                            'server-hardware'
                            {

                                Try
                                {
                                
                                    $ServerProfile = Send-HPOVRequest -Uri $InputObject.serverProfileUri -Hostname $ApplianceConnection
                                
                                }
                                
                                Catch
                                {
                                
                                    $PSCmdlet.ThrowTerminatingError($_)
                                
                                }

                                # If a template is associated, get template code first
                                if ($null -ne $ServerProfile.serverProfileTemplateUri)
                                {

                                    Try
                                    {
                                    
                                        $ServerProfileTemplate = Send-HPOVRequest -Uri $ServerProfile.serverProfileTemplateUri -Hostname $ApplianceConnection
                                    
                                    }
                                    
                                    Catch
                                    {
                                    
                                        $PSCmdlet.ThrowTerminatingError($_)
                                    
                                    }

                                    Generate-ProfileTemplate-Script -InputObject $ServerProfileTemplate

                                }

                                Generate-Profile-Script -InputObject $ServerProfile

                            }

						}
						
					}
					
					'DeploymentManager'
					{

						Generate-osDeploymentServer-Script -InputObject $InputObject

					}

                    default
                    {

                        $ExceptionMessage = 'The "{0}" resource category for "{1}" is currently not supported. ' -f $InputObject.type, $InputObject.name
                        $ErrorRecord = New-ErrorRecord HPOneview.InputObjectResourceException InvalidInputObjectResource InvalidArgument "InputObject" -TargetType $InputObject.GetType().Name -Message $ExceptionMessage

                        $PSCmdlet.WriteError($ErrorRecord)

                    }

                }

            }

        }   

    }

    End
    {

        '[{0}] Done.' -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

    }

}
