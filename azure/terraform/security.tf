# Asignación de Roles RBAC (Equivalente a las Políticas IAM en AWS)
# Permite que la Azure Function invoque modelos en Azure AI Services usando su Identidad Administrada

resource "azurerm_role_assignment" "fn_to_ai" {
  scope                = azurerm_cognitive_account.ai_services.id
  role_definition_name = "Cognitive Services User" # Rol integrado para consumir endpoints de IA/Cognitivos
  principal_id         = azurerm_linux_function_app.chatbot.identity[0].principal_id
}
