Describe "Get-DevOpsProjects" {

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

    It "Throws if no DevOps projects are found " {
        Mock @CommonSplat -MockWith {
            @{
                value = @()
            }
        }
        { Get-DevOpsProjects -OrganizationName 'DevOrg' -Headers @{} -ExcludedProjects @() } | Should -Throw -ExpectedMessage "No projects found in organization: DevOrg"
    }
    It "Returns all projects when no ExcludedProjects are provided" {
        $ExpectedOutput = @(
            @{
                name = 'Project1'
            },
            @{
                name = 'Project2'
            }
        )
        Mock @CommonSplat -MockWith {
            @{
                value = @(
                    $ExpectedOutput
                )
            }
        }
        $Projects = Get-DevOpsProjects -OrganizationName 'DevOrg' -Headers @{} -ExcludedProjects @()
        $Projects | Should -Be $ExpectedOutput
    }
    It "Should not return a project if it's excluded" {
        $Project = @(
            @{
                name = 'Project1'
            },
            @{
                name = 'Project2'
            }
        )
        Mock @CommonSplat -MockWith {
            @{
                value = @(
                    $Project
                )
            }
        }
        $Projects = Get-DevOpsProjects -OrganizationName 'DevOrg' -Headers @{} -ExcludedProjects @('Project1')
        $Projects | Should -Be $Project[1]
    }
}