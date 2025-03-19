# secretshub-azure-setup
This repo sets up the infrastructure needed to connect CyberArk's Secrets Hub with an Azure Key Vault that is not publicly accessible. 
It sets up App Registrations, Service Principles, a VM for the Connector and the Key Vault.

In order for this to run successfully, a Resource Group needs to exists.

## Prerequisites

- Terraform 1.0 or newer
- Azure CLI
- Existing Resource Group inside Azure

### 1. Authenticate to Azure

#### Azure CLI

Ensure you are logged in to Azure CLI:
```bash
az login
```
### 2. Update the variables inside the variables.tf file

Provide your subscription id, tenant id etc.

### 3. Deploy the resources

```bash
terraform init
terraform apply
```
