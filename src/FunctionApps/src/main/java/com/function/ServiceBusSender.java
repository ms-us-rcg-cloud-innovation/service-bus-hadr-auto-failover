import java.io.Closeable;
import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusSenderClient;
import com.azure.messaging.servicebus.ServiceBusMessage;
import java.time.Duration;
import java.util.logging.Logger;

public class ServiceBusSender implements Closeable {

    private final String queueName = "processing";

    ServiceBusSenderClient primarySenderClient;
    ServiceBusSenderClient secondarySenderClient;
    Boolean sendToSecondary;

    public ServiceBusSender(String primaryConnString, String secondaryConnString, Boolean sendToSecondary) {
        this.sendToSecondary = sendToSecondary;

        this.primarySenderClient = new ServiceBusClientBuilder()
            .connectionString(primaryConnString)
            .sender()
            .queueName(queueName)
            .buildClient();

        if (sendToSecondary) {
            this.secondarySenderClient = new ServiceBusClientBuilder()
                .connectionString(secondaryConnString)
                .sender()
                .queueName(queueName)
                .buildClient();
        }
    }

    public void sendMessageToQueues(String messageContent, Logger logger) {
        ServiceBusMessage message = new ServiceBusMessage(messageContent);

        primarySenderClient.sendMessage(message);
        logger.info("Message sent to primary queue.");

        if (sendToSecondary) {
            Thread secondaryQueueThread = new Thread(() -> {
                try {
                    ServiceBusMessage secondaryMessage = message;
                    secondaryMessage.setTimeToLive(Duration.ofSeconds(120));

                    secondarySenderClient.sendMessage(secondaryMessage);

                    logger.info("Message sent to secondary queue");
                }
                catch (Exception e) {
                    logger.severe("Error sending message to secondary queue: " + e.getMessage());
                }
            });

            secondaryQueueThread.start();
        }
    }

    @Override
    public void close() {
        if (primarySenderClient != null) {
            primarySenderClient.close();
        }
        if (secondarySenderClient != null) {
            secondarySenderClient.close();
        }
    }
}