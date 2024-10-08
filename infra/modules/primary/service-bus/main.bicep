
param namespaceName string
param secondaryNamespaceId string
param keyVaultName string
param logAnalyticsWorkspaceName string
param managedIdentityName string

@description('If true, the Service Bus namespace will be created with Geo-Replication enabled. If false, the Service Bus namespace will be created without Geo-Replication.')
param georeplicate bool

resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: namespaceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

module queueIngress 'queue.bicep' = {
  name: 'ingress-queue-${namespaceName}-deployment'
  dependsOn: [
    namespace
  ]
  params: {
    name: 'ingress'
    namespaceName: namespaceName
  }
}

module queueProcessing 'queue.bicep' = {
  name: 'processing-queue-${namespaceName}-deployment'
  dependsOn: [
    namespace
  ]
  params: {
    name: 'processing'
    namespaceName: namespaceName
  }
}

resource serviceBusAlias 'Microsoft.ServiceBus/namespaces/disasterRecoveryConfigs@2022-10-01-preview' = if (georeplicate) {
  parent: namespace
  dependsOn: [
    queueIngress
    queueProcessing
  ]
  name: '${namespaceName}-alias'
  properties: {
    partnerNamespace: secondaryNamespaceId
  }
}

var endpoint = georeplicate ? 'sb://${serviceBusAlias.name}.servicebus.windows.net' : 'sb://${namespace.name}.servicebus.windows.net'
var serviceBusResourceId = georeplicate ? serviceBusAlias.id : namespace.id
var apiVersion = georeplicate ? serviceBusAlias.apiVersion : namespace.apiVersion
var dependsOn = georeplicate ? [serviceBusAlias] : [namespace]

resource serviceBusConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'sb-conn-string'
  dependsOn: dependsOn
  properties: {
    value: 'Endpoint=${endpoint}/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${listKeys('${serviceBusResourceId}/AuthorizationRules/RootManageSharedAccessKey', apiVersion).primaryKey}'
  }
}

resource diagSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: namespace
  name: 'diag-${namespace.name}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'OperationalLogs'
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

module chaosStudio 'chaosstudio.bicep' = {
  name: 'chaos-studio-${namespaceName}-deployment'
  params: {
    namespaceName: namespaceName
    experimentName: 'chaos-sb-${namespaceName}-fault'
    managedIdentityName: managedIdentityName
    location: namespace.location
  }
}

output pairingAlias string = serviceBusAlias.name
output connStringSecretName string = serviceBusConnectionStringSecret.name
