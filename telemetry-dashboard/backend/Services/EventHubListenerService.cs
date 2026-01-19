using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Microsoft.AspNetCore.SignalR;
using System.Text;

public class EventHubListenerService : BackgroundService
{
    private readonly ILogger<EventHubListenerService> _logger;
    private readonly IConfiguration _configuration;
    private readonly IHubContext<TelemetryHub> _hubContext;
    private EventHubConsumerClient _consumerClient;

    public EventHubListenerService(
        ILogger<EventHubListenerService> logger,
        IConfiguration configuration,
        IHubContext<TelemetryHub> hubContext)
    {
        _logger = logger;
        _configuration = configuration;
        _hubContext = hubContext;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        Console.WriteLine("Event Hub Listener Service starting...");
        try
        {
            string connectionString = _configuration["Azure:EventHub:ConnectionString"];
            string eventHubName = _configuration["Azure:EventHub:EventHubName"];
             Console.WriteLine("connectionString: " + connectionString + ", eventHubName: " + eventHubName);
            _consumerClient = new EventHubConsumerClient(
                EventHubConsumerClient.DefaultConsumerGroupName,
                connectionString,
                eventHubName);

            _logger.LogInformation("Starting Event Hub listener...");

            await foreach (PartitionEvent partitionEvent in _consumerClient.ReadEventsAsync(stoppingToken))
            {
                try
                {
                    string messageBody = Encoding.UTF8.GetString(partitionEvent.Data.Body.ToArray());
                    _logger.LogInformation($"Received message: {messageBody}");

                    // Broadcast to all connected SignalR clients
                    await _hubContext.Clients.All.SendAsync("ReceiveTelemetry", messageBody, cancellationToken: stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError($"Error processing message: {ex.Message}");
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError($"Event Hub listener error: {ex.Message}");
        }
    }

    public async override void Dispose()
    {
        if (_consumerClient != null)
        {
            await _consumerClient.CloseAsync();
        }
        base.Dispose();
    }
}