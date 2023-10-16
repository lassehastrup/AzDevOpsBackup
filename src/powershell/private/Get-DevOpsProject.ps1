function Get-DevOpsProjects {
    <#
    .SYNOPSIS
        Listing all DevOps projects in an organization
    .DESCRIPTION
        This functions will retrieve all the projects that are available in the organization
    .EXAMPLE
        Get-DevOpsProject -OrganizationName "eNettet" -Headers @{'Authorization' = 'Bearer xzy'; 'Content-Type' = 'application/json' }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $OrganizationName,

        [Parameter(Mandatory)]
        [hashtable]
        $Headers,

        [Parameter()]
        [array]
        $ExcludedProjects
    )
    begin {
        Write-Information "Getting DevOps projects for organization: $OrganizationName"
    }
    process {
        $restUri = "https://dev.azure.com/{0}/_apis/projects?api-version=7.0" -f $OrganizationName
        $project = Invoke-RestMethod -Uri $restUri -Method 'Get' -Headers $Headers -ErrorAction 'Stop'
        $RelevantProjects = $project.value | Where-Object { $_.name -notin $ExcludedProjects }
    }

    end {
        Write-Information "Retrieved $($RelevantProjects.Count) projects for organization: $OrganizationName"
        Write-Information "Excluded Projects: $(($Project.value | Where-Object { $_.name -in $ExcludedProjects }).name)"
        if ($RelevantProjects.count -ge 1) {
            return $RelevantProjects
        }
        else {
            throw "No projects found in organization: $OrganizationName"
        }
    }
}