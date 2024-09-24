param name string
param location string
param tags object
param managedIdentityName string
param appServicePlanName string
param appInsightsName string
param logAnalyticsWorkspaceName string
param keyVaultName string
param storageAcctConnStringSecretName string
param serviceBusConnStringSecretName string
param serviceBusSecondaryConnStringSecretName string
param geoReplicate bool
param fileShareName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' existing = {
  name: managedIdentityName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'B3'
  }
  properties: {
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: name
  location: location
  kind: 'functionapp'
  tags: union(tags, {
    'azd-service-name':'functionapp'
  })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    keyVaultReferenceIdentity: managedIdentity.id
    siteConfig: {
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource configSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: functionApp
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${storageAcctConnStringSecretName})'
    FUNCTIONS_WORKER_RUNTIME: 'java'
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${storageAcctConnStringSecretName})'
    WEBSITE_CONTENTSHARE: fileShareName
    SERVICE_BUS_ALIAS_CONNECTION_STRING: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${serviceBusConnStringSecretName})'
    SERVICE_BUS_SECONDARY_CONNECTION_STRING: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${serviceBusSecondaryConnStringSecretName})'
    SEND_TO_SECONDARY: '${geoReplicate}'
  }
}

resource diagSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: functionApp
  name: 'diag-${functionApp.name}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output functionAppName string = functionApp.name
