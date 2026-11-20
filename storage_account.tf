resource "azurerm_storage_account" "st_01" {
  name                            = var.st_01_name
  resource_group_name             = azurerm_resource_group.rg_01.name
  location                        = azurerm_resource_group.rg_01.location
  account_tier                    = "Standard"
  account_replication_type        = var.st_01_replication
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false # el blob es privado; solo la identity lo lee
  tags                            = var.tags
}

resource "azurerm_storage_container" "imagenes" {
  name                  = var.st_01_container_name
  storage_account_id    = azurerm_storage_account.st_01.id
  container_access_type = "private"
}

# La imagen tambien es infraestructura como codigo: se sube en el apply
resource "azurerm_storage_blob" "fachada" {
  name                   = basename(var.imagen_local)
  storage_account_name   = azurerm_storage_account.st_01.name
  storage_container_name = azurerm_storage_container.imagenes.name
  type                   = "Block"
  source                 = "${path.module}/${var.imagen_local}"
  content_type           = "image/jpeg"
  content_md5            = filemd5("${path.module}/${var.imagen_local}") # si cambias la imagen, se vuelve a subir
}

# Minimo privilegio: solo lectura de blobs (en vez de compartir la access key)
resource "azurerm_role_assignment" "st_01_identity_reader" {
  scope                = azurerm_storage_account.st_01.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.identity_01.principal_id
}

# Espera a que los roles de la identity se propaguen (Key Vault, Storage y ACR).
# Sin esto la primera revision puede fallar al leer secretos o al descargar la imagen.
resource "time_sleep" "espera_rbac_identity" {
  depends_on = [
    azurerm_role_assignment.kv_01_identity_reader,
    azurerm_role_assignment.st_01_identity_reader,
    azurerm_role_assignment.acr_01_identity_pull,
  ]
  create_duration = "60s"
}
