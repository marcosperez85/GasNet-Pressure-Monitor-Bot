# Empaquetado del código de la función
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/${var.function_path}"
  output_path = "${path.module}/function.zip"
}

# Contenedor de almacenamiento para el paquete de despliegue
resource "azurerm_storage_container" "deployments" {
  name                  = "function-releases"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# Subir el ZIP del código al Storage Account
resource "azurerm_storage_blob" "function_code" {
  name                   = "function-${data.archive_file.function_zip.output_md5}.zip"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.deployments.name
  type                   = "Block"
  source                 = data.archive_file.function_zip.output_path
}

# SAS Token para descargar el paquete de despliegue
data "azurerm_storage_account_sas" "sas" {
  connection_string = azurerm_storage_account.storage.primary_connection_string
  https_only        = true
  start             = "2026-06-01T00:00:00Z"
  expiry            = "2030-06-01T00:00:00Z"

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

# Azure Function App en Linux
resource "azurerm_linux_function_app" "chatbot" {
  name                = "${var.prefix}-${var.environment}-fn-${random_id.unique.hex}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  service_plan_id            = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      python_version = "3.11"
    }
    cors {
      allowed_origins = ["*"]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "WEBSITE_RUN_FROM_PACKAGE"       = "https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.deployments.name}/${azurerm_storage_blob.function_code.name}${data.azurerm_storage_account_sas.sas.sas}"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app_insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.app_insights.connection_string
    
    # Configuración para invocar Azure AI Foundry
    "AZURE_AI_FOUNDRY_ENDPOINT"        = azurerm_cognitive_account.ai_services.endpoint
    "AZURE_AI_FOUNDRY_DEPLOYMENT_NAME" = var.model_name
    # Dejamos AZURE_AI_FOUNDRY_KEY vacío a propósito para forzar el uso de Managed Identity
    "AZURE_AI_FOUNDRY_KEY"             = ""
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"], # Permitir actualizaciones externas si es necesario
    ]
  }
}
