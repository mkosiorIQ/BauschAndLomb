var builder = WebApplication.CreateBuilder(args);

// Add Azure SignalR
builder.Services.AddSignalR();
//builder.Services.AddSignalR()
//    .AddAzureSignalR(builder.Configuration["Azure:SignalR:ConnectionString"]);

// Add Event Hub client
builder.Services.AddSingleton(sp => 
    new Azure.Messaging.EventHubs.Consumer.EventHubConsumerClient(
        "$Default",
        builder.Configuration["Azure:EventHub:ConnectionString"]));

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddControllers();
builder.Services.AddHostedService<EventHubListenerService>();

// Inside Program.cs, before app.Build() or similar
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend",
        builder =>
        {
            builder.WithOrigins("http://localhost:3000") // Default React port
                   .AllowAnyMethod()    // Allows all HTTP methods (GET, POST, PUT, DELETE, etc.)
                   .AllowAnyHeader()    // Allows all headers
                   .AllowCredentials(); // Important for SignalR
        });
});

var app = builder.Build();

// After app.Build() and before app.Run()
app.UseCors("AllowFrontend");
app.MapHub<TelemetryHub>("/telemetryHub");

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

Console.WriteLine("Map Controllers...");
app.MapControllers();

Console.WriteLine("Running the application...");
app.Run();
