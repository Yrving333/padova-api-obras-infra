# Base de datos PaaS (sesion 7): servidor logico + base de datos Basic (5 DTU, 2 GB)
resource "azurerm_mssql_server" "sql_01" {
  name                          = var.sql_01_name
  resource_group_name           = azurerm_resource_group.rg_01.name
  location                      = local.sql_location
  version                       = "12.0"
  administrator_login           = var.db_admin_user
  administrator_login_password  = random_password.db_password.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true # la red privada no entra en el trabajo final (sesion 8)
  tags                          = var.tags
}

resource "azurerm_mssql_database" "sqldb_01" {
  name                 = var.sqldb_01_name
  server_id            = azurerm_mssql_server.sql_01.id
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  sku_name             = var.sqldb_01_sku
  max_size_gb          = var.sqldb_01_max_size_gb
  storage_account_type = "Local" # backups con redundancia local: suficiente para dev
  tags                 = var.tags
}

# Excepcion "Allow Azure services and resources to access this server" (start/end = 0.0.0.0).
# Evita depender de la IP de salida del Container App, que cambia (taller 5, sesion 7).
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_01.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Tu IP, para usar el Query editor del portal y cargar seed.sql. Vacio = sin regla.
resource "azurerm_mssql_firewall_rule" "allow_mi_ip" {
  count            = var.mi_ip_publica == "" ? 0 : 1
  name             = "Allow-MiIP"
  server_id        = azurerm_mssql_server.sql_01.id
  start_ip_address = var.mi_ip_publica
  end_ip_address   = var.mi_ip_publica
}
