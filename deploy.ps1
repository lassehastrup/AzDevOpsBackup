[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $TenantId,

    [Parameter(Mandatory)]
    [string]
    $SubscriptionId,

    [Parameter(Mandatory)]
    [string]
    $OrganizationName
)

begin {
    $InformationPreference = 'Continue'
    Import-Module "$PSScriptRoot/src/powershell/DevOpsBackup.psm1" -Force
    Set-AzContext -TenantId $TenantId -SubscriptionId $SubscriptionId | Out-Null
    $Headers = Get-Headers -TenantId $TenantId
    $DeploymentParameterFile = "$PSScriptRoot/templates/azureDeploy.parameters.json"
    $excludedProjects = (Get-Content "$PSScriptRoot/config/backupExclusions.json" | ConvertFrom-Json).projects
    if (Test-Path "$PSScriptRoot/artifacts") {
        Remove-Item -Path "$PSScriptRoot/artifacts" -Recurse -Force
    }
}
process {
    $AllProjects = Get-DevOpsProjects -OrganizationName $OrganizationName -Headers $Headers -ExcludedProjects $excludedProjects

    # Retrieving relevant project and repository settings
    foreach ($project in $AllProjects) {
        Get-DevOpsProjectInformation -Project $project -OrganizationName $OrganizationName -Headers $Headers
    }

    # Performing bicep deployment og Storage account, blob service and container to store the backup
    # Configuring permissions on the storage account
    $splat = @{
        Name                  = "mainDeploy-$((Get-Date).Ticks)"
        Location              = ((Get-Content "$PSScriptRoot/templates/azureDeploy.parameters.json") | ConvertFrom-Json).parameters.location.value
        TemplateFile          = "$PSScriptRoot/templates/main.bicep"
        TemplateParameterFile = $DeploymentParameterFile
        Verbose               = $false
    }
    New-AzDeployment @splat | Out-Null

    # Uploading the backup configuration file to the storage account
    Publish-BackupArtifact -ArtifactDirectory "$PSScriptRoot/artifacts/" -TenantId $TenantId
}
end {
    # Applying locks on the subscription to prevent accidental deletion of resources
    $ResourceLocks = Set-AzResourceLock -LockName "DevOpsBackup" -LockNotes "Locking ResourceGroup to prevent accidental deletion of resources" -LockLevel CanNotDelete -ResourceGroupName $(Get-Content $DeploymentParameterFile | ConvertFrom-Json).parameters.resourceGroupName.value  -Force
    Write-Information "Applied locks on resource group: $($ResourceLocks.ResourceGroupName)"
    Write-Information "Backup completed successfully"
}
