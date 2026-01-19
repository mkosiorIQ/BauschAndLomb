//using System.Net.WebSockets;
using Microsoft.AspNetCore.SignalR;

public class TelemetryHub : Hub
{
    public override async Task OnConnectedAsync()
    {
        Console.WriteLine("TelemetryHub::OnConnectedAsync Client connected: " + Context.ConnectionId);
        await Clients.All.SendAsync("ReceiveTelemetry", "Welcome! You are connected to the Telemetry Hub.");
        //return base.OnConnectedAsync();
    }

    public async Task SendTelemetry(object telemetryData)
    {
        Console.WriteLine("TelemetryHub::SendTelemetry Sending telemetry data to clients...");
        await Clients.All.SendAsync("ReceiveTelemetry", telemetryData);
    }
}