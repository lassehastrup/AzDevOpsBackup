param (
    [String]$Path,
    [String]$Output = "Detailed",
    [Switch]$CodeCoverage
)

# Convert string to DirectoryInfo or FileInfo
$PathObject = Get-Item $Path -ErrorAction 'Stop'

Import-Module 'Pester' -MinimumVersion 5.2.0

$Configuration = [PesterConfiguration]::Default

$Configuration.Run.Path = $PathObject.FullName

$Configuration.Output.Verbosity = $Output

$Configuration.CodeCoverage.Enabled = [bool]$CodeCoverage
# CoverageGutters is new option in Pester 5.2
$Configuration.CodeCoverage.OutputFormat = "CoverageGutters"

$Configuration.CodeCoverage.OutputPath = "$PSScriptRoot/coverage.xml"
$Configuration.CodeCoverage.CoveragePercentTarget = 90

$Configuration.Debug.WriteDebugMessages = $true
$Configuration.Debug.WriteDebugMessagesFrom = "CodeCoverage"

# Include .Tests.ps1 files
$Configuration.CodeCoverage.ExcludeTests = $false

$objectTypeName = $PathObject.GetType().Name
switch ($objectTypeName) {
    'DirectoryInfo' {
        # Test the dir provided
        $Configuration.CodeCoverage.Path = $SourcePath.FullName
        break
    }
    'FileInfo' {
        # Get the function file relating to the test file
        $FileNameToTest = $PathObject.Name.Replace('.Tests', '')
        $SourcePath = Get-ChildItem -Recurse "$PSScriptRoot/../src" -Filter $FileNameToTest -File | Select-Object -ExpandProperty 'FullName'
        if ($SourcePath.Count -ne 1) {
            throw "Expected to find 1 file matching $FileNameToTest, found: $($SourcePath.Count)"
        }
        $Configuration.CodeCoverage.Path = $SourcePath
        break
    }
    Default {
        throw "Unexpected type found when running paint-coverage.ps1: $objectTypeName"
    }
}

Invoke-Pester -Configuration $Configuration