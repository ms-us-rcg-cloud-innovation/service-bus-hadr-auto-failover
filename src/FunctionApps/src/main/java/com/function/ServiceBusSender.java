import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusSenderClient;
import com.azure.messaging.servicebus.ServiceBusMessage;

public class ServiceBusSender {

    private String primaryConnectionString;
    private String secondaryConnectionString;
    private boolean sendToSecondary;
    private final String queueName = "ingress";

    public ServiceBusSender() {
        primaryConnectionString = System.getenv("SERVICE_BUS_ALIAS_CONNECTION_STRING");
        secondaryConnectionString = System.getenv("SERVICE_BUS_SECONDARY_CONNECTION_STRING");
        sendToSecondary = System.getenv("SEND_TO_SECONDARY").equals("true");
    }

    public void sendMessageToQueues(String messageContent) {
        ServiceBusSenderClient primarySenderClient = new ServiceBusClientBuilder()
            .connectionString(primaryConnectionString)
            .sender()
            .queueName(queueName)
            .buildClient();

        ServiceBusMessage message = new ServiceBusMessage(messageContent);

        try {
            primarySenderClient.sendMessage(message);
            System.out.println("Message sent to primary queue");
        } finally {
            primarySenderClient.close();
        }

        if (sendToSecondary) {
            try {

                ServiceBusSenderClient secondarySenderClient = new ServiceBusClientBuilder()
                    .connectionString(secondaryConnectionString)
                    .sender()
                    .queueName(queueName)
                    .buildClient();
    
                ServiceBusMessage secondaryMessage = message.clone();
                secondaryMessage.setTimeToLive(Duration.ofSeconds(120));
    
                secondarySenderClient.sendMessage(secondaryMessage);
                System.out.println("Message sent to secondary queue");
            } finally {
                secondarySenderClient.close();
            }
        }
    }
}