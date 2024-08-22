@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Region for resources. This location should support Availability Zones and should have a paired region that also supports Availability Zones.')
param location string

param tags object

var envLocation = '${environmentName}-${location}'
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

module managedIdentity '../shared/managedidentity.bicep' = {
  name: 'managed-identity-${envLocation}-deployment'
  params: {
    location: location
    managedIdentityName: 'id-${resourceToken}'
    tags: tags
  }
}

module logging '../shared/logging.bicep' = {
  name: 'logging-${envLocation}-deployment'
  params: {
    appInsightsName: 'appi-${resourceToken}'
    logAnalyticsWorkspaceName: 'law-${resourceToken}'
    location: location
    tags: tags
  }
}

module keyVault '../shared/keyvault.bicep' = {
  name: 'key-vault-${envLocation}-deployment'
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
  dependsOn: [
    managedIdentity
  ]
  params: {
    namespaceName: 'sb${resourceToken}'
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
  }
} 

output serviceBusNamespaceId string = servicebus.outputs.namespaceId
