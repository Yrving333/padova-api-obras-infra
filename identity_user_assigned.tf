# Identidad con la que el Container App accede a Key Vault y Storage (sin claves en el codigo)
resource "azurerm_user_assigned_identity" "identity_01" {
  name                = var.identity_01_name
  resource_group_name = azurerm_resource_group.rg_01.name
  location            = azurerm_resource_group.rg_01.location
  tags                = var.tags
}
