variable "resource_group_name" {
  type        = string
  default     = "rg-telemetria-poc-eus-01"
  description = "Nombre del Grupo de Recursos existente creado por el cliente"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Región de Azure donde se desplegarán los recursos"
}

variable "prefix" {
  type        = string
  default     = "ophub"
  description = "Prefijo para los nombres de los recursos"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Entorno del despliegue (dev, prod, etc.)"
}

variable "function_path" {
  type        = string
  default     = "../function"
  description = "Ruta relativa al directorio de código de la Azure Function"
}

variable "apim_sku" {
  type        = string
  default     = "Consumption_0" # Consumption es idóneo para desarrollo rápido y bajo coste. Para producción se sugiere Developer_1 o Basic_1.
  description = "SKU de Azure API Management"
}

variable "model_name" {
  type        = string
  default     = "gpt-5.1"
  description = "gpt-5.1"
}

variable "model_version" {
  type        = string
  default     = "20251113" # usar la versión exacta que muestra el deployment creado en Foundry
}
