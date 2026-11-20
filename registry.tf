# Registry de la misma nube donde se despliega (criterio de la sesion 8). SKU minimo: Basic.
resource "azurerm_container_registry" "acr_01" {
  name                = var.acr_01_name
  resource_group_name = azurerm_resource_group.rg_01.name
  location            = azurerm_resource_group.rg_01.location
  sku                 = var.acr_01_sku
  admin_enabled       = false # sin usuario/clave admin: se entra con az acr login o con la identity
  tags                = var.tags
}

# Minimo privilegio: la identity del Container App solo DESCARGA imagenes (no puede hacer push)
resource "azurerm_role_assignment" "acr_01_identity_pull" {
  scope                = azurerm_container_registry.acr_01.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.identity_01.principal_id
}

# Primer apply (solo el registry, para poder publicar la primera imagen):
#   terraform apply -target="azurerm_container_registry.acr_01"
# Ver imagenes publicadas:
#   az acr repository show-tags --name <acr> --repository api-obras -o table
