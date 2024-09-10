#!/bin/bash

MissingSomething=false

greenCheck() {
    echo -e "\e[32m✔\e[0m"
}

# Check if the needed components are installed
echo "------------------------------------"
echo "Checking Azure CLI"
if command -v az &> /dev/null
then
    greenCheck
else
    echo ">>>> Azure CLI not installed. Please install and try again."
    MissingSomething=true
fi
echo ""

echo "------------------------------------"
echo "Checking Azure Developer CLI (azd)"
if command -v azd &> /dev/null
then
    azdVersion=$(azd version)
    greenCheck
    echo " - Azure Developer CLI version: $azdVersion"
else
    echo ">>>> Azure Developer CLI not installed. Please install and try again."
    echo ">>>> You can install it by running the following command in a terminal window: winget install microsoft.azd"
    MissingSomething=true
fi
echo ""

echo "------------------------------------"
echo "Checking Azure Functions Core Tools"
if command -v func &> /dev/null
then
    funcVersion=$(func --version)
    greenCheck
    echo " - Azure Functions Core Tools version: $funcVersion"
else
    echo ">>>> Azure Functions Core Tools not installed. Please install and try again."
    echo ">>>> You can install it by visiting https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local"
    MissingSomething=true
fi
echo ""

if [ "$MissingSomething" = true ]; then
    echo "------------------------------------"
    echo "One or more components are missing."
    echo "Please review the log above and install the missing components before continuing."
else
    echo "------------------------------------"
    echo -e "\e[32mAll dependent components installed!\e[0m"
    echo "------------------------------------"
fi