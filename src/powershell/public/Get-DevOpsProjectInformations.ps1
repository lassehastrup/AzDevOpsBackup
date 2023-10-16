function Get-DevOpsProjectInformation {
    [CmdletBinding()]
    param (
        [Parameter()]
        [object]
        $Project,

        [Parameter()]
        [string]
        $OrganizationName,

        [Parameter()]
        [hashtable]
        $Headers

    )
    begin {
        $Repositories = Get-DevOpsRepository -Project $Project -OrganizationName $OrganizationName -Headers $Headers
    }
    process {
        foreach ($repository in $Repositories) {
            if (!(Test-Path "$PSScriptRoot/../../../artifacts/$($project.name)")) {
                New-Item -Path "$PSScriptRoot/../../../artifacts/$($project.name)" -ItemType Directory | Out-Null
            }
            Write-Information "Downloading repository: $($repository.name)"
            $DownloadSplat = @{
                Uri     = "https://dev.azure.com/$OrganizationName/$($Project.name)/_apis/git/repositories/$($repository.name)/items?scopePath=/&`$format=zip&download=true&api-version=7.1-preview.1"
                Headers = $Headers
                Method  = 'Get'
            }
            try {
                Invoke-RestMethod @DownloadSplat -OutFile "$PSScriptRoot/../../../artifacts/$($project.name)/$($repository.name).zip" | Out-Null
            }
            catch {
                if ($_.ErrorDetails.message -match "VS403403") {
                    Write-Information "Repository $($repository.name) is empty"
                }
                else {
                    throw $_
                }
            }
        }
        # Get basic information of the project, like extensions, build definitions, release definitions, etc.
        $EndpointSplat = @{
            Uri     = "https://dev.azure.com/{0}/{1}/_apis/serviceendpoint/endpoints?api-version=7.1-preview.4" -f $OrganizationName, $Project.name
            Method  = 'Get'
            Headers = $Headers
        }
        Invoke-RestMethod @EndpointSplat | ConvertTo-Json -Depth 5 | Out-File "$PSScriptRoot/../../../artifacts/$($project.name)/serviceConnections.json"

    }
    end {
        Write-Information "Downloaded all repositories for project: $($project.name)"
    }
}