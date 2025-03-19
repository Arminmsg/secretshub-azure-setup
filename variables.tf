variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "The Azure tenant ID."
  type        = string
}

variable "app_client_display_name" {
  description = "The display name for the app that is created in your directory. The name must be unique"
  type        = string
}

variable "admin_password" {
  description = "The administrator password for the VM."
  type        = string
}

variable "resource_group" {
  description = "The name of the resource group in which to create the environment."
  default     = "secretsHubPOC"
  type        = string
}

variable "poc_name" {
  description = "Name of the POC"
  default     = "secretsHubPOC"
  type        = string
}

variable "admin_username" {
  description = "The administrator username for the VM."
  default     = "secretsHubPOCAdmin"
  type        = string
}

variable "vm_size" {
  description = "The size of the VM that will be created."
  default     = "Standard_DS1_v2"
  type        = string
}
