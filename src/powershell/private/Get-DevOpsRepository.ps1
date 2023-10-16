<#
.SYNOPSIS
Retrieves a DevOps repository.

.DESCRIPTION
This function retrieves a DevOps repository by name and project.

.PARAMETER Name
The name of the repository.

.PARAMETER Project
The name of the project containing the repository.

.EXAMPLE
Get-DevOpsRepository -Name "MyRepo" -Project "MyProject"

This example retrieves the "MyRepo" repository from the "MyProject" project.

#>
function Get-DevOpsRepository {
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSObject]
        $Project,

        [Parameter()]
        [string]
        $organizationName,

        [Parameter()]
        [hashtable]
        $Headers
    )
    begin {
        Write-Verbose "Getting DevOps repositories for project: $($Project.name)"
    }
    process {
        $restSplat = @{
            Uri     = "https://dev.azure.com/{0}/{1}/_apis/git/repositories?api-version=7.1-preview.1" -f $organizationName, $Project.name
            Headers = $Headers
            Method  = 'Get'
        }
        $repository = Invoke-RestMethod @restSplat
    }
    end {
        Write-Verbose "Retrieved $($repository.Count) repositories for project: $($Project.name)"
        return $repository.value
    }
}