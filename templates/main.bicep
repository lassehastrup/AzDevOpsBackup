targetScope = 'subscription'

param resourceGroupName string
param location string
param storageAccountName string
param storageAccountType string
param accessTier string
param storageAccountKind string
param containerName string
param ServicePrincipalObjectId string

resource backupResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

module storageAccount './StorageAccount.bicep' = {
  name: 'storageaccount-${guid(resourceGroupName, 'sa', containerName, backupResourceGroup.name)}'
  scope: backupResourceGroup
  params: {
    storageAccountType: storageAccountType
    storageAccountKind: storageAccountKind
    location: location
    accessTier: accessTier
    storageAccountName: storageAccountName
    containerName: containerName
    ServicePrincipalObjectId: ServicePrincipalObjectId

  }
}
