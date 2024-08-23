param location string
param namespaceName string
param managedIdentityName string
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string
param tags object

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' existing = {
  name: managedIdentityName
}

var capacity = sku == 'Basic' ? 1 : sku == 'Standard' ? 2 : 4
var zoneRedundant = sku == 'Premium'

resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: namespaceName
  location: location
  sku: {
    name: sku
    tier: sku
    capacity: capacity
  }
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    zoneRedundant: zoneRedundant
  }
}

@description('This is the built-in Azure Service Bus Data Receiver role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#security')
resource serviceBusDataReceiverRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
}

resource receiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(namespace.id, managedIdentity.id, serviceBusDataReceiverRoleDefinition.id)
  scope: namespace
  properties: {
    roleDefinitionId: serviceBusDataReceiverRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('This is the built-in Azure Service Bus Data Sender role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#security')
resource serviceBusDataSenderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
}

resource senderRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(namespace.id, managedIdentity.id, serviceBusDataSenderRoleDefinition.id)
  scope: namespace
  properties: {
    roleDefinitionId: serviceBusDataSenderRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output namespaceId string = namespace.id
