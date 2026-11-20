data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg_01" {
  name     = var.rg_01_name
  location = var.location
  tags     = var.tags
}
