targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary region for resources. A secondary region will be created based on paired region. This location should support Availability Zones and should have a paired region that also supports Availability Zones.')
param locationPrimary string = 'westus3'

@minLength(1)
@description('Secondary region for resources. This location should support Availability Zones and should have a paired region that also supports Availability Zones.')
param locationSecondary string = 'eastus'

var tags = {
  'azd-env-name': environmentName
}

module secondary 'modules/secondary/main.bicep' = {
  name: 'secondary-${environmentName}-deployment'
  params: {
    environmentName: environmentName
    location: locationSecondary
    tags: tags
  }
}

module primary 'modules/primary/main.bicep' = {
  name: 'primary-${environmentName}-deployment'
  dependsOn: [
    secondary
  ]
  params: {
    environmentName: environmentName
    location: locationPrimary
    tags: tags
    secondaryServiceBusNamespaceId: secondary.outputs.serviceBusNamespaceId
  }
}
