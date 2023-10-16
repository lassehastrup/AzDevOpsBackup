function Publish-BackupArtifact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.IO.DirectoryInfo]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        $ArtifactDirectory,

        [Parameter(Mandatory)]
        [guid]
        $TenantId

    )
    begin {
        $ParameterFile = (Get-Content "$PSScriptRoot/../../../templates/azureDeploy.parameters.json" | ConvertFrom-Json).parameters

        $TmpDir = New-Item -ItemType Directory -Path "$ArtifactDirectory/../$(Get-Date -Format 'yyyy-MM-dd-HH-mm:ss')"
        Copy-Item -Path $ArtifactDirectory -Destination $TmpDir -Recurse -Force | Out-Null
        Compress-Archive -Path $TmpDir.FullName -DestinationPath "$TmpDir.zip" -Force | Out-Null

        $Context = (Get-AzStorageAccount -Name $ParameterFile.storageAccountName.value -ResourceGroupName $ParameterFile.resourceGroupName.value -ErrorAction 'Stop').Context
    }
    process {

        $BlobSplat = @{
            File             = $TmpDir.FullName + '.zip'
            Container        = $ParameterFile.containerName.value
            Blob             = "DevOps-Backup-$(Get-Date -f yyyy-MM-dd-hh:mm).zip"
            Context          = $Context
            StandardBlobTier = 'Hot'
        }
        Set-AzStorageBlobContent @BlobSplat | Out-Null


    }
    end {
        Remove-Item -Path $TmpDir.FullName -Recurse -Force
        Remove-Item ($TmpDir.FullName + '.zip') -Force
        Write-Information "Published backup artifact to storage account: $($ParameterFile.storageAccountName.value) in container: $($ParameterFile.ContainerName.value)"
    }
}