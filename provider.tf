terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.51.0" # version fijada, como en clase
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Al hacer destroy el Key Vault se purga para poder reutilizar el nombre (nombre global)
      purge_soft_delete_on_destroy = true
    }
  }
  subscription_id = var.subscription_id
}
