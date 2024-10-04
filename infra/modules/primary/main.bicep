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

param notificationEmail string

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

module servicebusNamespace '../shared/servicebus.bicep' = {
  name: 'service-bus-${envLocation}-deployment'
  params: {
    location: location
    namespaceName: 'sb${resourceToken}'
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    tags: tags
    sku: georeplicate ? 'Premium' : 'Standard'
  }
}

module servicebusAppItems './service-bus/main.bicep' = {
  name: 'service-bus-items-${envLocation}-deployment'
  dependsOn: [
    servicebusNamespace
    keyVault
  ]
  params: {
    namespaceName: servicebusNamespace.outputs.namespaceName
    secondaryNamespaceId: secondaryServiceBusNamespaceId
    keyVaultName: keyVault.outputs.keyVaultName
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsWorkspaceName
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    georeplicate: georeplicate
  }
} 

module office365Connection 'office365connection.bicep' = {
  name: 'office365-connection-${envLocation}-deployment'
  dependsOn: [
    managedIdentity
  ]
  params: {
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
  }
}

module logicApp 'logicapp.bicep' = {
  name: 'logic-app-${envLocation}-deployment'
  dependsOn: [
    managedIdentity
    storageAccount
    servicebusNamespace
    servicebusAppItems
    office365Connection
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
    fileShareName: storageAccount.outputs.logicAppFileShareName
    storageAcctConnStringSecretName: storageAccount.outputs.connStringSecretName
    serviceBusConnStringSecretName: servicebusAppItems.outputs.connStringSecretName
    serviceBusNamespaceName: servicebusNamespace.outputs.namespaceName
    notificationEmail: notificationEmail
    office365ConnectionName: office365Connection.outputs.name
  }
}

module functionApp 'functionapp.bicep' = {
  name: 'function-app-${envLocation}-deployment'
  dependsOn: [
    managedIdentity
    storageAccount
    servicebusNamespace
    servicebusAppItems
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
    storageAcctConnStringSecretName: storageAccount.outputs.connStringSecretName
    serviceBusConnStringSecretName: servicebusAppItems.outputs.connStringSecretName
    serviceBusSecondaryConnStringSecretName: servicebusAppItems.outputs.connStringSecretName
    geoReplicate: georeplicate
    fileShareName: storageAccount.outputs.funcFileShareName
  }
}

output logicAppName string = logicApp.outputs.name
output serviceBusNamespaceId string = servicebusNamespace.outputs.namespaceId
output serviceBusNamespaceName string = servicebusNamespace.outputs.namespaceName
output serviceBusPairingAlias string = servicebusAppItems.outputs.pairingAlias

