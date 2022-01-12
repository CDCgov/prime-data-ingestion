variable "cdc_vnet_name" {
  type = string
  description = "Name of CDC vnet"
}

variable "cdc_subnet_name" {
  type = string
  description = "Name of subnet within CDC vnet"
}

variable "environment" {
  type        = string
  description = "Target Environment"
}

variable "location" {
  type        = string
  description = "Network Location"
}

variable "resource_group" {
  type        = string
  description = "Resource Group Name"
}

variable "resource_prefix" {
  type        = string
  description = "Resource Prefix"
}