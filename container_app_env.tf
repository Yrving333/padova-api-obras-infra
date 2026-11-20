# Logs de la app (Application / System) para diagnosticar desde el portal
resource "azurerm_log_analytics_workspace" "log_01" {
  name                = var.log_01_name
  resource_group_name = azurerm_resource_group.rg_01.name
  location            = azurerm_resource_group.rg_01.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_01_retention_days
  tags                = var.tags
}

resource "azurerm_container_app_environment" "cae_01" {
  name                       = var.cae_01_name
  resource_group_name        = azurerm_resource_group.rg_01.name
  location                   = azurerm_resource_group.rg_01.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_01.id
  tags                       = var.tags

  # Azure asigna este perfil por defecto; se declara en el codigo para evitar drift en el plan
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}
