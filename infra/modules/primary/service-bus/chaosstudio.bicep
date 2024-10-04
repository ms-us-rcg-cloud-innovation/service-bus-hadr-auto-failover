param namespaceName string
param experimentName string
param managedIdentityName string
param location string

resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: namespaceName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' existing = {
  name: managedIdentityName
}

resource chaosTarget 'Microsoft.Chaos/targets@2024-01-01' = {
  name: 'Microsoft-ServiceBus'
  location: location
  scope: namespace
  properties: {}

  resource chaosCapability 'capabilities' = {
    name: 'ChangeQueueState-1.0'
  }
}

var targetSelectorId = guid(namespace.name, chaosTarget.name, 'selector')

resource chaosExperiment 'Microsoft.Chaos/experiments@2024-01-01' = {
  name: experimentName
  location: location 
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    selectors: [
      {
        id: targetSelectorId
        type: 'List'
        targets: [
          {
            id: chaosTarget.id
            type: 'ChaosTarget'
          }
        ]
      }
    ]
    steps: [
      {
        name: 'Step1'
        branches: [
          {
            name: 'Branch 1'
            actions: [
              {
                selectorId: targetSelectorId
                type: 'discrete'
                parameters: [
                  {
                    key: 'queues'
                    value: '["processing"]'
                  }
                  {
                    key: 'desiredState'
                    value: 'Disabled'
                  }
                ]
                name: 'urn:csci:microsoft:serviceBus:changeQueueState/1.0'
              }
              {
                type: 'delay'
                duration: 'PT15M'
                name: 'urn:csci:microsoft:chaosStudio:TimedDelay/1.0'
              }
              {
                selectorId: targetSelectorId
                type: 'discrete'
                parameters: [
                  {
                    key: 'queues'
                    value: '["processing"]'
                  }
                  {
                    key: 'desiredState'
                    value: 'Active'
                  }
                ]
                name: 'urn:csci:microsoft:serviceBus:changeQueueState/1.0'
              }
            ]
          }
        ]
      }
    ]
  }
}

@description('This is the built-in Azure Service Bus Data Owner role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#security')
resource serviceBusDataOwnerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '090c5cfd-751d-490a-894a-3ce6f1109419'
}

resource ownerRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(chaosExperiment.id, managedIdentity.id, serviceBusDataOwnerRoleDefinition.id)
  scope: namespace
  properties: {
    roleDefinitionId: serviceBusDataOwnerRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
