param location string
param namespaceName string
param secondaryNamespaceId string
param managedIdentityName string

@description('If true, the Service Bus namespace will be created with Geo-Replication enabled. If false, the Service Bus namespace will be created without Geo-Replication.')
param georeplicate bool

param tags object

module namespace '../../shared/servicebus.bicep' = {
  name: 'service-bus-${namespaceName}-deployment'
  params: {
    location: location
    namespaceName: namespaceName
    managedIdentityName: managedIdentityName
    tags: tags
    sku: georeplicate ? 'Premium' : 'Standard'
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

resource serviceBusAlias 'Microsoft.ServiceBus/namespaces/disasterRecoveryConfigs@2022-10-01-preview' = if (georeplicate) {
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

var endpoint = georeplicate ? 'sb://${serviceBusAlias.name}.servicebus.windows.net' : 'sb://${createdNamespace.name}.servicebus.windows.net'

module connection 'connection.bicep' = {
  name: 'service-bus-${namespaceName}-connection-deployment'
  params: {
    location: location
    tags: tags
    namespaceEndpoint: endpoint
    managedIdentityName: managedIdentityName
  }
}

output namespaceId string = createdNamespace.id
output namespaceName string = namespace.name
output pairingAlias string = serviceBusAlias.name
output connectionName string = connection.outputs.name
