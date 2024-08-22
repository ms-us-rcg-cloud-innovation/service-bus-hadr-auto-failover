param location string
param namespaceName string
param secondaryNamespaceId string
param managedIdentityName string
param tags object

module namespace '../../shared/servicebus.bicep' = {
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

module connection 'connection.bicep' = {
  name: 'service-bus-${namespaceName}-connection-deployment'
  params: {
    location: location
    tags: tags
    namespaceEndpoint: 'sb://${serviceBusAlias.name}.servicebus.windows.net'
    managedIdentityName: managedIdentityName
  }
}

output namespaceId string = createdNamespace.id
output namespaceName string = namespace.name
output pairingAlias string = serviceBusAlias.name
output connectionName string = connection.outputs.name
