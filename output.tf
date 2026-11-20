output "rg_name" {
  value = azurerm_resource_group.rg_01.name
}

# terraform output -raw app_url
output "app_url" {
  value = "https://${azurerm_container_app.aca_01.ingress[0].fqdn}"
}

output "endpoints" {
  value = [for p in ["hello", "variable", "secreto", "imagen", "consulta"] :
  "https://${azurerm_container_app.aca_01.ingress[0].fqdn}/${p}"]
}

output "imagen_desplegada_inicial" {
  value = local.imagen
}

# terraform output -raw acr_login_server
output "acr_login_server" {
  value = azurerm_container_registry.acr_01.login_server
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv_01.vault_uri
}

output "storage_blob_url" {
  value = azurerm_storage_blob.fachada.url
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql_01.fully_qualified_domain_name
}

output "sql_database_name" {
  value = azurerm_mssql_database.sqldb_01.name
}
