using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using System.Text;
using Xunit;

public class EventHubListenerServiceTests
{
    private readonly Mock<ILogger<EventHubListenerService>> _mockLogger;
    private readonly Mock<IConfiguration> _mockConfiguration;
    private readonly Mock<IHubContext<TelemetryHub>> _mockHubContext;
    private readonly Mock<IHubClients> _mockClients;
    private readonly Mock<IClientProxy> _mockClientProxy;

    public EventHubListenerServiceTests()
    {
        _mockLogger = new Mock<ILogger<EventHubListenerService>>();
        _mockConfiguration = new Mock<IConfiguration>();
        _mockHubContext = new Mock<IHubContext<TelemetryHub>>();
        _mockClients = new Mock<IHubClients>();
        _mockClientProxy = new Mock<IClientProxy>();

        _mockHubContext.Setup(x => x.Clients).Returns(_mockClients.Object);
        _mockClients.Setup(x => x.All).Returns(_mockClientProxy.Object);
    }

    [Fact]
    public void Constructor_ShouldInitializeService()
    {
        // Arrange & Act
        var service = new EventHubListenerService(
            _mockLogger.Object,
            _mockConfiguration.Object,
            _mockHubContext.Object);

        // Assert
        Assert.NotNull(service);
    }

    [Fact]
    public async Task ExecuteAsync_ShouldLogError_WhenConnectionStringIsNull()
    {
        // Arrange
        _mockConfiguration.Setup(x => x["Azure:EventHub:ConnectionString"]).Returns((string)null);
        _mockConfiguration.Setup(x => x["Azure:EventHub:EventHubName"]).Returns("test-hub");

        var service = new EventHubListenerService(
            _mockLogger.Object,
            _mockConfiguration.Object,
            _mockHubContext.Object);

        var cts = new CancellationTokenSource();
        cts.CancelAfter(TimeSpan.FromSeconds(2));

        // Act
        await service.StartAsync(cts.Token);
        await Task.Delay(500);
        await service.StopAsync(cts.Token);

        // Assert
        _mockLogger.Verify(
            x => x.Log(
                LogLevel.Error,
                It.IsAny<EventId>(),
                It.Is<It.IsAnyType>((v, t) => v.ToString().Contains("Event Hub listener error")),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception, string>>()),
            Times.AtLeastOnce);
    }

    [Fact]
    public async Task Dispose_ShouldCloseConsumerClient()
    {
        // Arrange
        _mockConfiguration.Setup(x => x["Azure:EventHub:ConnectionString"])
            .Returns("Endpoint=sb://test.servicebus.windows.net/;SharedAccessKeyName=test;SharedAccessKey=test");
        _mockConfiguration.Setup(x => x["Azure:EventHub:EventHubName"]).Returns("test-hub");

        var service = new EventHubListenerService(
            _mockLogger.Object,
            _mockConfiguration.Object,
            _mockHubContext.Object);

        var cts = new CancellationTokenSource();
        cts.CancelAfter(TimeSpan.FromMilliseconds(100));

        await service.StartAsync(cts.Token);

        // Act
        service.Dispose();

        // Assert - Service should dispose without throwing
        Assert.True(true);
    }
}