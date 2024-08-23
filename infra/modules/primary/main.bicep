@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Region for resources. This location should support Availability Zones and should have a paired region that also supports Availability Zones.')
param location string

@description('If true, the Service Bus namespace will be created with Geo-Replication enabled. If false, the Service Bus namespace will be created without Geo-Replication.')
param georeplicate bool

param secondaryServiceBusNamespaceId string

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

module logging 'logging.bicep' = {
  name: 'logging-${envLocation}-deployment'
  params: {
    appInsightsName: 'appi-${resourceToken}'
    logAnalyticsWorkspaceName: 'law-${resourceToken}'
    location: location
    tags: tags
  }
}

module keyVault 'keyvault.bicep' = {
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

module storageAccount 'storage.bicep' = {
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

module servicebus './service-bus/namespace.bicep' = {
  name: 'service-bus-${envLocation}-deployment'
  dependsOn: [
    managedIdentity
    keyVault
  ]
  params: {
    namespaceName: 'sb${resourceToken}'
    secondaryNamespaceId: secondaryServiceBusNamespaceId
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    georeplicate: georeplicate
  }
} 

module logicApp 'logicapp.bicep' = {
  name: 'logic-app-${envLocation}-deployment'
  dependsOn: [
    managedIdentity
    storageAccount
    servicebus
  ]
  params: {
    name: 'logic-${resourceToken}'
    appServicePlanName: 'asp-logic-${resourceToken}'
    appInsightsName: logging.outputs.appInsightsName
    keyVaultName: keyVault.outputs.keyVaultName
    location: location
    tags: tags
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsWorkspaceName
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    fileShareName: storageAccount.outputs.fileShareName
    storageAcctConnStringName: storageAccount.outputs.connStringSecretName
    serviceBusConnectionName: servicebus.outputs.connectionName
  }
}

module functionApp 'functionapp.bicep' = {
  name: 'function-app-${envLocation}-deployment'
  dependsOn: [
    managedIdentity
    storageAccount
    servicebus
  ]
  params: {
    name: 'func-${resourceToken}'
    appServicePlanName: 'asp-func-${resourceToken}'
    appInsightsName: logging.outputs.appInsightsName
    keyVaultName: keyVault.outputs.keyVaultName
    location: location
    tags: tags
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsWorkspaceName
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    storageAcctConnStringName: storageAccount.outputs.connStringSecretName
    fileShareName: storageAccount.outputs.fileShareName
    storageAcctContainerName: storageAccount.outputs.blobContainerName
  }
}

output serviceBusNamespaceId string = servicebus.outputs.namespaceId
output serviceBusNamespaceName string = servicebus.outputs.namespaceName
output serviceBusPairingAlias string = servicebus.outputs.pairingAlias

