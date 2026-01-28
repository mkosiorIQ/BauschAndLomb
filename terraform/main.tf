# Data source to get the current client's object ID for ownership assignment
data "azuread_client_config" "current" {}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

# Create Azure Resource Group for Monitoring Resources
resource "azurerm_resource_group" "rg" {
  #name     = "bl-monitoring-rg1"
  #location = "East US"
  name     = "bl-monitoring-rg2"
  location = "Central US"  # For SQL Free Tier compliance
}

# Create Azure Storage Account (ADLS Gen2) for Telemetry Data
resource "azurerm_storage_account" "st" {
  name                     = "blmonitoring${random_integer.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"
  identity {
    type = "SystemAssigned"
  }
}

# Create Azure Storage Container for Telemetry Data
resource "azurerm_storage_container" "telemetry" {
  name                  = "telemetry"
  storage_account_id    = azurerm_storage_account.st.id # Reference the ID
  container_access_type = "private"
}

# Create Azure Event Hub Namespace for Telemetry Ingestion
resource "azurerm_eventhub_namespace" "namespace" {
  name                = "bl-eh-namespace-${random_integer.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  capacity            = 1
}

# Create Azure Event Hub for Telemetry Ingestion
resource "azurerm_eventhub" "eventhub" {    
  name                = "bl-telemetry-eh-${random_integer.suffix.result}"
  namespace_id      = azurerm_eventhub_namespace.namespace.id
  partition_count     = 2
  message_retention   = 1
}

# Create Azure Event Hub Authorization Rule for Telemetry Ingestion
resource "azurerm_eventhub_authorization_rule" "auth_rule" {
  name                = "bl-eh-auth-rule-${random_integer.suffix.result}"
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  eventhub_name       = azurerm_eventhub.eventhub.name
  resource_group_name = azurerm_resource_group.rg.name

  listen = true
  send   = true
  manage = false
}

# Create Azure IoT Hub for Device Communication
resource "azurerm_iothub" "iothub" {
  name                = "bl-iothub-${random_integer.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "S1"
    capacity = 1
  }

  tags = {
    purpose = "testing-azure-iothub"
    environment = "dev"
  }

  endpoint {  
    name                       = "export-storage-endpoint"
    type                       = "AzureIotHub.StorageContainer"
    connection_string          = azurerm_storage_account.st.primary_connection_string
    container_name             = azurerm_storage_container.telemetry.name
    batch_frequency_in_seconds = 60
  } 

  endpoint {
    name                       = "export-eventhub-endpoint"
    type                       = "AzureIotHub.EventHub"
    connection_string          = azurerm_eventhub_authorization_rule.auth_rule.primary_connection_string
    batch_frequency_in_seconds = 60
  }

  route {
    name                   = "export-telemetry-route-storage"
    source                 = "DeviceMessages"
    endpoint_names         = ["export-storage-endpoint"]
    enabled                = true
    condition              = "true"
  }

  route {
    name                   = "export-telemetry-route-eventhub"
    source                 = "DeviceMessages"
    endpoint_names         = ["export-eventhub-endpoint"]
    enabled                = true
    condition              = "true"
  }
}

#resource "azurerm_iothub_device" "bl-device" {
#  name        = "bl-iot-device-${random_integer.suffix.result}"
#  #iothub_name = azurerm_iothub.iothub.name # Reference the IoT Hub name but not recognized in some TF versions
#  iothub_name = "bl-iothub-${random_integer.suffix.result}"
#  #resource_group_name = azurerm_resource_group.rg.name
#  status              = "enabled" # or disabled
# Authentication: Symmetric Key (default)
# X.509 certificate authentication can also be configured
#}
resource "null_resource" "create_device" {
  provisioner "local-exec" {
    command = "az iot hub device-identity create --device-id bl-device --hub-name ${azurerm_iothub.iothub.name}"
  }
}

#resource "random_password" "admin_password" {
#  count       = var.admin_password == null ? 1 : 0
#  length      = 20
#  special     = true
#  min_numeric = 1
#  min_upper   = 1
#  min_lower   = 1
#  min_special = 1
#}
#
#locals {
#  admin_password = try(random_password.admin_password[0].result, var.admin_password)
#}
#
resource "azurerm_mssql_server" "bl-server" {
  name                         = "bl-mssql-server-${random_integer.suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  #administrator_login          = var.admin_username
  #administrator_login_password = local.admin_password
  administrator_login          = "bladmin"
  administrator_login_password = var.sql_admin_password
  version                      = "12.0"
}

resource "azurerm_mssql_database" "bl-db" {
  #name        = var.sql_db_name
  name        = "bl-sqldb-${random_integer.suffix.result}"
  server_id   = azurerm_mssql_server.bl-server.id
  #sku_name    = "Basic" # S0 is the implied capacity for "Basic" tier
  #max_size_gb = 0.1     # Smallest possible size (0.1 GB/100MB)
  # Crucial settings for Free Tier
  #sku_name    = "Free"
  sku_name    = "S0" # Free tier uses S0 as the SKU name
  max_size_gb = 1  # 32 Max size for Free Tier
}
