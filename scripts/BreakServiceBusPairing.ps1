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

# Check and wait for pairing status to be unpaired
$pairingStatus = az servicebus georecovery-alias show --alias $alias `
                                                     --namespace-name $serviceBusPrimaryNamespace `
                                                     --resource-group $resourceGroup `
                                                     --subscription $subscriptionId |
                 ConvertFrom-Json |
                 Select-Object -ExpandProperty pairingState

while ($pairingStatus -ne "Unpaired") {
    Write-Host "Waiting for pairing status to be unpaired..."
    Start-Sleep -Seconds 10
    $pairingStatus = az servicebus georecovery-alias show --alias $alias `
                                                         --namespace-name $serviceBusPrimaryNamespace `
                                                         --resource-group $resourceGroup `
                                                         --subscription $subscriptionId |
                     ConvertFrom-Json |
                     Select-Object -ExpandProperty pairingState
}

Write-Host "Pairing status is now unpaired."

# Check if a separate service bus instance exists
$serviceBusSecondaryNamespace = az servicebus georecovery-alias show --alias $alias `
                                                                     --namespace-name $serviceBusPrimaryNamespace `
                                                                     --resource-group $resourceGroup `
                                                                     --subscription $subscriptionId |
                               ConvertFrom-Json |
                               Select-Object -ExpandProperty partnerNamespace

if ($serviceBusSecondaryNamespace) {
    Write-Host "Separate service bus instance exists. Deleting..."

    az servicebus namespace delete --name $serviceBusSecondaryNamespace `
                                   --resource-group $resourceGroup `
                                   --subscription $subscriptionId

    Write-Host "Separate service bus instance deleted."
} else {
    Write-Host "No separate service bus instance found."
}