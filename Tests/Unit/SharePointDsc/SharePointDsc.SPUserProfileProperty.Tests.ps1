[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_SPUserProfileProperty"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPUserProfileProperty - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParamsNewProperty = @{
           Name = "WorkEmailNew"
           UserProfileService = "User Profile Service Application"
           DisplayName = "WorkEmailNew"
           Type = "String"
           Description = "" 
           PolicySetting = "Mandatory"
           PrivacySetting = "Public"
           MappingConnectionName = "contoso"
           MappingPropertyName = "department"
           MappingDirection = "Import"
           Length = 30
           DisplayOrder = 5496 
           IsEventLog =$false
           IsVisibleOnEditor=$true
           IsVisibleOnViewer = $true
           IsUserEditable = $true
           IsAlias = $false
           IsSearchable = $false 
           TermStore = "Managed Metadata service"
           TermGroup = "People"
           TermSet = "Department" 
           UserOverridePrivacy = $false
        }
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        $farmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
        $testParamsUpdateProperty = @{
           Name = "WorkEmailUpdate"
           UserProfileService = "User Profile Service Application"
           DisplayName = "WorkEmailUpdate"
           Type = "String"
           Description = ""
           PolicySetting = "Optin"
           PrivacySetting = "Private"
           Ensure ="Present"
           MappingConnectionName = "contoso"
           MappingPropertyName = "mail"
           MappingDirection = "Import"
           Length = 25
           DisplayOrder = 5401
           IsEventLog =$true
           IsVisibleOnEditor=$True
           IsVisibleOnViewer = $true
           IsUserEditable = $true
           IsAlias = $true 
           IsSearchable = $true 
           TermStore = "Managed Metadata service"
           TermGroup = "People"
           TermSet = "Location" 
           UserOverridePrivacy = $false
        }
        
        try { [Microsoft.Office.Server.UserProfiles] }
        catch {
            Add-Type @"
                namespace Microsoft.Office.Server.UserProfiles {
                public enum ConnectionType { ActiveDirectory, BusinessDataCatalog };
                public enum ProfileType { User};
                }        
"@ -ErrorAction SilentlyContinue
        }   

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        $corePropertyUpdate = @{ 
                            DisplayName = "WorkEmailUpdate" 
                            Name = "WorkEmailUpdate"
                            IsMultiValued=$false
                            Type = "String"
                            TermSet = @{Name=       $testParamsUpdateProperty.TermSet
                                        Group=      @{Name =$testParamsUpdateProperty.TermGroup}
                                        TermStore = @{Name =$testParamsUpdateProperty.TermStore} }
                            Length=25
                            IsSearchable =$true
                        } | Add-Member ScriptMethod Commit {
                            $Global:SPUPSPropertyCommitCalled = $true
                        } -PassThru | Add-Member ScriptMethod Delete {
                            $Global:SPUPSPropertyDeleteCalled = $true
                        } -PassThru
        $corePropertyUpdate.Type = $corePropertyUpdate.Type | Add-Member ScriptMethod GetTypeCode {
                            $Global:SPUPSPropertyGetTypeCodeCalled = $true
                            return $corePropertyUpdate.Type
                        } -PassThru -Force
        $coreProperties = @{WorkEmailUpdate = $corePropertyUpdate}

        $coreProperties = $coreProperties | Add-Member ScriptMethod Create {
                            $Global:SPUPCoreCreateCalled = $true
                            return @{
                            Name="";
                            DisplayName=""
                            Type=""
                            TermSet=$null
                            Length=10
                            }
                        } -PassThru  | Add-Member ScriptMethod RemovePropertyByName {
                            $Global:SPUPCoreRemovePropertyByNameCalled = $true
                        } -PassThru | Add-Member ScriptMethod Add {
                            $Global:SPUPCoreAddCalled = $true
                        } -PassThru -Force 
                        
       # $coreProperties.Add($coreProperty)
        $typePropertyUpdate = @{
                            IsVisibleOnViewer=$true
                            IsVisibleOnEditor=$true
                            IsEventLog=$true
                        }| Add-Member ScriptMethod Commit {
                            $Global:SPUPPropertyCommitCalled = $true
                        } -PassThru 
        
        #$typeProperties.Add($typeProperty)
       $subTypePropertyUpdate = @{
                            Name= "WorkEmailUpdate"
                            DisplayName="WorkEmailUpdate"
                            Description = ""
                            PrivacyPolicy = "Optin"
                            DefaultPrivacy = "Private"
                            DisplayOrder =5401
                            IsUserEditable= $true
                            IsAlias =  $true
                            CoreProperty = $corePropertyUpdate
                            TypeProperty = $typePropertyUpdate
                            AllowPolicyOverride=$false;
                        }| Add-Member ScriptMethod Commit {
                            $Global:SPUPPropertyCommitCalled = $true
                        } -PassThru 


        $coreProperty = @{ 
                            DisplayName = $testParamsNewProperty.DisplayName
                            Name = $testParamsNewProperty.Name
                            IsMultiValued=$testParamsNewProperty.Type -eq "stringmultivalue"
                            Type = $testParamsNewProperty.Type
                            TermSet = @{Name=       $testParamsNewProperty.TermSet
                                        Group=      @{Name =$testParamsNewProperty.TermGroup}
                                        TermStore = @{Name =$testParamsNewProperty.TermStore} }
                            Length=$testParamsNewProperty.Length
                            IsSearchable =$testParamsNewProperty.IsSearchable
                        } | Add-Member ScriptMethod Commit {
                            $Global:SPUPSPropertyCommitCalled = $true
                        } -PassThru | Add-Member ScriptMethod Delete {
                            $Global:SPUPSPropertyDeleteCalled = $true
                        } -PassThru

        $typeProperty = @{
                            IsVisibleOnViewer=$testParamsNewProperty.IsVisibleOnViewer
                            IsVisibleOnEditor=$testParamsNewProperty.IsVisibleOnEditor
                            IsEventLog=$testParamsNewProperty.IsEventLog
                        }| Add-Member ScriptMethod Commit {
                            $Global:SPUPPropertyCommitCalled = $true
                        } -PassThru 

        $subTypeProperty = @{
                            Name= $testParamsNewProperty.Name
                            DisplayName= $testParamsNewProperty.DisplayName
                            Description = $testParamsNewProperty.Description
                            PrivacyPolicy = $testParamsNewProperty.PolicySetting 
                            DefaultPrivacy = $testParamsNewProperty.PrivateSetting
                            DisplayOrder =$testParamsNewProperty.DisplayOrder
                            IsUserEditable= $testParamsNewProperty.IsUserEditable
                            IsAlias =  $testParamsNewProperty.IsAlias
                            CoreProperty = $coreProperty
                            TypeProperty = $typeProperty
                            AllowPolicyOverride=$true;
                        }| Add-Member ScriptMethod Commit {
                            $Global:SPUPPropertyCommitCalled = $true
                        } -PassThru 
        $userProfileSubTypePropertiesNoProperty = @{} | Add-Member ScriptMethod Create {
                            $Global:SPUPSubTypeCreateCalled = $true
                        } -PassThru  | Add-Member ScriptMethod GetPropertyByName {
                            $result = $null
                            if($Global:SPUPGetPropertyByNameCalled -eq $TRUE){
                                $result = $subTypeProperty
                            }
                            $Global:SPUPGetPropertyByNameCalled  = $true
                            return $result
                        } -PassThru| Add-Member ScriptMethod Add {
                            $Global:SPUPSubTypeAddCalled = $true
                        } -PassThru -Force 

        $userProfileSubTypePropertiesUpdateProperty = @{"WorkEmailUpdate" = $subTypePropertyUpdate } | Add-Member ScriptMethod Create {
                            $Global:SPUPSubTypeCreateCalled = $true
                        } -PassThru | Add-Member ScriptMethod Add {
                            $Global:SPUPSubTypeAddCalled = $true
                        } -PassThru -Force | Add-Member ScriptMethod GetPropertyByName {
                            $Global:SPUPGetPropertyByNameCalled  = $true
                            return $subTypePropertyUpdate
                        } -PassThru
         #$userProfileSubTypePropertiesValidProperty.Add($subTypeProperty);
        mock Get-SPDSCUserProfileSubTypeManager -MockWith {
        $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                            $Global:SPUPGetProfileSubtypeCalled = $true
                            return @{
                            Properties = $userProfileSubTypePropertiesNoProperty
                            }
                        } -PassThru 

        return $result
        }
        

        Mock Get-SPWebApplication -MockWith {
            return @(
                    @{
                        IsAdministrationWebApplication=$true
                        Url ="caURL"
                     })
        }  
        #IncludeCentralAdministration
        $TermSets =@{Department = @{Name="Department"
                                }
                    Location = @{Name="Location"
                                }                                
                                } 
                             
        $TermGroups = @{People = @{Name="People"
                                TermSets = $TermSets 
                                }}

        $TermStoresList = @{"Managed Metadata service" = @{Name="Managed Metadata service"
                                Groups = $TermGroups 
                                }}    


        Mock New-Object -MockWith {
            return (@{
                TermStores = $TermStoresList
            })
        } -ParameterFilter { $TypeName -eq "Microsoft.SharePoint.Taxonomy.TaxonomySession" } 

        Mock New-Object -MockWith {
            return (@{
                Properties = @{} | Add-Member ScriptMethod SetDisplayOrderByPropertyName {
                $Global:UpsSetDisplayOrderByPropertyNameCalled=$true;
                return $false; 
            } -PassThru | Add-Member ScriptMethod CommitDisplayOrder {
                $Global:UpsSetDisplayOrderByPropertyNameCalled=$true;
                return $false; 
            } -PassThru    })
        } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileManager" } 
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
  
        
        Mock New-PSSession { return $null } -ModuleName "SharePointDsc.Util"
        $propertyMappingItem =  @{
                                    DataSourcePropertyName="mail"
                                    IsImport=$true
                                    IsExport=$false
                                    } | Add-Member ScriptMethod Delete {
                                        $Global:UpsMappingDeleteCalled=$true;
                                        return $true; 
                                        } -PassThru

        $propertyMapping = @{}| Add-Member ScriptMethod Item {
                            param( [string]$property  )
                            $Global:SPUPSMappingItemCalled = $true
                                if($property="WorkEmailUpdate"){
                                    return $propertyMappingItem}
                                    } -PassThru -force | Add-Member ScriptMethod AddNewExportMapping {
                                        $Global:UpsMappingAddNewExportCalled=$true;
                                        return $true; 
                                        } -PassThru | Add-Member ScriptMethod AddNewMapping {
                                        $Global:UpsMappingAddNewMappingCalled=$true;
                                        return $true; 
                                        } -PassThru 
        $connection = @{ 
            DisplayName = "Contoso" 
            Server = "contoso.com"
            AccountDomain = "Contoso"
            AccountUsername = "TestAccount"
            Type= "ActiveDirectory"
            PropertyMapping = $propertyMapping
        }

        $connection = $connection   | Add-Member ScriptMethod Update {
                            $Global:SPUPSSyncConnectionUpdateCalled = $true
                        } -PassThru  | Add-Member ScriptMethod AddPropertyMapping {
                            $Global:SPUPSSyncConnectionAddPropertyMappingCalled = $true
                        } -PassThru

        
        $ConnnectionManager = @($connection) | Add-Member ScriptMethod  AddActiveDirectoryConnection{ `
                                                param([Microsoft.Office.Server.UserProfiles.ConnectionType] $connectionType,  `
                                                $name, `
                                                $forest, `
                                                $useSSL, `
                                                $userName, `
                                                $securePassword, `
                                                $namingContext, `
                                                $p1, $p2 `
                                            )
        
        $Global:SPUPSAddActiveDirectoryConnectionCalled =$true
        } -PassThru
        
        
        Mock New-Object -MockWith {
            $ProfilePropertyManager = @{"Contoso"  = $connection} | Add-Member ScriptMethod GetCoreProperties {
                $Global:UpsConfigManagerGetCorePropertiesCalled=$true;

                return ($coreProperties); 
            } -PassThru | Add-Member ScriptMethod GetProfileTypeProperties {
                $Global:UpsConfigManagerGetProfileTypePropertiesCalled=$true;
                return $userProfileSubTypePropertiesUpdateProperty; 
            } -PassThru     
            return (@{
            ProfilePropertyManager = $ProfilePropertyManager
            ConnectionManager = $ConnnectionManager  
            } | Add-Member ScriptMethod IsSynchronizationRunning {
                $Global:UpsSyncIsSynchronizationRunning=$true;
                return $false; 
            } -PassThru   )
        } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 
        
        $userProfileServiceValidConnection =  @{
            Name = "User Profile Service Application"
            TypeName = "User Profile Service Application"
            ApplicationPool = "SharePoint Service Applications"
            FarmAccount = $farmAccount 
            ServiceApplicationProxyGroup = "Proxy Group"
            ConnectionManager=  @($connection) #New-Object System.Collections.ArrayList
        }

        Mock Get-SPServiceApplication { return $userProfileServiceValidConnection }

        
        Context "When property doesn't exist" {
            
            It "returns null from the Get method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false
                (Get-TargetResource @testParamsNewProperty).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsNewProperty.UserProfileService } 
                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $false
            }
            
            It "returns false when the Test method is called" {
                $Global:SPUPGetPropertyByNameCalled = $false
                Test-TargetResource @testParamsNewProperty | Should Be $false
                $Global:SPUPGetPropertyByNameCalled | Should be $true
            }

            It "creates a new user profile property in the set method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                
                $Global:SPUPSMappingItemCalled = $false
                Set-TargetResource @testParamsNewProperty
                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                
                $Global:SPUPSMappingItemCalled | Should be $true

            }

        }

        Context "When property doesn't exist, connection doesn't exist" {
            Mock New-Object -MockWith {
                $ProfilePropertyManager = @{"Contoso"  = $connection} | Add-Member ScriptMethod GetCoreProperties {
                $Global:UpsConfigManagerGetCorePropertiesCalled=$true;

                return ($coreProperties); 
            } -PassThru | Add-Member ScriptMethod GetProfileTypeProperties {
                $Global:UpsConfigManagerGetProfileTypePropertiesCalled=$true;
                return $userProfileSubTypePropertiesUpdateProperty; 
            } -PassThru     
            return (@{
            ProfilePropertyManager = $ProfilePropertyManager
            ConnectionManager = $()  
            } | Add-Member ScriptMethod IsSynchronizationRunning {
                $Global:UpsSyncIsSynchronizationRunning=$true;
                return $false; 
            } -PassThru   )
        } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 

            It "returns null from the Get method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false
                (Get-TargetResource @testParamsNewProperty).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsNewProperty.UserProfileService } 
                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $false
            }
            
            It "returns false when the Test method is called" {
                $Global:SPUPGetPropertyByNameCalled = $false
                Test-TargetResource @testParamsNewProperty | Should Be $false
                $Global:SPUPGetPropertyByNameCalled | Should be $true
            }

            It "attempts to create a new property but fails as connection isn't available" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false

                {Set-TargetResource @testParamsNewProperty} | should throw "connection not found"

                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $false

            }




        }

        Context "When property doesn't exist, term set doesn't exist" {
            $termSet = $testParamsNewProperty.TermSet 
            $testParamsNewProperty.TermSet = "Invalid"

            It "returns null from the Get method" {
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false
                (Get-TargetResource @testParamsNewProperty).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsNewProperty.UserProfileService } 
                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $false
            }
            
            It "returns false when the Test method is called" {
                $Global:SPUPGetPropertyByNameCalled = $false
                Test-TargetResource @testParamsNewProperty | Should Be $false
                $Global:SPUPGetPropertyByNameCalled | Should be $true
            }

            It "creates a new user profile property in the set method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPSMappingItemCalled = $false

                {Set-TargetResource @testParamsNewProperty} | should throw "Term Set $($testParamsNewProperty.TermSet) not found"

                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $false

            }
            $testParamsNewProperty.TermSet = $termSet

        }

        Context "When property doesn't exist, term group doesn't exist" {
            $termGroup = $testParamsNewProperty.TermGroup
            $testParamsNewProperty.TermGroup = "InvalidGroup"

            It "returns null from the Get method" {
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false
                (Get-TargetResource @testParamsNewProperty).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsNewProperty.UserProfileService } 
                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $false
            }
            
            It "returns false when the Test method is called" {
                $Global:SPUPGetPropertyByNameCalled = $false
                Test-TargetResource @testParamsNewProperty | Should Be $false
                $Global:SPUPGetPropertyByNameCalled | Should be $true
            }

            It "creates a new user profile property in the set method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPSMappingItemCalled = $false

                {Set-TargetResource @testParamsNewProperty} | should throw "Term Group $($testParamsNewProperty.TermGroup) not found"

                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $false

            }
            $testParamsNewProperty.TermGroup = $termGroup

        }

        Context "When property doesn't exist, term store doesn't exist" {
            $termStore = $testParamsNewProperty.TermStore
            $testParamsNewProperty.TermStore = "InvalidStore"

            It "returns null from the Get method" {
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false
                (Get-TargetResource @testParamsNewProperty).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsNewProperty.UserProfileService } 
                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $false
            }
            
            It "returns false when the Test method is called" {
                $Global:SPUPGetPropertyByNameCalled = $false
                Test-TargetResource @testParamsNewProperty | Should Be $false
                $Global:SPUPGetPropertyByNameCalled | Should be $true
            }

            It "creates a new user profile property in the set method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPSMappingItemCalled = $false

                {Set-TargetResource @testParamsNewProperty} | should throw "Term Store $($testParamsNewProperty.TermStore) not found"

                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $false

            }
            $testParamsNewProperty.TermStore = $termStore


        }


        Context "When property exists and all properties match" {
            mock Get-SPDSCUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                                $Global:SPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                                }
                            } -PassThru 

            return $result
            }
                    
            It "returns valid value from the Get method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false
                (Get-TargetResource @testParamsNewProperty).Ensure | Should Be "Present"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsUpdateProperty.UserProfileService } 
                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $true
            }
            
            It "returns false when the Test method is called" {
                $Global:SPUPGetPropertyByNameCalled = $false
                Test-TargetResource @testParamsUpdateProperty | Should Be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
            }

            It "updates an user profile property in the set method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPSMappingItemCalled = $false
                Set-TargetResource @testParamsUpdateProperty
                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $true

            }


        }

        Context "When property exists and type is different - throws exception" {
            $currentType = $testParamsUpdateProperty.Type
            $testParamsUpdateProperty.Type = "StringMultiValue"
            mock Get-SPDSCUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                                $Global:SPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                                }
                            } -PassThru 

            return $result
            }
                    
            It "returns valid value from the Get method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false
                (Get-TargetResource @testParamsNewProperty).Ensure | Should Be "Present"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsUpdateProperty.UserProfileService } 
                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $true
            }
            
            It "returns false when the Test method is called" {
                $Global:SPUPGetPropertyByNameCalled = $false
                Test-TargetResource @testParamsUpdateProperty | Should Be $false
                $Global:SPUPGetPropertyByNameCalled | Should be $true
            }

            It "attempts to update an user profile property in the set method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false

                {Set-TargetResource @testParamsUpdateProperty} | should throw "Can't change property type. Current Type"

                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $false
            }
            $testParamsUpdateProperty.Type = $currentType

        }

        Context "When property exists and mapping exists, mapping config does not match" {
            
            $propertyMappingItem.DataSourcePropertyName = "property"

            mock Get-SPDSCUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                                $Global:SPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                                }
                            } -PassThru 

            return $result
            }
                    
            It "returns valid value from the Get method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false
                (Get-TargetResource @testParamsNewProperty).Ensure | Should Be "Present"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsUpdateProperty.UserProfileService } 
                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $true
            }
            
            It "returns false when the Test method is called" {
                $Global:SPUPGetPropertyByNameCalled = $false
                Test-TargetResource @testParamsUpdateProperty | Should Be $false
                $Global:SPUPGetPropertyByNameCalled | Should be $true
            }

            It "updates an user profile property in the set method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false

                Set-TargetResource @testParamsUpdateProperty

                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $true
            }
        }
        Context "When property exists and mapping does not " {
           $propertyMappingItem=$null
                       mock Get-SPDSCUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                                $Global:SPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                                }
                            } -PassThru 

            return $result
            }
                    
            It "returns valid value from the Get method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false
                (Get-TargetResource @testParamsNewProperty).Ensure | Should Be "Present"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsUpdateProperty.UserProfileService } 
                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $true
            }
            
            It "returns false when the Test method is called" {
                $Global:SPUPGetPropertyByNameCalled = $false
                Test-TargetResource @testParamsUpdateProperty | Should Be $false
                $Global:SPUPGetPropertyByNameCalled | Should be $true
            }

            It "updates an user profile property in the set method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false

                Set-TargetResource @testParamsUpdateProperty

                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $true
            }
        }

        Context "When property exists and ensure equals Absent" {
            mock Get-SPDSCUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                                $Global:SPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                                }
                            } -PassThru 

            return $result
            }
                    $testParamsUpdateProperty.Ensure = "Absent"
            It "deletes an user profile property in the set method" {
                $Global:SPUPGetProfileSubtypeCalled = $false
                $Global:SPUPGetPropertyByNameCalled = $false
                $Global:SPUPSMappingItemCalled = $false
                $Global:SPUPCoreRemovePropertyByNameCalled=$false

                Set-TargetResource @testParamsUpdateProperty

                $Global:SPUPGetProfileSubtypeCalled | Should be $true
                $Global:SPUPGetPropertyByNameCalled | Should be $true
                $Global:SPUPSMappingItemCalled | Should be $false
                $Global:SPUPCoreRemovePropertyByNameCalled | Should be $true
            }           
        }
    }    
}
