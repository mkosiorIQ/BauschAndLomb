terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.57.0"
    }
  }
}

# Configure the Microsoft Azure Provider (optional, only if managing other Azure resources)
provider "azurerm" {
  features {}
}

# Configure the Microsoft Entra ID Provider
# The provider configuration will use authentication methods 
# configured in your environment (e.g., Azure CLI login, Managed Identity, 
# or Service Principal environment variables)
provider "azuread" {}
