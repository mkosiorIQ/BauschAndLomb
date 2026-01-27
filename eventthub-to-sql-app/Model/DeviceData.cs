using Newtonsoft.Json;

public class DeviceData
{
    public int Id { get; set; }
    
    [JsonProperty("deviceId")]
    public required string DeviceId { get; set; }
    
    [JsonProperty("temperature")]
    public double Temperature { get; set; }
    
    [JsonProperty("timestamp")]
    public DateTime Timestamp  { get; set; }
    
    [JsonProperty("humidity")]
    public double Humidity { get; set; }
}
