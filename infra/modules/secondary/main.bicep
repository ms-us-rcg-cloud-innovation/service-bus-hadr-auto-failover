@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Region for resources. This location should support Availability Zones and should have a paired region that also supports Availability Zones.')
param location string

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

module servicebus '../shared/servicebus.bicep' = {
  name: 'service-bus-${envLocation}-deployment'
  dependsOn: [
    managedIdentity
  ]
  params: {
    namespaceName: 'sb${resourceToken}'
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    sku: 'Premium'
  }
} 

output serviceBusNamespaceId string = servicebus.outputs.namespaceId
output serviceBusNamespaceName string = servicebus.outputs.namespaceName
