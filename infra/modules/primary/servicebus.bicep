param location string
param namespaceName string
param queueName string
param secondaryNamespaceId string
param managedIdentityName string
param tags object

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' existing = {
  name: managedIdentityName
}

resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: namespaceName
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 4
  }
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    zoneRedundant: true
  }
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  parent: namespace
  name: queueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource serviceBusAlias 'Microsoft.ServiceBus/namespaces/disasterRecoveryConfigs@2022-10-01-preview' = {
  parent: namespace
  name: '${namespaceName}-alias'
  properties: {
    partnerNamespace: secondaryNamespaceId
  }
}

output namespaceId string = namespace.id
output namespaceName string = namespace.name
output queueId string = queue.id
output pairingAlias string = serviceBusAlias.name
