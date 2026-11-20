resource "azurerm_key_vault" "kv_01" {
  name                       = var.kv_01_name
  resource_group_name        = azurerm_resource_group.rg_01.name
  location                   = azurerm_resource_group.rg_01.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true # permisos por roles (RBAC), no access policies
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # laboratorio: permite destroy y purga
  tags                       = var.tags
}

# Minimo privilegio: la identity del Container App solo LEE secretos
resource "azurerm_role_assignment" "kv_01_identity_reader" {
  scope                = azurerm_key_vault.kv_01.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.identity_01.principal_id
}

# Quien ejecuta Terraform (tu usuario) administra los secretos
resource "azurerm_role_assignment" "kv_01_terraform_officer" {
  scope                = azurerm_key_vault.kv_01.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Los roles tardan en propagarse; sin esta espera el primer apply suele dar 403
resource "time_sleep" "espera_rbac_kv" {
  depends_on      = [azurerm_role_assignment.kv_01_terraform_officer]
  create_duration = "60s"
}

# Secreto que muestra /secreto
resource "azurerm_key_vault_secret" "secreto_demo" {
  name         = var.secreto_nombre
  value        = var.secreto_valor
  key_vault_id = azurerm_key_vault.kv_01.id
  depends_on   = [time_sleep.espera_rbac_kv]
}

# Credenciales de la BD: el password lo genera Terraform y nadie lo escribe a mano
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "_-!"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "azurerm_key_vault_secret" "db_user" {
  name         = "db-user"
  value        = var.db_admin_user
  key_vault_id = azurerm_key_vault.kv_01.id
  depends_on   = [time_sleep.espera_rbac_kv]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.kv_01.id
  depends_on   = [time_sleep.espera_rbac_kv]
}

# Leer un secreto desde tu PC:
#   az keyvault secret show --vault-name <kv> -n db-password --query value -o tsv
