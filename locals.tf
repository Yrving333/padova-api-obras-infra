locals {
  # La region se toma de variables, nunca escrita a mano en un recurso suelto
  sql_location = var.sql_location == "" ? azurerm_resource_group.rg_01.location : var.sql_location

  # Imagen que se despliega: <acr>.azurecr.io/<repo>:<rama-commit>
  imagen = "${azurerm_container_registry.acr_01.login_server}/${var.imagen_repo}:${var.imagen_tag}"
}
