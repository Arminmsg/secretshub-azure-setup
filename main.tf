terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.23.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

data "azurerm_client_config" "azurerm_data" {}

data "azurerm_subscription" "current" {}

# Create Azure AD Application
resource "azuread_application_registration" "secretshub_app" {
  display_name = var.app_client_display_name
}

# Create Service Principal for the application
resource "azuread_service_principal" "secretshub_service_principal" {
  client_id    = azuread_application_registration.secretshub_app.client_id
  use_existing = true
}

# Create credentials for the service principal, Valid for one year
resource "azuread_application_password" "secretshub_service_principal_password" {
  application_id = azuread_application_registration.secretshub_app.id
  end_date       = timeadd(timestamp(), "8760h")
}

# Create RBAC Role Definition (if Key Vault uses RBAC)
resource "azurerm_role_definition" "secretshub_keyvault_role" {
  count = azurerm_key_vault.secretshub.enable_rbac_authorization ? 1 : 0

  name        = "Secrets-Hub-${azurerm_key_vault.secretshub.name}-${var.app_client_display_name}-Role"
  scope       = azurerm_key_vault.secretshub.id
  description = "Provide read-write access to secrets in Key Vault"
  permissions {
    actions = [
      "Microsoft.KeyVault/vaults/secrets/write",
      "Microsoft.KeyVault/vaults/secrets/read",
    ]
    data_actions = [
      "Microsoft.KeyVault/vaults/secrets/delete",
      "Microsoft.KeyVault/vaults/secrets/purge/action",
      "Microsoft.KeyVault/vaults/secrets/update/action",
      "Microsoft.KeyVault/vaults/secrets/getSecret/action",
      "Microsoft.KeyVault/vaults/secrets/setSecret/action",
      "Microsoft.KeyVault/vaults/secrets/readMetadata/action"
    ]
  }
  assignable_scopes = [azurerm_key_vault.secretshub.id]
}

# Assign role to the service principal
resource "azurerm_role_assignment" "secretshub_keyvault_role_assignment" {
  count = azurerm_key_vault.secretshub.enable_rbac_authorization ? 1 : 0

  principal_id         = azuread_service_principal.secretshub_service_principal.object_id
  role_definition_name = azurerm_role_definition.secretshub_keyvault_role[0].name
  scope                = azurerm_key_vault.secretshub.id
  depends_on           = [azurerm_role_definition.secretshub_keyvault_role[0]]
}

# If Key Vault uses Vault Access Policy
resource "azurerm_key_vault_access_policy" "access_policy" {
  count = azurerm_key_vault.secretshub.enable_rbac_authorization ? 0 : 1

  key_vault_id = azurerm_key_vault.secretshub.id
  tenant_id    = data.azurerm_client_config.azurerm_data.tenant_id
  object_id    = azuread_service_principal.secretshub_service_principal.object_id

  secret_permissions = ["Get", "Set", "List", "Delete", "Purge"]
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.poc_name}VNet"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
  service_endpoints    = ["Microsoft.KeyVault"]

}

resource "azurerm_network_security_group" "allow_RDP_public_access" {
  name                = "allow_RDP_public_access"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow_RDP_public_access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "public_RDP_access" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.allow_RDP_public_access.id
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.poc_name}VMNic"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"  # or "Static" if you prefer
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "azurerm_windows_virtual_machine" "connector" {
  name                = "${var.poc_name}VM"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = var.vm_size

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_username = var.admin_username
  admin_password = var.admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_key_vault" "secretshub" {
  name                = "${var.poc_name}KV"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku_name            = "standard"
  enable_rbac_authorization = true

  tenant_id = var.tenant_id

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = [
      azurerm_subnet.default.id,
    ]
  }
}