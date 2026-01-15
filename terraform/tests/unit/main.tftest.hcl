# Unit tests for the IoT Edge monitoring infrastructure
# Run with: terraform test

# Test that the resource group is configured correctly
run "test_resource_group_configuration" {
  command = plan

  assert {
    condition     = azurerm_resource_group.rg.name == "bl-monitoring-rg1"
    error_message = "Resource group name should be 'bl-monitoring-rg1'"
  }

  assert {
    condition     = azurerm_resource_group.rg.location == "East US"
    error_message = "Resource group location should be 'East US'"
  }
}

# Test that the storage account is configured correctly
run "test_storage_account_configuration" {
  command = plan

  assert {
    condition     = azurerm_storage_account.st.account_tier == "Standard"
    error_message = "Storage account tier should be 'Standard'"
  }

  assert {
    condition     = azurerm_storage_account.st.account_replication_type == "LRS"
    error_message = "Storage account replication should be 'LRS'"
  }

  assert {
    condition     = azurerm_storage_account.st.is_hns_enabled == true
    error_message = "Storage account should have hierarchical namespace enabled (ADLS Gen2)"
  }

  assert {
    condition     = azurerm_storage_account.st.min_tls_version == "TLS1_2"
    error_message = "Storage account should enforce minimum TLS version 1.2"
  }

  assert {
    condition     = can(azurerm_storage_account.st.identity[0].type)
    error_message = "Storage account should have a system-assigned managed identity"
  }

  assert {
    condition     = azurerm_storage_account.st.identity[0].type == "SystemAssigned"
    error_message = "Storage account identity should be 'SystemAssigned'"
  }
}

# Test that the storage container is configured correctly
run "test_storage_container_configuration" {
  command = plan

  assert {
    condition     = azurerm_storage_container.telemetry.name == "telemetry"
    error_message = "Storage container name should be 'telemetry'"
  }

  assert {
    condition     = azurerm_storage_container.telemetry.container_access_type == "private"
    error_message = "Storage container access type should be 'private'"
  }
}

# Test that the Event Hub namespace is configured correctly
run "test_eventhub_namespace_configuration" {
  command = plan

  assert {
    condition     = azurerm_eventhub_namespace.namespace.sku == "Basic"
    error_message = "Event Hub namespace SKU should be 'Basic'"
  }

  assert {
    condition     = azurerm_eventhub_namespace.namespace.capacity == 1
    error_message = "Event Hub namespace capacity should be 1"
  }
}

# Test that the Event Hub is configured correctly
run "test_eventhub_configuration" {
  command = plan

  assert {
    condition     = azurerm_eventhub.eventhub.partition_count == 2
    error_message = "Event Hub should have 2 partitions"
  }

  assert {
    condition     = azurerm_eventhub.eventhub.message_retention == 1
    error_message = "Event Hub message retention should be 1 day"
  }
}

# Test that the Event Hub authorization rule is configured correctly
run "test_eventhub_auth_rule_configuration" {
  command = plan

  assert {
    condition     = azurerm_eventhub_authorization_rule.auth_rule.listen == true
    error_message = "Event Hub authorization rule should have 'listen' permission"
  }

  assert {
    condition     = azurerm_eventhub_authorization_rule.auth_rule.send == true
    error_message = "Event Hub authorization rule should have 'send' permission"
  }

  assert {
    condition     = azurerm_eventhub_authorization_rule.auth_rule.manage == false
    error_message = "Event Hub authorization rule should NOT have 'manage' permission"
  }
}

# Test that the IoT Hub is configured correctly
run "test_iothub_configuration" {
  command = plan

  assert {
    condition     = azurerm_iothub.iothub.sku[0].name == "S1"
    error_message = "IoT Hub SKU should be 'S1'"
  }

  assert {
    condition     = azurerm_iothub.iothub.sku[0].capacity == 1
    error_message = "IoT Hub capacity should be 1"
  }

  assert {
    condition     = azurerm_iothub.iothub.tags["purpose"] == "testing-azure-iothub"
    error_message = "IoT Hub should have correct 'purpose' tag"
  }

  assert {
    condition     = azurerm_iothub.iothub.tags["environment"] == "dev"
    error_message = "IoT Hub should have correct 'environment' tag"
  }
}

# Test that IoT Hub storage endpoint is configured correctly
run "test_iothub_storage_endpoint" {
  command = plan

  assert {
    condition     = length([for e in azurerm_iothub.iothub.endpoint : e if e.name == "export-storage-endpoint"]) == 1
    error_message = "IoT Hub should have a storage endpoint named 'export-storage-endpoint'"
  }

  assert {
    condition     = [for e in azurerm_iothub.iothub.endpoint : e if e.name == "export-storage-endpoint"][0].type == "AzureIotHub.StorageContainer"
    error_message = "Storage endpoint should be of type 'AzureIotHub.StorageContainer'"
  }

  assert {
    condition     = [for e in azurerm_iothub.iothub.endpoint : e if e.name == "export-storage-endpoint"][0].batch_frequency_in_seconds == 60
    error_message = "Storage endpoint batch frequency should be 60 seconds"
  }
}

# Test that IoT Hub Event Hub endpoint is configured correctly
run "test_iothub_eventhub_endpoint" {
  command = plan

  assert {
    condition     = length([for e in azurerm_iothub.iothub.endpoint : e if e.name == "export-eventhub-endpoint"]) == 1
    error_message = "IoT Hub should have an Event Hub endpoint named 'export-eventhub-endpoint'"
  }

  assert {
    condition     = [for e in azurerm_iothub.iothub.endpoint : e if e.name == "export-eventhub-endpoint"][0].type == "AzureIotHub.EventHub"
    error_message = "Event Hub endpoint should be of type 'AzureIotHub.EventHub'"
  }

  assert {
    condition     = [for e in azurerm_iothub.iothub.endpoint : e if e.name == "export-eventhub-endpoint"][0].batch_frequency_in_seconds == 60
    error_message = "Event Hub endpoint batch frequency should be 60 seconds"
  }
}

# Test that IoT Hub routes are configured correctly
run "test_iothub_routes" {
  command = plan

  assert {
    condition     = length(azurerm_iothub.iothub.route) == 2
    error_message = "IoT Hub should have exactly 2 routes"
  }

  assert {
    condition     = length([for r in azurerm_iothub.iothub.route : r if r.name == "export-telemetry-route-storage"]) == 1
    error_message = "IoT Hub should have a route named 'export-telemetry-route-storage'"
  }

  assert {
    condition     = length([for r in azurerm_iothub.iothub.route : r if r.name == "export-telemetry-route-eventhub"]) == 1
    error_message = "IoT Hub should have a route named 'export-telemetry-route-eventhub'"
  }

  assert {
    condition     = [for r in azurerm_iothub.iothub.route : r if r.name == "export-telemetry-route-storage"][0].source == "DeviceMessages"
    error_message = "Storage route should have source 'DeviceMessages'"
  }

  assert {
    condition     = [for r in azurerm_iothub.iothub.route : r if r.name == "export-telemetry-route-eventhub"][0].source == "DeviceMessages"
    error_message = "Event Hub route should have source 'DeviceMessages'"
  }

  assert {
    condition     = [for r in azurerm_iothub.iothub.route : r if r.name == "export-telemetry-route-storage"][0].enabled == true
    error_message = "Storage route should be enabled"
  }

  assert {
    condition     = [for r in azurerm_iothub.iothub.route : r if r.name == "export-telemetry-route-eventhub"][0].enabled == true
    error_message = "Event Hub route should be enabled"
  }

  assert {
    condition     = [for r in azurerm_iothub.iothub.route : r if r.name == "export-telemetry-route-storage"][0].condition == "true"
    error_message = "Storage route condition should be 'true' (route all messages)"
  }

  assert {
    condition     = [for r in azurerm_iothub.iothub.route : r if r.name == "export-telemetry-route-eventhub"][0].condition == "true"
    error_message = "Event Hub route condition should be 'true' (route all messages)"
  }
}

# Test that resource naming follows conventions
run "test_resource_naming_conventions" {
  command = plan

  assert {
    condition     = can(regex("^blmonitoring[0-9]{5}$", azurerm_storage_account.st.name))
    error_message = "Storage account name should follow pattern 'blmonitoring' followed by 5 digits"
  }

  assert {
    condition     = can(regex("^bl-eh-namespace-[0-9]{5}$", azurerm_eventhub_namespace.namespace.name))
    error_message = "Event Hub namespace name should follow pattern 'bl-eh-namespace-' followed by 5 digits"
  }

  assert {
    condition     = can(regex("^bl-telemetry-eh-[0-9]{5}$", azurerm_eventhub.eventhub.name))
    error_message = "Event Hub name should follow pattern 'bl-telemetry-eh-' followed by 5 digits"
  }

  assert {
    condition     = can(regex("^bl-iothub-[0-9]{5}$", azurerm_iothub.iothub.name))
    error_message = "IoT Hub name should follow pattern 'bl-iothub-' followed by 5 digits"
  }
}

# Test that the random suffix is within expected range
run "test_random_suffix_range" {
  command = plan

  assert {
    condition     = random_integer.suffix.min == 10000
    error_message = "Random suffix minimum should be 10000"
  }

  assert {
    condition     = random_integer.suffix.max == 99999
    error_message = "Random suffix maximum should be 99999"
  }
}
