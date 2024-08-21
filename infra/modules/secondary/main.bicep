targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Region for resources. This location should support Availability Zones and should have a paired region that also supports Availability Zones.')
param location string

param tags object

var envLocation = '${environmentName}-${location}'
var resourceGroupName = 'rg-${envLocation}'
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module managedIdentity '../shared/managedidentity.bicep' = {
  name: 'managed-identity-${envLocation}-deployment'
  scope: rg
  params: {
    location: location
    managedIdentityName: 'id-${resourceToken}'
    tags: tags
  }
}

module logging '../shared/logging.bicep' = {
  name: 'logging-${envLocation}-deployment'
  scope: rg
  params: {
    appInsightsName: 'appi-${resourceToken}'
    logAnalyticsWorkspaceName: 'law-${resourceToken}'
    location: location
    tags: tags
  }
}

module keyVault '../shared/keyvault.bicep' = {
  name: 'key-vault-${envLocation}-deployment'
  scope: rg
  dependsOn: [
    managedIdentity
  ]
  params: {
    keyVaultName: 'kv${resourceToken}'
    tenantId: subscription().tenantId
    location: location
    tags: tags
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsWorkspaceName
    managedIdentityName: managedIdentity.outputs.managedIdentityName
  }
}

module storageAccount '../shared/storage.bicep' = {
  name: 'storage-account-${envLocation}-deployment'
  scope: rg
  dependsOn: [
    keyVault
  ]
  params: {
    name: 'sa${resourceToken}'
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

module servicebus 'servicebus.bicep' = {
  name: 'service-bus-${envLocation}-deployment'
  scope: rg
  params: {
    namespaceName: 'sb${resourceToken}'
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
  }
} 

output serviceBusNamespaceId string = servicebus.outputs.namespaceId

output AZURE_RESOURCE_GROUP_NAME string = rg.name
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = subscription().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.outputs.storageAccountName
output AZURE_STORAGE_ACCOUNT_FILE_SHARE_NAME string = storageAccount.outputs.fileShareName
output AZURE_STORAGE_ACCOUNT_BLOB_CONTAINER_NAME string = storageAccount.outputs.blobContainerName
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.keyVaultName
output AZURE_APP_INSIGHTS_NAME string = logging.outputs.appInsightsName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = logging.outputs.logAnalyticsWorkspaceName
output AZURE_MANAGED_IDENTITY_NAME string = managedIdentity.outputs.managedIdentityName
