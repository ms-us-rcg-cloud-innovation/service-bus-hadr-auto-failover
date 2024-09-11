import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.ServiceBusQueueTrigger;
import com.microsoft.azure.functions.ExecutionContext;

import java.util.concurrent.ThreadLocalRandom;

/**
 * Azure Functions with Service Bus Queue Trigger.
 */
public class Function {
    /**
     * This function is triggered when a new message is received in the Service Bus queue.
     */
    @FunctionName("ServiceBusQueueTriggerExample")
    public void run(
            @ServiceBusQueueTrigger(name = "message", queueName = "ingress", connection = "SERVICE_BUS_ALIAS_CONNECTION_STRING") String message,
            final ExecutionContext context) {

        context.getLogger().info("Java Service Bus queue trigger processed a message: " + message);

        try {

            ServiceBusSender sender = new ServiceBusSender();
            sender.sendMessageToQueues("Processing message content!");

            // Sleep the active thread for the generated duration
            int sleepDuration = ThreadLocalRandom.current().nextInt(1, 7);
            context.getLogger().info("Sleeping for " + sleepDuration + " seconds.");
            Thread.sleep(sleepDuration * 1000);
            context.getLogger().info("Finished sleeping for " + sleepDuration + " seconds.");

        } catch (InterruptedException e) {
            context.getLogger().severe("SB function processing error: " + e.getMessage());
        }
    }
}