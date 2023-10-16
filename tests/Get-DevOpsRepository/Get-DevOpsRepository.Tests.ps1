Describe "Get-DevOpsRepository" {

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
    }
    It "Does not throw even if no repositories are found" {
        Mock @CommonSplat -MockWith {
            @{
                value = @()
            }
        }

        { Get-DevOpsRepository -organizationName 'DevOrg' -Headers @{} -Project @{} } | Should -Not -Throw
    }
    It "Should return repositories as an objet" {
        Mock @CommonSplat -MockWith {
            @{
                value = @(
                    @{
                        id   = '123'
                        name = 'Repo1'
                    },
                    @{
                        id   = '456'
                        name = 'Repo2'
                    }
                )
            }
        }

        $result = Get-DevOpsRepository -organizationName 'DevOrg' -Headers @{} -Project @{}

        $result | Should -BeOfType [System.Collections.Hashtable]
        $result | Should -HaveCount 2
    }
}