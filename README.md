# Azure Service Bus High Availability and Disaster Recovery (HADR) Auto-Failover Solution

## Description

This project provides scripts and a custom Logic App solution to monitor Azure Service Bus and trigger an automatic failover to another region in a high availability, disaster recovery (HADR) scenario. The solution ensures minimal downtime and seamless transition during regional outages or failures. It also includes a recommended but optional step of including human approval of the failover based on Microsoft's recommended best practice.

## Features

- **Automatic Monitoring**: Continuously monitors the health of Azure Service Bus instances.
- **Auto-Failover**: Automatically triggers a failover to a pre-configured secondary region when a failure is detected.
- **Custom Logic App**: Utilizes Azure Logic Apps for orchestrating the failover process.
- **Notification Alerts**: Sends alerts and notifications during failover events. Optionally include human approval process.
- **Customizable**: Easily configurable to fit different failover requirements and scenarios.

## Prerequisites

- Azure Subscription
- Azure Service Bus Instances in multiple regions
- Azure Logic App

## Getting Started

### Step 1: Clone the Repository

```bash
git clone https://github.com/ms-us-rcg-cloud-innovation/service-bus-hadr-auto-failover.git
cd service-bus-hadr-auto-failover
```

## Step 2: Configure Azure Resources

TODO

## Step 3: Deploy Scripts

TODO

## Step 4: Test Failover

TODO

## Contributing

Contributions are welcome! Please fork the repository and submit pull requests for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Support

For any questions or support, please open an issue in the repository or contact the maintainers.
