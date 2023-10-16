#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.1" }

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RootOfInitiatingRepo = "$PSScriptRoot/../"
)

Write-Verbose "RootOfInitiatingRepo: $RootOfInitiatingRepo"

Describe "Content" {
    BeforeDiscovery {

    }
    Context "File Content" {
        BeforeAll {
            $IgnoreWords = Get-Content "$RootOfInitiatingRepo/.cspell.json" | ConvertFrom-Json | Select-Object -ExpandProperty Words
            $IgnoreWords = Get-Content "$RootOfInitiatingRepo/.cspell.json" | ConvertFrom-Json | Select-Object -ExpandProperty Words

            Write-Verbose "Checking $($IgnoreWords.count) cSpell words against files in repository"


            $GetChildItemSplat = @{
                Path    = $RootOfRepository
                Recurse = $true
                Force   = $true
                File    = $true
                Exclude = "*.cspell.json"
            }
            $Items = Get-ChildItem @GetChildItemSplat | Where-Object { $_.FullName -notmatch "/.git/" -and $_.FullName -notmatch '/tests/' }


            $ContentOfAllFiles = $Items | ForEach-Object -ThrottleLimit 15 -Parallel { @{
                    Path    = $_.FullName
                    Content = Get-Content $_.FullName
                }
            }
            Write-Verbose "Checking $($ContentOfAllFiles.count) file content against cSpell words"
            Write-Verbose "Using forbidden words: $ForbiddenWords"
        }
        It "Should only check words that are present in files in the repository" {
            $UnusedIgnoreWords = $IgnoreWords | ForEach-Object -ThrottleLimit 15 -Parallel {
                $IgnoreWord = $_
                $ContentOfAllFiles = $using:ContentOfAllFiles
                # Ignore words that are negated in cSpell
                if ($IgnoreWord -match "^!") {
                    # should not be included in the list of unused words
                    continue
                }
                $ContentMatch = $ContentOfAllFiles.Content | Where-Object { $_ -match $IgnoreWord }
                if ($null -eq $ContentMatch) {
                    $IgnoreWord
                }
            }
            $UnusedIgnoreWords | Should -BeNullOrEmpty -Because "cSpell ignore words: $($UnusedIgnoreWords | ConvertTo-Json), is not present in any file and should not be ignored"
        }
        It "Should not contain duplicate words" {
            $GroupedIgnoreWords = $IgnoreWords | Group-Object -CaseSensitive | Where-Object { $_.Count -gt 1 }
            $GroupedIgnoreWords | Should -BeNullOrEmpty -Because "cSpell contains duplicate words words: $($GroupedIgnoreWords.Name). words defined in cSpell should be unique"
        }
        It "Should contain TODO as a cSpell ignore word" {
            $IgnoreWords | Should -Contain "!TODO" -Because "TODOs should be resolved before merging to main or be tracked in a work item"
        }
        It "Should contain FIXME as a cSpell ignore word" {
            $IgnoreWords | Should -Contain "!FIXME" -Because "FIXMEs should be resolved before merging to main or be tracked in a work item"
        }
        It "Should not contain TODO" {
            $ContentOfAllFiles | ForEach-Object -ThrottleLimit 15 -Parallel {
                $Item = $_
                $Item.Content | Should -Not -Match 'TODO' -Because "TODO exist in file $($Item.Path)"
            }
        }
        It "Should not contain FIXME" {
            $ContentOfAllFiles | ForEach-Object -ThrottleLimit 15 -Parallel {
                $Item = $_
                $Item.Content | Should -Not -Match 'FIXME' -Because "FIXME exist in file $($Item.Path)"
            }
        }

    }
}