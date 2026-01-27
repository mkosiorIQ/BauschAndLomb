
dotnet new console -n IoTHubToSqlApp
cd IoTHubToSqlApp
dotnet add package Azure.Messaging.EventHubs
dotnet add package Azure.Messaging.EventHubs.Processor
dotnet add package Microsoft.Data.SqlClient
dotnet add package Newtonsoft.Json # For handling JSON messages

