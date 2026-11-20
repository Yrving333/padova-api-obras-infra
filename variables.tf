// GENERAL ------------------------------------------------------------------
variable "subscription_id" {
  description = "ID de la suscripcion (az account show --query id -o tsv)"
  type        = string
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "tags" {
  type = map(string)
}

// NOMBRES: <tipo>-<proyecto>-<ambiente>-<region>-<nnn> --------------------
variable "rg_01_name" { type = string }
variable "log_01_name" { type = string }
variable "cae_01_name" { type = string }
variable "aca_01_name" { type = string }
variable "identity_01_name" { type = string }

variable "kv_01_name" {
  description = "Nombre global: sin guiones, 3-24 caracteres"
  type        = string
}

variable "st_01_name" {
  description = "Nombre global: minusculas y numeros, 3-24 caracteres"
  type        = string
}

variable "acr_01_name" {
  description = "Nombre global: solo letras y numeros, 5-50 caracteres"
  type        = string
}

variable "sql_01_name" {
  description = "Nombre global del servidor SQL"
  type        = string
}

variable "sqldb_01_name" { type = string }

// SKUS Y TAMANOS (minimo necesario) ----------------------------------------
variable "acr_01_sku" {
  type    = string
  default = "Basic"
}

variable "sqldb_01_sku" {
  type    = string
  default = "Basic"
}

variable "sqldb_01_max_size_gb" {
  type    = number
  default = 2
}

variable "sql_location" {
  description = "Region del servidor SQL. Vacio = la del resource group. Cambiala si la suscripcion no permite SQL en esa region."
  type        = string
  default     = ""
}

variable "st_01_replication" {
  type    = string
  default = "LRS"
}

variable "st_01_container_name" {
  type    = string
  default = "imagenes"
}

variable "log_01_retention_days" {
  type    = number
  default = 30
}

variable "aca_01_cpu" {
  type    = number
  default = 0.5
}

variable "aca_01_memory" {
  type    = string
  default = "1Gi"
}

// ESCALADO -----------------------------------------------------------------
variable "min_replicas" {
  description = "0 = escala a cero sin trafico (mas barato, primera visita tarda 10-20 s)"
  type        = number
  default     = 0
}

variable "max_replicas" {
  type    = number
  default = 3
}

variable "concurrencia_por_replica" {
  description = "Peticiones simultaneas por replica antes de crear otra"
  type        = number
  default     = 50
}

// APLICACION ---------------------------------------------------------------
variable "imagen_repo" {
  type    = string
  default = "api-obras"
}

variable "imagen_tag" {
  description = "Tag publicado en el ACR por deploy.ps1 -SoloPublicar (rama-commit)"
  type        = string
}

variable "target_port" {
  description = "Debe coincidir con EXPOSE del Dockerfile"
  type        = number
  default     = 8080
}

variable "nombre_alumno" { type = string }
variable "mi_variable" { type = string }

variable "secreto_nombre" {
  type    = string
  default = "secreto-demo"
}

variable "secreto_valor" {
  description = "Valor del secreto que muestra /secreto"
  type        = string
  sensitive   = true
}

variable "imagen_local" {
  description = "Archivo que se sube al blob y muestra /imagen"
  type        = string
  default     = "assets/fachada.jpg"
}

// BASE DE DATOS ------------------------------------------------------------
variable "db_admin_user" {
  description = "Login administrador de Azure SQL (no puede ser admin, sa, root...)"
  type        = string
  default     = "padovaadmin"
}

variable "mi_ip_publica" {
  description = "Tu IP publica (https://ifconfig.me) para el Query editor. Vacio = sin regla."
  type        = string
  default     = ""
}
