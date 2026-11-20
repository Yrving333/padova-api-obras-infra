resource "azurerm_container_app" "aca_01" {
  name                         = var.aca_01_name
  container_app_environment_id = azurerm_container_app_environment.cae_01.id
  resource_group_name          = azurerm_resource_group.rg_01.name
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity_01.id]
  }

  # La imagen se descarga del ACR con la identity (rol AcrPull), sin usuario/clave
  registry {
    server   = azurerm_container_registry.acr_01.login_server
    identity = azurerm_user_assigned_identity.identity_01.id
  }

  # Secretos del Container App como referencia a Key Vault (versionless = siempre la ultima version)
  secret {
    name                = "db-user"
    key_vault_secret_id = azurerm_key_vault_secret.db_user.versionless_id
    identity            = azurerm_user_assigned_identity.identity_01.id
  }
  secret {
    name                = "db-password"
    key_vault_secret_id = azurerm_key_vault_secret.db_password.versionless_id
    identity            = azurerm_user_assigned_identity.identity_01.id
  }

  ingress {
    external_enabled = true
    target_port      = var.target_port # = EXPOSE del Dockerfile
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    # Escalado horizontal por peticiones concurrentes
    http_scale_rule {
      name                = "http-concurrencia"
      concurrent_requests = tostring(var.concurrencia_por_replica)
    }

    container {
      name   = var.imagen_repo
      image  = local.imagen
      cpu    = var.aca_01_cpu
      memory = var.aca_01_memory

      # Health check en Azure: si /health falla, se reinicia la replica (liveness)
      # o se le quita trafico (readiness)
      liveness_probe {
        transport               = "HTTP"
        port                    = var.target_port
        path                    = "/health"
        initial_delay           = 10
        interval_seconds        = 30
        failure_count_threshold = 3
      }
      readiness_probe {
        transport               = "HTTP"
        port                    = var.target_port
        path                    = "/health"
        interval_seconds        = 10
        failure_count_threshold = 3
      }

      env {
        name  = "NOMBRE"
        value = var.nombre_alumno
      }
      env {
        name  = "MI_VARIABLE"
        value = var.mi_variable
      }
      # /secreto: la app lee el Key Vault en tiempo de ejecucion con la identity
      env {
        name  = "KEY_VAULT_URL"
        value = azurerm_key_vault.kv_01.vault_uri
      }
      env {
        name  = "SECRET_NAME"
        value = azurerm_key_vault_secret.secreto_demo.name
      }
      env {
        name  = "AZURE_CLIENT_ID" # le dice a DefaultAzureCredential que identity usar
        value = azurerm_user_assigned_identity.identity_01.client_id
      }
      # /imagen
      env {
        name  = "STORAGE_ACCOUNT_URL"
        value = azurerm_storage_account.st_01.primary_blob_endpoint
      }
      env {
        name  = "BLOB_CONTAINER"
        value = azurerm_storage_container.imagenes.name
      }
      env {
        name  = "BLOB_NAME"
        value = azurerm_storage_blob.fachada.name
      }
      # /consulta: host y base como variables; usuario y password como secretos desde Key Vault
      env {
        name  = "DB_HOST"
        value = azurerm_mssql_server.sql_01.fully_qualified_domain_name
      }
      env {
        name  = "DB_NAME"
        value = azurerm_mssql_database.sqldb_01.name
      }
      env {
        name        = "DB_USER"
        secret_name = "db-user"
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
    }
  }

  # Los roles de la identity deben estar propagados antes de la primera revision
  depends_on = [time_sleep.espera_rbac_identity]

  lifecycle {
    # Las nuevas versiones de la imagen las despliega scripts/deploy.ps1 (az containerapp update)
    ignore_changes = [template[0].container[0].image]
  }
}

# Ver revisiones:
#   az containerapp revision list -n <ca> -g <rg> -o table
# Logs en vivo:
#   az containerapp logs show -n <ca> -g <rg> --follow
