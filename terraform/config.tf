terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.57.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "046696af-1d89-4ff1-9ab1-411f666c1c06"
}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

# Create Azure Resource Group for Monitoring Resources
resource "azurerm_resource_group" "rg" {
  name     = "bl-monitoring-rg1"
  location = "East US"
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

# Create Azure Evvent Hub Namespace for Telemetry Ingestion
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
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  resource_group_name = azurerm_resource_group.rg.name
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
