targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary region for resources. A secondary region will be created based on paired region. This location should support Availability Zones and should have a paired region that also supports Availability Zones.')
param locationPrimary string

@minLength(1)
@description('Secondary region for resources. This location should support Availability Zones and should have a paired region that also supports Availability Zones.')
param locationSecondary string

@description('If true, the Service Bus namespace will be created with Geo-Replication enabled. If false, the Service Bus namespace will be created without Geo-Replication.')
param georeplicate bool = true

@minLength(1)
param notificationEmail string

var tags = {
  'azd-env-name': environmentName
}

resource rgSecondary 'Microsoft.Resources/resourceGroups@2021-04-01' = if (georeplicate) {
  name: 'rg-${environmentName}-secondary-${locationSecondary}'
  location: locationSecondary
  tags: tags
}

module secondary 'modules/secondary/main.bicep' = if (georeplicate) {
  name: 'secondary-${environmentName}-deployment'
  scope: rgSecondary
  params: {
    environmentName: environmentName
    location: locationSecondary
    tags: tags
  }
}

resource rgPrimary 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}-primary-${locationPrimary}'
  location: locationPrimary
  tags: tags
}

var primaryDependsOn = georeplicate ? [secondary] : []

module primary 'modules/primary/main.bicep' = {
  name: 'primary-${environmentName}-deployment'
  scope: rgPrimary
  dependsOn: primaryDependsOn
  params: {
    environmentName: environmentName
    location: locationPrimary
    tags: tags
    secondaryServiceBusNamespaceId: georeplicate ? secondary.outputs.serviceBusNamespaceId : ''
    secondaryResourceGroupName: georeplicate ? rgSecondary.name : rgPrimary.name
    secondaryServiceBusNamespaceName: georeplicate ? secondary.outputs.serviceBusNamespaceName : ''
    georeplicate: georeplicate
    notificationEmail: notificationEmail
  }
}

output AZURE_RESOURCE_GROUP_NAME string = rgPrimary.name
output AZURE_RESOURCE_GROUP string = rgPrimary.name
output AZURE_LOGIC_APP_NAME string = primary.outputs.logicAppName
output AZURE_SERVICEBUS_PRIMARY_NAMESPACE string = primary.outputs.serviceBusNamespaceName
output AZURE_SERVICEBUS_PAIRING_ALIAS string = primary.outputs.serviceBusPairingAlias
