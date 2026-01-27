using System.Text;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Newtonsoft.Json;
using Microsoft.Extensions.Configuration;
using System.IO;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;
using System.Runtime.InteropServices;
using System.Reflection.Metadata;

class Program
{
    // Use "$Default" consumer group or create a custom one in the Azure portal.
    private const string consumerGroup = "$Default";

    static async Task EnsureDatabaseSchemaAsync(string sqlDbConnectionString)
    {
        using (SqlConnection conn = new SqlConnection(sqlDbConnectionString))
        {
            await conn.OpenAsync();
            
            var createTableSql = @"
                IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EventsTable')
                BEGIN
                    CREATE TABLE EventsTable (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        DeviceId NVARCHAR(100),
                        Temperature FLOAT,
                        Humidity FLOAT,
                        Timestamp DATETIME2,
                        Payload NVARCHAR(MAX),
                        EventTime DATETIME2 DEFAULT GETUTCDATE()
                    );
                END";
            
            using (SqlCommand cmd = new SqlCommand(createTableSql, conn))
            {
                await cmd.ExecuteNonQueryAsync();
                Console.WriteLine("Database schema verified/created.");
            }
        }
    }
    static async Task Main()
    {
        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
            .AddEnvironmentVariables()
            .Build();

        // Read the actual VALUES from configuration with null checks
        string? connectionString = configuration["Azure:EventHub:ConnectionString"];
        string? eventHubName = configuration["Azure:EventHub:EventHubName"];
        string? sqlDbConnectionString = configuration["Azure:SqlDatabase:ConnectionString"];

        if (string.IsNullOrEmpty(connectionString))
        {
            throw new InvalidOperationException("Event Hub connection string is not configured in appsettings.json");
        }

        if (string.IsNullOrEmpty(eventHubName))
        {
            throw new InvalidOperationException("Event Hub name is not configured in appsettings.json");
        }

        if (string.IsNullOrEmpty(sqlDbConnectionString))
        {
            throw new InvalidOperationException("SQL Database connection string is not configured in appsettings.json");
        }

        // Ensure database schema exists
        await EnsureDatabaseSchemaAsync(sqlDbConnectionString);

        Console.WriteLine($"Connecting to Event Hub: {eventHubName}");

        await using (var consumerClient = new EventHubConsumerClient(consumerGroup, connectionString, eventHubName))
        {
            Console.WriteLine("Listening for events...");

            // Read events from the Event Hub
            await foreach (PartitionEvent partitionEvent in consumerClient.ReadEventsAsync())
            {
                if (partitionEvent.Data != null)
                {
                    string eventData = Encoding.UTF8.GetString(partitionEvent.Data.Body.ToArray());
                    Console.WriteLine($"Received event: {eventData}");

                    // Insert the event into Azure SQL Database
                    await InsertEventIntoSqlAsync(eventData);
                }
            }
        }
    }

    static async Task InsertEventIntoSqlAsync(string eventDataJson)
    {
        // Add debugging to see the raw JSON
        Console.WriteLine($"Raw JSON received:  {eventDataJson}");
     
        DeviceData? deviceData = null; // Changed: Use nullable type, remove initialization
        try
        {
            // Deserialize the message
            //var deviceData = JsonConvert.DeserializeObject<DeviceData>(eventDataJson);
            deviceData = JsonConvert.DeserializeObject<DeviceData>(eventDataJson);
            if (deviceData == null)
            {
                Console.WriteLine("Failed to deserialize event data.");
                return;
            }
            Console.WriteLine($"Inserting data for DeviceId: {deviceData.DeviceId}, Temperature: {deviceData.Temperature}, Humidity: {deviceData.Humidity}");
        }
        catch (JsonReaderException ex)
        {
            Console.WriteLine($"JSON Deserialization Error: {ex.Message}");
            Console.WriteLine($"Problematic JSON: {eventDataJson}");
            throw;
        }

        // Read SQL Database connection string from configuration
        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
            .AddEnvironmentVariables()
            .Build();
        string? sqlDbConnectionString = configuration["Azure:SqlDatabase:ConnectionString"];
        if (string.IsNullOrEmpty(sqlDbConnectionString))
        {
            throw new InvalidOperationException("SQL Database connection string is not configured in appsettings.json");
        }

        // Example with raw SqlConnection, consider using a ORM like Entity Framework Core for production
        using (SqlConnection conn = new SqlConnection(sqlDbConnectionString))
        {
            await conn.OpenAsync();

            // Assuming your table 'EventsTable' has a 'Payload' column for the raw JSON
            // Insert only if not exists (atomic operation)
            var sql = @"
                IF NOT EXISTS (SELECT 1 FROM EventsTable WHERE DeviceId = @DeviceId AND Timestamp = @Timestamp)
                BEGIN
                    INSERT INTO EventsTable (DeviceId, Temperature, Humidity, Timestamp, Payload, EventTime) 
                    VALUES (@DeviceId, @Temperature, @Humidity, @Timestamp, @Payload, @EventTime)
                END";

            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@DeviceId", deviceData.DeviceId);
                cmd.Parameters.AddWithValue("@Temperature", deviceData.Temperature);
                cmd.Parameters.AddWithValue("@Humidity", deviceData.Humidity);
                cmd.Parameters.AddWithValue("@Timestamp", deviceData.Timestamp);
                cmd.Parameters.AddWithValue("@Payload", eventDataJson);
                cmd.Parameters.AddWithValue("@EventTime", DateTime.UtcNow); // Use an appropriate timestamp

            int rowsAffected = await cmd.ExecuteNonQueryAsync();
            
            if (rowsAffected > 0)
            {
                Console.WriteLine("Data inserted successfully.");
            }
            else
            {
                Console.WriteLine($"Record already exists for DeviceId: {deviceData.DeviceId}, Timestamp: {deviceData.Timestamp}. Skipping insert.");
            }
            }
        }
    }
}