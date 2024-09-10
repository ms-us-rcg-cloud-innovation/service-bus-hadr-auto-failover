#!/bin/bash

# Retrieve environment variables
logicAppName="$AZURE_LOGIC_APP_NAME"
resourceGroupName="$AZURE_RESOURCE_GROUP_NAME"

# Set error handling
set -e

# Define directories
dir="$(dirname "$0")"
root="$(realpath "$dir/../")"

# Change to the root directory
pushd "$root" > /dev/null

# Create output directory
mkdir -p output

echo "- Setting up Logic App"

# Compress the Logic Apps directory
zip -r output/workflows.zip src/LogicApps/*

# Deploy the Logic App using Azure CLI
az logicapp deployment source config-zip --name "$logicAppName" --resource-group "$resourceGroupName" --src output/workflows.zip
echo "- Logic App Setup Complete for $logicAppName in $resourceGroupName."

# Return to the original directory
popd > /dev/null