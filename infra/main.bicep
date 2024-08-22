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

var tags = {
  'azd-env-name': environmentName
}

resource rgSecondary 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}-${locationSecondary}'
  location: locationSecondary
  tags: tags
}

module secondary 'modules/secondary/main.bicep' = {
  name: 'secondary-${environmentName}-deployment'
  scope: rgSecondary
  params: {
    environmentName: environmentName
    location: locationSecondary
    tags: tags
  }
}

resource rgPrimary 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}-${locationPrimary}'
  location: locationPrimary
  tags: tags
}

module primary 'modules/primary/main.bicep' = {
  name: 'primary-${environmentName}-deployment'
  scope: rgPrimary
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

output AZURE_RESOURCE_GROUP_NAME string = rgPrimary.name
output AZURE_SERVICEBUS_PRIMARY_NAMESPACE string = primary.outputs.serviceBusNamespaceName
output AZURE_SERVICEBUS_PAIRING_ALIAS string = primary.outputs.serviceBusPairingAlias

// output AZURE_LOCATION string = location
// output AZURE_TENANT_ID string = subscription().tenantId
// output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
// output AZURE_LOGIC_APP_NAME string = logicApp.outputs.logicAppName
// output AZURE_FUNCTION_APP_NAME string = functionApp.outputs.functionAppName
// output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.outputs.storageAccountName
// output AZURE_STORAGE_ACCOUNT_FILE_SHARE_NAME string = storageAccount.outputs.fileShareName
// output AZURE_STORAGE_ACCOUNT_BLOB_CONTAINER_NAME string = storageAccount.outputs.blobContainerName
// output AZURE_KEY_VAULT_NAME string = keyVault.outputs.keyVaultName
// output AZURE_APP_INSIGHTS_NAME string = logging.outputs.appInsightsName
// output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = logging.outputs.logAnalyticsWorkspaceName
// output AZURE_MANAGED_IDENTITY_NAME string = managedIdentity.outputs.managedIdentityName 
