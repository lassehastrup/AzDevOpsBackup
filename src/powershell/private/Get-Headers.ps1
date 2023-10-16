function Get-Headers {
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('(\{|\()?[A-Za-z0-9]{4}([A-Za-z0-9]{4}\-?){4}[A-Za-z0-9]{12}(\}|\()?')]
        [string]$TenantId,

        [ValidateSet("AadGraph", "AnalysisServices", "Arm", "Attestation", "Batch", "DataLake", "KeyVault", "MSGraph", "OperationalInsights", "ResourceManager", "Storage", "Synapse", "DevOps")]
        [Parameter()][string]$ResourceTypeName = "Arm"
    )
    begin {
        Write-Information ("Getting Azure Bearer Token of type: {0} for tenant: {1}" -f $ResourceTypeName, $TenantId)
        if ($ResourceTypeName -eq "DevOps") {
            $Token = (Get-AzAccessToken -Resource '499b84ac-1321-427f-aa17-267ca6975798' -TenantId $TenantId -ErrorAction 'Stop').Token
        }
        else {
            try {
                $Token = (Get-AzAccessToken -ResourceTypeName $ResourceTypeName -TenantId $TenantId -ErrorAction 'Stop').Token
            }
            catch {
                Connect-AzAccount -TenantId $TenantId
                $Token = (Get-AzAccessToken -ResourceTypeName $ResourceTypeName -TenantId $TenantId -ErrorAction 'Stop').Token
            }
        }
    }
    process {
        if ($null -eq $Token) {
            throw "Unable to get Azure Bearer Token for tenant: $TenantId of type: $ResourceTypeName"
        }
        return @{"Authorization" = "Bearer $Token"; "Content-Type" = "application/json" }
    }
}