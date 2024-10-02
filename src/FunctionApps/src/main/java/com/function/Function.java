import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.ServiceBusQueueTrigger;
import com.microsoft.azure.functions.ExecutionContext;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Azure Functions with Service Bus Queue Trigger.
 */
public class Function {

    String primaryConnectionString;
    String secondaryConnectionString;
    Boolean sendToSecondary;

    public Function() {
        primaryConnectionString = System.getenv("SERVICE_BUS_ALIAS_CONNECTION_STRING");
        secondaryConnectionString = System.getenv("SERVICE_BUS_SECONDARY_CONNECTION_STRING");
        sendToSecondary = System.getenv("SEND_TO_SECONDARY").equals("true");
    }

    /**
     * This function is triggered when a new message is received in the Service Bus queue.
     */
    @FunctionName("ServiceBusQueueTriggerFunction")
    public void run(
            @ServiceBusQueueTrigger(name = "message", queueName = "ingress", connection = "SERVICE_BUS_ALIAS_CONNECTION_STRING") String message,
            final ExecutionContext context) throws Exception {

        context.getLogger().info("Java Service Bus queue trigger processed a message: " + message);
        ServiceBusSender sender = null;

        try {

            sender = new ServiceBusSender(primaryConnectionString, secondaryConnectionString, sendToSecondary);

            sender.sendMessageToQueues("Processing message content.", context.getLogger());

            // Sleep the active thread for the generated duration
            int sleepDuration = ThreadLocalRandom.current().nextInt(1, 7);
            context.getLogger().info("Sleeping for " + sleepDuration + " seconds.");
            Thread.sleep(sleepDuration * 1000);
            context.getLogger().info("Finished sleeping for " + sleepDuration + " seconds.");
        } catch (Exception e) {
            context.getLogger().severe("SB function processing error - Exception: " + e.getMessage());
            throw e;
        } 
        finally {
            context.getLogger().info("SB function processing completed.");

            if (sender != null) {
                sender.close();
            }
        }
    }
}