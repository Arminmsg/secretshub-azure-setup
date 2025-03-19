variable "subscription_id" {
  description = "Azure Subscription ID"
}

variable "tenant_id" {
  description = "The Azure tenant ID."
}

variable "app_client_display_name" {
  description = "The display name for the app that is created in your directory. The name must be unique"
  type        = string
}

variable "admin_password" {
  description = "The administrator password for the VM."
}

variable "resource_group" {
  description = "The name of the resource group in which to create the environment."
  default     = "secretsHubPOC"
}

variable "poc_name" {
  description = "Name of the POC"
  default     = "secretsHubPOC"
}

variable "admin_username" {
  description = "The administrator username for the VM."
  default     = "secretsHubPOCAdmin"
}

variable "vm_size" {
  description = "The size of the VM that will be created."
  default     = "Standard_DS1_v2"
}