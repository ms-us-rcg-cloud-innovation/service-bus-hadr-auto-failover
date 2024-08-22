$subscriptionId = $env:AZURE_SUBSCRIPTION_ID
$resourceGroup = $env:AZURE_RESOURCE_GROUP_NAME
$serviceBusPrimaryNamespace = $env:AZURE_SERVICEBUS_PRIMARY_NAMESPACE
$alias = $env:AZURE_SERVICEBUS_PAIRING_ALIAS

Write-Host "- Breaking Service Bus Pairing Alias $alias in Resource Group $resourceGroup"

az servicebus georecovery-alias break-pair --alias $alias `
                                           --namespace-name $serviceBusPrimaryNamespace `
                                           --resource-group $resourceGroup `
                                           --subscription $subscriptionId

Write-Host "- Service Bus Pairing Alias $alias Broken"