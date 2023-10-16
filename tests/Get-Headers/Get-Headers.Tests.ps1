#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.3.1' };@{ ModuleName = 'Az.Accounts'; ModuleVersion = '2.12.4'}
if (!(Get-Module Az.Accounts)){
    Install-Module -Name Az.Accounts -Force
}
Describe "Get-Headers" {

    BeforeAll {
        Import-Module -Name "$PSScriptRoot/../../src/powershell/DevOpsBackup.psm1" -ErrorAction Stop -Force -Verbose:$false

        $CommonSplat = @{
            CommandName = 'Invoke-RestMethod'
            ModuleName  = 'DevOpsBackup'
        }

        # The below line is added to catch any situations where the mock is not invoked in the test
        # If the below throw is activated during the test, we know that Invoke-RestMethod was called without being mocked
        # and shows us that another mock is needed
        Mock @CommonSplat -MockWith { throw "Invoked default mock for Invoke-RestMethod" }

        # Always mock the Get-AzAccessToken function so it returns a token
        $tokenObj = @{
            Token     = 'redacted-token'
            TenantId  = 'a128debf-0eff-4519-9474-334aa0ceb95d'
            ExpiresOn = @{
                UtcDateTime = (Get-Date).AddMinutes(30)
            }
        }
    }
    It "Should be outputted as a hashtable" {
        Mock Get-AzAccessToken -MockWith { $tokenObj } -ModuleName 'DevOpsBackup'
        Get-Headers -TenantId 'a128debf-0eff-4519-9474-334aa0ceb95d' | Should -BeOfType [System.Collections.Hashtable]
    }
    It "Should have two headers" {
        Mock Get-AzAccessToken -MockWith { $tokenObj } -ModuleName 'DevOpsBackup'
        $headers = Get-Headers -TenantId 'a128debf-0eff-4519-9474-334aa0ceb95d'
        $headers.Keys | Should -HaveCount 2
    }
    It "Should throw if the token is null" {
        Mock Get-AzAccessToken -MockWith { $null } -ModuleName 'DevOpsBackup'
        $tenantId = 'a128debf-0eff-4519-9474-334aa0ceb95d'
        $ResourceTypeName = 'Arm'
        { Get-Headers -TenantId $tenantId -ResourceTypeName $ResourceTypeName } | Should -Throw -ExpectedMessage "Unable to get Azure Bearer Token for tenant: $tenantId of type: $ResourceTypeName"

    }
    It "Should have a Content-Type header" {
        Mock Get-AzAccessToken -MockWith { $tokenObj } -ModuleName 'DevOpsBackup'
        $headers = Get-Headers -TenantId 'a128debf-0eff-4519-9474-334aa0ceb95d'
        $headers.Keys | Should -Contain 'Content-Type'
    }
    It "Should have a Authorization header" {
        Mock Get-AzAccessToken -MockWith { $tokenObj } -ModuleName 'DevOpsBackup'
        $headers = Get-Headers -TenantId 'a128debf-0eff-4519-9474-334aa0ceb95d'
        $headers.Keys | Should -Contain 'Authorization'
    }
    It "Should provide a valid token if resourceType is 'DevOps" {
        Mock Get-AzAccessToken -MockWith { $tokenObj } -ModuleName 'DevOpsBackup'
        $headers = Get-Headers -TenantId 'a128debf-0eff-4519-9474-334aa0ceb95d' -ResourceTypeName 'DevOps'
        $headers['Authorization'] | Should -Be "Bearer redacted-token"
    }
    It "It should use Connect-AzAccount if the wrong tenant is used and still retrieve a valid token" {
        Mock Get-AzAccessToken -MockWith { Throw "Wrong tenant" } -ModuleName 'DevOpsBackup'
        Mock Connect-AzAccount -MockWith { $null } -ModuleName 'DevOpsBackup'
        { Get-Headers -TenantId 'a128debf-0eff-4519-9474-334aa0ceb95d' -ResourceTypeName 'Arm' } | Should -Throw -ExpectedMessage "Wrong tenant"
        Mock Get-AzAccessToken -MockWith { $tokenObj } -ModuleName 'DevOpsBackup'
        $headers = Get-Headers -TenantId 'a128debf-0eff-4519-9474-334aa0ceb95d' -ResourceTypeName 'Arm'
        $headers['Authorization'] | Should -Be "Bearer redacted-token"
    }
}
