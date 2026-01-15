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

resource "azurerm_resource_group" "rg" {
  name     = "bl-monitoring-rg1"
  location = "East US"
}

# IoT Hub
resource "azurerm_iothub" "iothub" {
  name                = "bl-iothub-${random_integer.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "S1"
    capacity = 1
  }

  tags = {
    environment = "dev"
  }
}
