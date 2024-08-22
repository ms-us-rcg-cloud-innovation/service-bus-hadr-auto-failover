param location string
param namespaceName string
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

module queueOne 'queue.bicep' = {
  name: 'ingress-queue-${namespaceName}-deployment'
  dependsOn: [
    namespace
  ]
  params: {
    name: 'ingress'
    namespaceName: namespaceName
  }
}

module queueTwo 'queue.bicep' = {
  name: 'processing-queue-${namespaceName}-deployment'
  dependsOn: [
    namespace
  ]
  params: {
    name: 'processing'
    namespaceName: namespaceName
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
output pairingAlias string = serviceBusAlias.name
