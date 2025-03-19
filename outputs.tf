output "azure_vault_uri" {
    value = azurerm_key_vault.secretshub.vault_uri
}

output "subscription_id" {
    value = data.azurerm_subscription.current.id
}

output "subscription_name" {
    value = data.azurerm_subscription.current.display_name
}

output "resource_group_name" {
    value = data.azurerm_resource_group.rg.name
}

output "directory_id" {
    value = data.azurerm_client_config.azurerm_data.tenant_id
}

output "app_client_id" {
    value = azuread_application_registration.secretshub_app.client_id
}

# 'terraform output app_client_secret'
output "app_client_secret" {
  value       = azuread_application_password.secretshub_service_principal_password.value
  sensitive   = true
}