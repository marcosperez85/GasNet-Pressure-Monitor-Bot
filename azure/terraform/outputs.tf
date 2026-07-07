output "api_url" {
  value       = "https://${azurerm_api_management.apim.gateway_url}/${azurerm_api_management_api.api.path}/chat"
  description = "URL pública de la API de APIM para interactuar con el chatbot"
}

output "api_key" {
  value       = azurerm_api_management_subscription.subscription.primary_key
  sensitive   = true
  description = "Clave de suscripción (x-api-key) para autenticarse en APIM"
}

output "ai_endpoint" {
  value = azurerm_cognitive_account.ai_services.endpoint
}