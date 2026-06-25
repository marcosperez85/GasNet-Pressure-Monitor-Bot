resource "random_id" "unique" {
  byte_length = 4
}

# Grupo de Recursos existente creado por el cliente
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Storage Account para la Azure Function
resource "azurerm_storage_account" "storage" {
  name                     = "${var.prefix}${var.environment}store${random_id.unique.hex}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Plan de Servicio App (Consumption/Serverless)
resource "azurerm_service_plan" "plan" {
  name                = "${var.prefix}-${var.environment}-plan"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Plan Consumption para Functions
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-${var.environment}-law"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Application Insights para logs de la Azure Function
resource "azurerm_application_insights" "app_insights" {
  name                = "${var.prefix}-${var.environment}-insights"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}
