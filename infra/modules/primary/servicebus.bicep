param location string
param namespaceName string
param secondaryNamespaceId string
param managedIdentityName string
param keyVaultName string
param tags object

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

module namespace '../shared/servicebus.bicep' = {
  name: 'service-bus-${namespaceName}-deployment'
  params: {
    location: location
    namespaceName: namespaceName
    managedIdentityName: managedIdentityName
    tags: tags
  }
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

resource createdNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: namespaceName
}

resource serviceBusAlias 'Microsoft.ServiceBus/namespaces/disasterRecoveryConfigs@2022-10-01-preview' = {
  parent: createdNamespace
  dependsOn: [
    namespace
    queueIngress
    queueProcessing
  ]
  name: '${namespaceName}-alias'
  properties: {
    partnerNamespace: secondaryNamespaceId
  }
}

var keyARMEndpoint = '${createdNamespace.id}/AuthorizationRules/RootManageSharedAccessKey'

resource serviceBusConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  dependsOn: [
    serviceBusAlias
  ]
  name: 'sb-conn-string'
  properties: {
    value: listKeys(keyARMEndpoint, createdNamespace.apiVersion).aliasPrimaryConnectionString
  }
}

output namespaceId string = createdNamespace.id
output namespaceName string = namespace.name
output pairingAlias string = serviceBusAlias.name
