[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_SPUserProfileServiceAppPermissions"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPUserProfileServiceAppPermissions- SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            ProxyName = "User Profile Service App Proxy"
            CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
            FollowAndEditProfile = @("Everyone")
            UseTagsAndNotes      = @("None")
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock New-SPClaimsPrincipal { 
            return @{
                Value = $Identity -replace "i:0#.w\|"
            }
        } -ParameterFilter { $IdentityType -eq "EncodedClaim" }

        Mock New-SPClaimsPrincipal { 
            $Global:SPDSCClaimsPrincipalUser = $Identity
            return (
                New-Object Object | Add-Member ScriptMethod ToEncodedString { 
                    return "i:0#.w|$($Global:SPDSCClaimsPrincipalUser)" 
                } -PassThru
            )
        } -ParameterFilter { $IdentityType -eq "WindowsSamAccountName" }

        Mock Grant-SPObjectSecurity { }
        Mock Revoke-SPObjectSecurity { }
        Mock Set-SPProfileServiceApplicationSecurity { }

        Mock Start-Sleep { }
        Mock Test-SPDSCIsADUser { return $true }
        Mock Write-Warning { }

        Mock Get-SPServiceApplicationProxy {
            return @()
        }
        
        Context "The proxy does not exist" {

            It "Should return null values from the get method" {
                $results = Get-TargetResource @testParams
                $results.CreatePersonalSite | Should BeNullOrEmpty
                $results.FollowAndEditProfile | Should BeNullOrEmpty
                $results.UseTagsAndNotes | Should BeNullOrEmpty
            }

            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the permissions correctly" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Mock Get-SPServiceApplicationProxy {
            return @(
                @{
                    DisplayName = $testParams.ProxyName
                }
            )
        }

        Context "Users who should have access do not have access" {
            Mock Get-SPProfileServiceApplicationSecurity {
                return @{
                    AccessRules = @()
                }
            }

            It "Should return the current permissions correctly" {
                Get-TargetResource @testParams
            }

            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the permissions correctly" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPProfileServiceApplicationSecurity
            }
        }

        Context "Users who should have access have incorrect permissions" {
            Mock Get-SPProfileServiceApplicationSecurity {
                return @{
                    AccessRules = @(
                        @{
                            Name = "i:0#.w|DEMO\User2"
                            AllowedRights = "UsePersonalFeatures"
                        },
                        @{
                            Name = "i:0#.w|DEMO\User1"
                            AllowedRights = "UsePersonalFeatures"
                        },
                        @{
                            Name = "c:0(.s|true"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        }
                    )
                }
            }

            It "Should return the current permissions correctly" {
                Get-TargetResource @testParams
            }

            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the permissions correctly" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPProfileServiceApplicationSecurity
            }
        }

        Context "Users who should have permissions have the correct permissions" {
            Mock Get-SPProfileServiceApplicationSecurity {
                return @{
                    AccessRules = @(
                        @{
                            Name = "i:0#.w|DEMO\User2"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "i:0#.w|DEMO\User1"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "c:0(.s|true"
                            AllowedRights = "UsePersonalFeatures"
                        }
                    )
                }
            }

            It "Should return the current permissions correctly" {
                Get-TargetResource @testParams
            }

            It "Should return true in the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Users who should not have access have permissions assigned" {
            Mock Get-SPProfileServiceApplicationSecurity {
                return @{
                    AccessRules = @(
                        @{
                            Name = "i:0#.w|DEMO\User2"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "i:0#.w|DEMO\User1"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "i:0#.w|DEMO\User3"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "c:0(.s|true"
                            AllowedRights = "UsePersonalFeatures"
                        }
                    )
                }
            }

            It "Should return the current permissions correctly" {
                Get-TargetResource @testParams
            }

            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the permissions correctly" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPProfileServiceApplicationSecurity
            }
        }

        Context "The old non-claims 'Authenticated Users' entry exists in the permissions" {
            Mock Get-SPProfileServiceApplicationSecurity {
                return @{
                    AccessRules = @(
                        @{
                            Name = "i:0#.w|DEMO\User2"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "i:0#.w|DEMO\User1"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "NT Authority\Authenticated Users"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "c:0(.s|true"
                            AllowedRights = "UsePersonalFeatures"
                        }
                    )
                }
            }

            It "Should return the current permissions correctly" {
                Get-TargetResource @testParams
            }

            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the permissions correctly" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPProfileServiceApplicationSecurity
            }
        }
    }    
}
