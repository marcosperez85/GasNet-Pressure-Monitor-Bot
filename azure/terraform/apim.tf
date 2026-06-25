# Obtener las claves de la Azure Function para mapear la llamada segura
data "azurerm_function_app_host_keys" "keys" {
  name                = azurerm_linux_function_app.chatbot.name
  resource_group_name = data.azurerm_resource_group.rg.name
  
  depends_on = [
    azurerm_linux_function_app.chatbot
  ]
}

# Azure API Management
resource "azurerm_api_management" "apim" {
  name                = "${var.prefix}-${var.environment}-apim-${random_id.unique.hex}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  publisher_name      = "GasNet Operations"
  publisher_email     = "admin@gasnet.local"

  sku_name = var.apim_sku

  tags = {
    Environment = var.environment
    Project     = var.prefix
  }
}

# API definition
resource "azurerm_api_management_api" "api" {
  name                  = "ophub-chatbot-api"
  resource_group_name   = data.azurerm_resource_group.rg.name
  api_management_name   = azurerm_api_management.apim.name
  revision              = "1"
  display_name          = "GasNet Chatbot API"
  path                  = "chat-service" # URL pública será: https://<apim-host>/chat-service
  protocols             = ["https"]
  subscription_required = true

  # Mapear el uso de x-api-key para coincidir con AWS API Gateway
  subscription_key_parameter_names {
    header = "x-api-key"
    query  = "api_key"
  }
}

# Operación: POST /chat
resource "azurerm_api_management_api_operation" "post" {
  operation_id        = "post-chat"
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.rg.name
  display_name        = "Post Chat Message"
  method              = "POST"
  url_template        = "/chat" # Ruta pública será /chat-service/chat
}

# Producto de APIM
resource "azurerm_api_management_product" "product" {
  product_id            = "ophub-product"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = data.azurerm_resource_group.rg.name
  display_name          = "GasNet Operations Product"
  subscription_required = true
  approval_required     = false
  published             = true
}

# Asociar API al Producto
resource "azurerm_api_management_product_api" "product_api" {
  api_name            = azurerm_api_management_api.api.name
  product_id          = azurerm_api_management_product.product.product_id
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Suscripción de APIM (para generar las claves x-api-key)
resource "azurerm_api_management_subscription" "subscription" {
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.rg.name
  product_id          = azurerm_api_management_product.product.id
  display_name        = "GasNet Chatbot Subscription"
  state               = "active"
}

# Políticas de la API (CORS, Throttling, Backend Routing, Functions-Key)
resource "azurerm_api_management_api_policy" "api_policy" {
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.rg.name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <!-- CORS Policy: APIM intercepta preflight OPTIONS de forma nativa -->
        <cors allow-credentials="false">
            <allowed-origins>
                <origin>*</origin>
            </allowed-origins>
            <allowed-methods preflight-result-max-age="300">
                <method>POST</method>
                <method>OPTIONS</method>
            </allowed-methods>
            <allowed-headers>
                <allowed-header>Content-Type</allowed-header>
                <allowed-header>x-api-key</allowed-header>
            </allowed-headers>
        </cors>
        
        <!-- Rate Limiting (10 requests por 1 segundo, equivalente al de AWS) -->
        <rate-limit-by-key calls="10" renewal-period="1" counter-key="@(context.Subscription?.Id ?? context.Request.IpAddress)" />
        
        <!-- Enrutar hacia la Azure Function -->
        <set-backend-service base-url="https://${azurerm_linux_function_app.chatbot.default_hostname}/api" />
        
        <!-- Inyectar clave x-functions-key de forma interna y transparente -->
        <set-header name="x-functions-key" exists-action="override">
            <value>${data.azurerm_function_app_host_keys.keys.default_function_key}</value>
        </set-header>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
XML
}
