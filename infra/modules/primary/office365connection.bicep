param connectionName string = 'office365'
param location string
param tags object

param managedIdentityName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' existing = {
  name: managedIdentityName
}

resource connection 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: location
  tags: tags
  kind: 'v2'
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365') 
    }
    displayName: '${connectionName}-connection'
    parameterValues: {}
  }
}

resource accessPolicy 'Microsoft.Web/connections/accessPolicies@2016-06-01' = {
  name: '${connectionName}${managedIdentity.name}'
  parent: connection
  location: location
  properties: {
    principal: {
      type: 'ActiveDirectory'
      identity: {
         objectId: managedIdentity.properties.principalId
         tenantId: managedIdentity.properties.tenantId
      }
   }
  }
}

output name string = connection.name
output id string = connection.id
output apiId string = connection.properties.api.id
output connectionRuntimeUrl string = connection.properties.connectionRuntimeUrl
