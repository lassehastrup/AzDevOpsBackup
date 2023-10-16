[CmdletBinding()]
param (
)

#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.3.1' };@{ ModuleName = 'Az.Accounts'; ModuleVersion = '2.12.4'}

$TestsConfigurationObject = @{
    TestResult   = @{
        Enabled      = $true
        OutputFormat = "NUnitXml"
        OutputPath   = "$PSScriptRoot/tmp/TEST-Pester.xml"
    }
    Run          = @{
        Path = $PSScriptRoot
        Exit = $true
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
    CodeCoverage = @{
        Enabled      = $true
        Path         = @("$PSScriptRoot/../src/powershell/private")
        OutputPath   = "$PSScriptRoot/Pester-Coverage.xml"
        OutputFormat = 'JaCoCo'
    }
}


$TestsConfiguration = New-PesterConfiguration -Hashtable $TestsConfigurationObject
Invoke-Pester -Configuration $TestsConfiguration