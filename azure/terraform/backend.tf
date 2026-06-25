# Alojamiento del Terraform State en Azure Blob Storage
# Descomenta y configura esta sección una vez tengas el Storage Account de administración listo.

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "terraform-state-rg"
#     storage_account_name = "tfstatemdp"
#     container_name       = "tfstate"
#     key                  = "chatbot/terraform.tfstate"
#   }
# }
