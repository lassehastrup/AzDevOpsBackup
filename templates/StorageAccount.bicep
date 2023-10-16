targetScope = 'resourceGroup'

param storageAccountName string
param storageAccountType string
param location string
param storageAccountKind string = 'StorageV2'
param accessTier string = 'Hot'
param containerName string
param ServicePrincipalObjectId string
// param PrivateEndpointSubnetResourceId string

var ReuqiredPermissions = [
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
]

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: storageAccountKind
  sku: {
    name: storageAccountType
  }
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: true

  }
}

resource StorageAccountWithContainer 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource BackupContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: containerName
  parent: StorageAccountWithContainer
}

// // Private endpoint for Storage Account

// resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
//   name: guid('pe', storageAccount.name)
//   location: location
//   properties: {
//     subnet: {
//       id: PrivateEndpointSubnetResourceId
//     }
//     privateLinkServiceConnections: [
//       {
//         name: guid('plsc', storageAccount.name)
//         properties: {
//           privateLinkServiceId: storageAccount.id
//           groupIds: [
//             'blob'
//           ]
//         }
//       }
//     ]
//   }
// }

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for permission in ReuqiredPermissions: {
  name: guid(permission, storageAccount.name)
  scope: storageAccount
  properties: {
    principalType: 'ServicePrincipal'
    principalId: ServicePrincipalObjectId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', permission)
  }
}]
