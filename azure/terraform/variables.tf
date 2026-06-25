variable "resource_group_name" {
  type        = string
  default     = "rg-telemetria-poc-eus-01"
  description = "Nombre del Grupo de Recursos existente creado por el cliente"
}

variable "location" {
  type        = string
  default     = "eastus2" # East US 2 es una de las regiones primarias con soporte para Anthropic Claude en Azure
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

variable "claude_model_name" {
  type        = string
  default     = "claude-3-5-sonnet"
  description = "Nombre del modelo de Anthropic Claude en el catálogo de Azure AI"
}

variable "claude_model_version" {
  type        = string
  default     = "20241022" # Versión del modelo Claude 3.5 Sonnet
  description = "Versión del modelo de Anthropic Claude"
}
