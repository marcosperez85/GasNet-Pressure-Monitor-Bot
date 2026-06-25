# Cuenta de Servicios de IA de Azure (Azure AI Services / Azure AI Foundry Hub)
resource "azurerm_cognitive_account" "ai_services" {
  name                = "${var.prefix}-${var.environment}-ai-${random_id.unique.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "AIServices"
  sku_name            = "S0"

  custom_subdomain_name = "${var.prefix}-${var.environment}-ai-${random_id.unique.hex}"

  # Habilitamos la autenticación local por si deciden usar claves de API en lugar de Managed Identity
  local_auth_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
    Project     = var.prefix
  }
}

# Despliegue del Modelo Anthropic Claude en Azure AI Services
# Nota: La disponibilidad de modelos de partner como Anthropic Claude varía por región (ej. East US 2, Sweden Central).
resource "azurerm_cognitive_deployment" "claude" {
  name                 = var.claude_model_name
  cognitive_account_id = azurerm_cognitive_account.ai_services.id

  model {
    format  = "Anthropic"
    name    = var.claude_model_name
    version = var.claude_model_version
  }

  sku {
    name     = "GlobalStandard" # Sku estándar para despliegues Serverless/MaaS (Model as a Service)
    capacity = 1
  }

  lifecycle {
    ignore_changes = [
      model[0].version # Ignorar cambios menores de versión del modelo de Azure
    ]
  }
}
