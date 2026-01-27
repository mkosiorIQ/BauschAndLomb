output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

# ---------------------------------------------------------------------------
# IoT Hub Outputs
# ---------------------------------------------------------------------------
output "iothub_name" {
  value = azurerm_iothub.iothub.name
}

# IoT Hub Event Hub-compatible endpoint connection string
output "iothub_eventhub_connection_string" {
  description = "Event Hub-compatible endpoint connection string for IoT Hub"
  value       = "Endpoint=${azurerm_iothub.iothub.event_hub_events_endpoint};SharedAccessKeyName=iothubowner;SharedAccessKey=${azurerm_iothub.iothub.shared_access_policy[0].primary_key};EntityPath=${azurerm_iothub.iothub.event_hub_events_path}"
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Event Hub Outputs
# ---------------------------------------------------------------------------
output "azurerm_eventhub" {
  value = azurerm_eventhub.eventhub.name
}

# Event Hub authorization rule connection string
output "eventhub_connection_string" {
  description = "Event Hub connection string"
  value       = azurerm_eventhub_authorization_rule.auth_rule.primary_connection_string
  sensitive   = true
}

# Consumer group (default)
output "eventhub_consumer_group" {
  description = "Consumer group for Event Hub"
  value       = "$Default"
}

# ---------------------------------------------------------------------------
# Storage Outputs
# ---------------------------------------------------------------------------
output "storage_container_name" {
  value = azurerm_storage_container.telemetry.name
}

output "sql_server_name" {
  value = azurerm_mssql_server.bl-server.name
}

#output "admin_password" {
#  sensitive = true
#  value     = local.admin_password
#}

output "sql_database_name" {
  value = azurerm_mssql_database.bl-db.name
}

# Storage Account connection string
output "storage_connection_string" {
  description = "Storage Account connection string for checkpointing"
  value       = azurerm_storage_account.st.primary_connection_string
  sensitive   = true
}

