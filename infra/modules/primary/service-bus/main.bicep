param location string
param namespaceName string
param secondaryNamespaceId string
param managedIdentityName string
param keyVaultName string

@description('If true, the Service Bus namespace will be created with Geo-Replication enabled. If false, the Service Bus namespace will be created without Geo-Replication.')
param georeplicate bool

param tags object

resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: namespaceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

module queueIngress 'queue.bicep' = {
  name: 'ingress-queue-${namespaceName}-deployment'
  dependsOn: [
    namespace
  ]
  params: {
    name: 'ingress'
    namespaceName: namespaceName
  }
}

module queueProcessing 'queue.bicep' = {
  name: 'processing-queue-${namespaceName}-deployment'
  dependsOn: [
    namespace
  ]
  params: {
    name: 'processing'
    namespaceName: namespaceName
  }
}

resource serviceBusAlias 'Microsoft.ServiceBus/namespaces/disasterRecoveryConfigs@2022-10-01-preview' = if (georeplicate) {
  parent: namespace
  dependsOn: [
    queueIngress
    queueProcessing
  ]
  name: '${namespaceName}-alias'
  properties: {
    partnerNamespace: secondaryNamespaceId
  }
}

var endpoint = georeplicate ? 'sb://${serviceBusAlias.name}.servicebus.windows.net' : 'sb://${namespace.name}.servicebus.windows.net'
var serviceBusResourceId = georeplicate ? serviceBusAlias.id : namespace.id
var apiVersion = georeplicate ? serviceBusAlias.apiVersion : namespace.apiVersion
var dependsOn = georeplicate ? [serviceBusAlias] : [namespace]

resource serviceBusConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'sb-conn-string'
  dependsOn: dependsOn
  properties: {
    value: 'Endpoint=${endpoint}/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${listKeys('${serviceBusResourceId}/AuthorizationRules/RootManageSharedAccessKey', apiVersion).primaryKey}'
  }
}

module connection 'connection.bicep' = {
  name: 'service-bus-${namespaceName}-connection-deployment'
  dependsOn: dependsOn
  params: {
    location: location
    tags: tags
    namespaceEndpoint: endpoint
    managedIdentityName: managedIdentityName
  }
}

output pairingAlias string = serviceBusAlias.name
output connectionName string = connection.outputs.name
output connStringSecretName string = serviceBusConnectionStringSecret.name
