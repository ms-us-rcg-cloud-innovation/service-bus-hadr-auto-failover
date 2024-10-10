#!/bin/bash

# Retrieve environment variables
subscriptionId="$AZURE_SUBSCRIPTION_ID"
resourceGroup="$AZURE_RESOURCE_GROUP_NAME"
serviceBusPrimaryNamespace="$AZURE_SERVICEBUS_PRIMARY_NAMESPACE"
alias="$AZURE_SERVICEBUS_PAIRING_ALIAS"
geoReplication="$AZURE_SERVICEBUS_GEO_REPLICATE"

if [ "$geoReplication" != "true" ]; then
    echo "Geo-replication is not enabled. Exiting script."
    exit 0
fi

echo "- Breaking Service Bus Pairing Alias $alias in Resource Group $resourceGroup"

# Break the Service Bus pairing
az servicebus georecovery-alias break-pair --alias "$alias" \
                                           --namespace-name "$serviceBusPrimaryNamespace" \
                                           --resource-group "$resourceGroup" \
                                           --subscription "$subscriptionId"

echo "- Service Bus Pairing Alias $alias Broken"

# Check and wait for pairing status to be unpaired
pairingStatus=$(az servicebus georecovery-alias show --alias "$alias" \
                                                     --namespace-name "$serviceBusPrimaryNamespace" \
                                                     --resource-group "$resourceGroup" \
                                                     --subscription "$subscriptionId" | \
                jq -r '.pairingState')

while [ "$pairingStatus" != "Unpaired" ]; do
    echo "Waiting for pairing status to be unpaired..."
    sleep 10
    pairingStatus=$(az servicebus georecovery-alias show --alias "$alias" \
                                                         --namespace-name "$serviceBusPrimaryNamespace" \
                                                         --resource-group "$resourceGroup" \
                                                         --subscription "$subscriptionId" | \
                    jq -r '.pairingState')
done

echo "Pairing status is now unpaired."

# Check if a separate service bus instance exists
serviceBusSecondaryNamespace=$(az servicebus georecovery-alias show --alias "$alias" \
                                                                    --namespace-name "$serviceBusPrimaryNamespace" \
                                                                    --resource-group "$resourceGroup" \
                                                                    --subscription "$subscriptionId" | \
                              jq -r '.partnerNamespace')

if [ -n "$serviceBusSecondaryNamespace" ]; then
    echo "Separate service bus instance exists. Deleting..."

    az servicebus namespace delete --name "$serviceBusSecondaryNamespace" \
                                   --resource-group "$resourceGroup" \
                                   --subscription "$subscriptionId"

    echo "Separate service bus instance deleted."
else
    echo "No separate service bus instance found."
fi