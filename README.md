# Azure Service Bus High Availability and Disaster Recovery (HADR) Auto-Failover Solution

## Description

This project provides scripts and a custom Logic App solution to monitor Azure Service Bus and trigger an automatic failover to another region in a high availability, disaster recovery (HADR) scenario. The solution ensures minimal downtime and seamless transition during regional outages or failures. It also includes a recommended but optional step of including human approval of the failover based on Microsoft's recommended best practice.

## Features

- **Automatic Monitoring**: Continuously monitors the health of Azure Service Bus instances.
- **Auto-Failover**: Automatically triggers a failover to a pre-configured secondary region when a failure is detected.
- **Custom Logic App**: Utilizes Azure Logic Apps for orchestrating the failover process.
- **Notification Alerts**: Sends alerts and notifications during failover events. Optionally include human approval process.
- **Customizable**: Easily configurable to fit different failover requirements and scenarios.

## Architecture

![Architecture](/assets/architecture.png)

## Setup

### Clone Repository

```bash
git clone https://github.com/ms-us-rcg-cloud-innovation/service-bus-hadr-auto-failover.git
cd service-bus-hadr-auto-failover
```

### Setup Java Environment

Setup local [Java development environment for Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-vs-code-java#configure-your-environment).

Also ensure [local environment variable JAVA_HOME is set](https://docs.oracle.com/cd/E19182-01/821-0917/inst_jdk_javahome_t/index.html) and pointing to installed Java instance.

### Check Environment

Run the CheckEnvironment.ps1 script to ensure the latest CLIs and dependencies are installed. If any dependencies are missing, the script will output guidance on how to install.

```powershell
cd scripts
.\CheckEnvironment.ps1
```

### Deploy

Establish required environment variables:

```powershell
$env:AZURE_ENV_NAME="sb-hadr" # custom project name
$env:AZURE_LOCATION_PRIMARY="eastus2" # azure region
$env:AZURE_LOCATION_SECONDARY="centralus" # azure region

# optional flag to test apps and logic without multiple premium Service Bus instances to reduce costs when testing
# this value should be true to test multi region pairing and automated failover logic
$env:AZURE_SERVICEBUS_GEO_REPLICATE=true
```

NOTE: The primary and secondary regions should be [paired regions](https://learn.microsoft.com/en-us/azure/reliability/cross-region-replication-azure#azure-paired-regions). Both regions should also [support availability zones](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-service-support#azure-regions-with-availability-zone-support) for recommended high availability.

This project uses the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview) to quickly deploy and tear down the resources and application files in Azure for demo purposes.

To get started, authenticate with an Azure Subscription ([details](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/reference#azd-auth-login)):

```powershell
azd auth login
```

To provision the necessary Azure resoruces and deploy the application, run the UP command:

```powershell
azd up
```

Once the infrastructure is established and the application is deployed, navigate to the [Azure Portal](https://portal.azure.com) to view the provisioned resources.

## Verify

TODO

## Clean Up Azure Resources

To remove the provisioned Resources run the following AZD command:

```powershell
azd down --force --purge
```

## License

This project is licensed under the [MIT License](LICENSE)

## Contributing

Contributions are welcome! Please fork the repository and submit pull requests for any enhancements or bug fixes.

## Support

For any questions or support, please open an issue in the repository or contact the maintainers.
