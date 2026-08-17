terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.57.0"
    }

  }
}
provider "azurerm" {
  features {}
  subscription_id = "f0679c99-0d63-422d-93ae-ec929728065c"
}
