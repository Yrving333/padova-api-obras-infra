# padova-api-obras-infra — Infraestructura como código (Terraform + Azure)

Infraestructura del microservicio `api-obras` de Grupo Padova: Azure Container Apps con imagen en Azure Container Registry, secretos en Key Vault, imagen en Blob Storage y base de datos Azure SQL. Todo se crea y se destruye con Terraform; no hay pasos manuales en el portal salvo cargar los datos de prueba.

Repositorio de la aplicación: `padova-api-obras`.

## Arquitectura

```
                         Usuarios (HTTPS)
                                |
  +-----------------------------v------------------------------+
  | Container Apps Environment (cae-)  + Log Analytics (log-)  |
  |   +------------------------------------------------------+ |
  |   | Container App (ca-)  0..3 réplicas, escala por HTTP  | |
  |   | probes /health · identity user-assigned (id-)        | |
  |   +----+-------------+--------------+-------------+------+ |
  +--------|-------------|--------------|-------------|--------+
       AcrPull   Key Vault Secrets User  Blob Data Reader  usuario/clave
           |             |              |             (desde Key Vault)
    +------v-----+ +-----v------+ +-----v--------+ +--v-----------------+
    | ACR Basic  | | Key Vault  | | Storage      | | Azure SQL Basic    |
    | api-obras: | | secreto-   | | contenedor   | | sql- / sqldb-      |
    | rama-commit| | demo,      | | "imagenes"   | | tabla proyectos    |
    +------------+ | db-user,   | | fachada.jpg  | | firewall: servicios|
                   | db-password| +--------------+ | de Azure           |
                   +------------+                  +--------------------+
                         Resource Group (rg-)
```

## Recursos (un archivo por tipo)

| Archivo | Recursos |
|---|---|
| `provider.tf` | azurerm `=4.51.0`, random, time |
| `locals.tf` | región de SQL e imagen completa (`<acr>/<repo>:<tag>`) |
| `resource_group.tf` | `rg_01` |
| `identity_user_assigned.tf` | `identity_01` |
| `registry.tf` | `acr_01` (Basic, sin admin) y rol `AcrPull` para la identity |
| `keyvault.tf` | `kv_01` (RBAC), roles, `secreto-demo`, `db-user`, `db-password` (generado con `random_password`) |
| `storage_account.tf` | `st_01`, contenedor `imagenes`, blob `fachada.jpg`, rol de lectura, espera de propagación de roles |
| `sql_database.tf` | `sql_01` (servidor), `sqldb_01` (Basic, 2 GB), firewall "servicios de Azure" y, opcionalmente, tu IP |
| `container_app_env.tf` | `log_01`, `cae_01` |
| `container_app.tf` | `aca_01`: registry con identity, secretos desde Key Vault, variables de entorno, probes, escalado 0..3 |
| `output.tf` | URL de la app y de cada endpoint, ACR, Key Vault, SQL |
| `variables.tf` / `terraform.tfvars.example` | todo variabilizado: nombres, SKUs, CPU/memoria, réplicas, región |

Nomenclatura: `<tipo>-<proyecto>-<ambiente>-<región>-<nnn>`. Key Vault, Storage y ACR van sin guiones porque sus nombres son globales.

## Seguridad y buenas prácticas

- **Mínimo privilegio por identidad:** la app solo lee secretos (`Key Vault Secrets User`), solo lee blobs (`Storage Blob Data Reader`) y solo descarga imágenes (`AcrPull`). Tu usuario es el único que administra secretos.
- **Sin credenciales en código ni en Git:**
  - La contraseña de SQL la genera Terraform y vive solo en Key Vault.
  - El Container App recibe usuario y contraseña como secretos referenciados a Key Vault.
  - El ACR no tiene usuario admin.
- **`.gitignore`:** excluye `.terraform/`, `*.tfstate*`, `*.tfvars` y los planes. Se versiona `terraform.tfvars.example`.
- **Ciclos separados:** `lifecycle.ignore_changes` sobre la imagen. Terraform administra la infraestructura y `scripts/deploy.ps1` (repo de la app) despliega las versiones.
- **Región:** sale de variables, nunca escrita a mano en un recurso.
- **SKUs mínimos:** ACR Basic, SQL Basic y escala a cero.

## Variables principales

| Variable | Descripción | Ejemplo |
|---|---|---|
| `subscription_id` | Suscripción de Azure | `az account show --query id -o tsv` |
| `location` | Región | `eastus2` |
| `imagen_tag` | Tag publicado en el ACR | `main-a1b2c3d` |
| `min_replicas` / `max_replicas` | Escalado | `0` / `3` |
| `kv_01_name`, `st_01_name`, `acr_01_name`, `sql_01_name` | Nombres globales | ver `.example` |
| `sql_location` | Región de SQL si la suscripción lo restringe | `""` o `westus2` |
| `mi_ip_publica` | Tu IP para usar el Query editor | `190.x.x.x` |

## Uso

```powershell
az login
copy terraform.tfvars.example terraform.tfvars        # completar valores
terraform init
terraform fmt
terraform validate

# 1) Solo el registry, para publicar la primera imagen
terraform apply -target="azurerm_container_registry.acr_01"
#    (en el repo de la app) .\scripts\deploy.ps1 -AcrName <acr> -SoloPublicar  -> copiar imagen_tag

# 2) Todo lo demás
terraform plan -out infra_dev.tfplan                  # debe decir: 22 to add (21 sin mi_ip_publica)
terraform apply infra_dev.tfplan
terraform output

# 3) Al terminar
terraform destroy
```

## Costo estimado (un mes, 2 usuarios, East US 2)

| Recurso | USD/mes aprox. |
|---|---|
| Azure SQL Basic | 4.90 |
| ACR Basic (0.167/día) | 5.00 |
| Container App con escala a cero | ~0 (cuota gratis mensual) |
| Key Vault, Storage, Log Analytics | < 0.50 |
| **Total** | **~10** |

## Evidencias

Ver la carpeta `evidencias/`: `terraform apply`, recursos en el portal (Resource visualizer), IAM de la identity, pruebas de endpoints y `terraform destroy`.
