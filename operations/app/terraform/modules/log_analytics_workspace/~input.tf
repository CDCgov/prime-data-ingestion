variable "location" {
  type        = string
  description = "Network Location"
}

variable "resource_group" {
  type        = string
  description = "Resource Group Name"
}

variable "function_app_id" {
  type        = string
  description = "Function app resource id"
}

variable "function_infrastructure_app_id" {
  type        = string
  description = "Infrastructure function app resource id"
}
