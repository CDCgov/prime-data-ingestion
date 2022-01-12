/*
 * Creates/associates a vnet, subnet(s), and security group(s). Subnets are:
 * 
 * - Private: Exists in the CDC-managed VNet as name "Default"; all services exist here
 * - Endpoint: Will exist in the application VNet, contains endpoints to the services in the Private subnet
 */


# vnet with endpoints, local DNS server, and VPN for devs to connect
resource "azurerm_virtual_network" "dev" {
  name                = "${var.resource_prefix}-dev-vnet"
  location            = var.location
  resource_group_name = var.resource_group
  address_space       = ["10.0.0.0/16"]

  tags = {
      environment = var.environment
  }
}

/* Private subnet */
resource "azurerm_subnet" "dev_private_subnet" {
  name                 = var.cdc_subnet_name  # keep this the same as the CDC vnet for consistency
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry",
  ]

  delegation {
    name = "server_farms"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }

  lifecycle {
    ignore_changes = [
      delegation[0].name, # FW team renamed this, and if we change it, a new resource will be created
    ]
  }
}

/* Private network security group */
resource "azurerm_network_security_group" "vnet_nsg_private" {
  name                = "${var.resource_prefix}-private-nsg"
  location            = var.location
  resource_group_name = var.resource_group
}

/* ...+ association to CDC "Default" subnet */
resource "azurerm_subnet_network_security_group_association" "cdc_private_to_nsg_private" {
  subnet_id                 = data.azurerm_subnet.cdc_subnet.id
  network_security_group_id = azurerm_network_security_group.vnet_nsg_private.id
}

/* ...+ association to dev private subnet */
resource "azurerm_subnet_network_security_group_association" "dev_private_to_nsg_private" {
  subnet_id                 = azurerm_subnet.dev_private_subnet.id
  network_security_group_id = azurerm_network_security_group.vnet_nsg_private.id
}

# ## VPN Access
# 
# resource "azurerm_virtual_network_gateway" "vpn_gateway" {
#   name                = "${var.resource_prefix}-vpn"
#   location            = var.location
#   resource_group_name = var.resource_group
#   sku                 = "VpnGw1"
#   type                = "Vpn"
# 
#   ip_configuration {
#     public_ip_address_id = azurerm_public_ip.vpn_ip.id
#     subnet_id            = azurerm_subnet.gateway.id
#   }
# 
#   vpn_client_configuration {
#     # Clients connected to the VPN will receive an IP address in this space
#     address_space        = ["192.168.10.0/24"]
#     vpn_client_protocols = ["OpenVPN"]
# 
#     root_certificate {
#       name = "PRIME-Ingestion-VPN-Root"
# 
#       # This is a public key. Private keys are stored elsewhere,
#       # so there is no security risk to storing unencrypted in a public repo.
#       public_cert_data = <<EOF
# MIIC5jCCAc6gAwIBAgIII4Y+H046XeswDQYJKoZIhvcNAQELBQAwETEPMA0GA1UE
# AxMGVlBOIENBMB4XDTIxMDMwOTE2MDY0M1oXDTI0MDMwODE2MDY0M1owETEPMA0G
# A1UEAxMGVlBOIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAq8y1
# FIQ2UsiUDZL3uOmcpS9H0Kgo3/IkcUvm61+EhICqCp+4ZcYkXyKvZiFLVcPdgACT
# g6Lun/DewvHYRZsHcIS/7P+58BbbJLobBviGZrQOME5DwoaTgAZLY/21RoEif/+3
# kKFNy3VVClb27VTD+ak656UXeqIxCvOIHhD2OyaMUUewYFwPBymSG9VYtkXtQSi0
# 838ewbYVt5lWwgChA+1z+NPt9JLzB0rW1e+3H5vpJA8O5JhkpwmYN1/IaBXtZ63Z
# l8fPXOhZNQMSub+3QonREYz931OZ0LNoE/gCMsy1uZ7Mk8M3TpFgF9yq2sYFmjQY
# jNAl2QF1PubAc0ULqQIDAQABo0IwQDAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB
# /wQEAwIBBjAdBgNVHQ4EFgQUasPU+9+fgel7L6tECx5tPJDZ+iEwDQYJKoZIhvcN
# AQELBQADggEBAARHM2oTIE8aFLpulufusQGekEkGvmuXA4yxs7gn2SNv2eg8deMi
# +DRErc8yAhZn+0HwjW6UhxzHBJ0ovx2EiWCasiCez699nx+f18EmejAgSkXb8cOn
# 4OFTMls9BaNSbBFI6yCXNmpIqstSb/Z6RHHSgARjQqvUZElpkzYfuC6L0El70q+b
# ArS+Qwkq8JJ93hPXXxUIcgaSC6KHNik0ik44nS1czYmwIyvdTeo/In2lZiqTL299
# GhdGksT8b4Wz3chHvgNJoFZmxm3YpiDKyWwNMLe/T7RLu8gY66b5GvB3s0YHjq9G
# axJToXMg3T9oImHz8yIk6X7j1n+UMHE9528=
# EOF
#     }
#   }
# 
#   tags = {
#     environment = var.environment
#   }
# }
# 
# # VPN gateways will receive an IP address in this subnet
# resource "azurerm_subnet" "gateway" {
#   name                 = "GatewaySubnet" # This subnet must be named this. Azure expects this name for VPN gateways.
#   resource_group_name  = var.resource_group
#   virtual_network_name = azurerm_virtual_network.dev.name
#   address_prefixes     = ["10.0.4.0/24"]
# }
# 
# # A public IP is needed so we can access the VPN over the internet
# resource "azurerm_public_ip" "vpn_ip" {
#   name                = "${var.resource_prefix}-vpn-ip"
#   location            = var.location
#   resource_group_name = var.resource_group
#   allocation_method   = "Dynamic"
# }

/* Endpoint subnet */
# resource "azurerm_subnet" "endpoint_subnet" {
#   count                = length(var.vnets)
#   name                 = "endpoint"
#   resource_group_name  = var.resource_group
#   virtual_network_name = var.vnets[count.index].name
# 
#   address_prefixes = [
#     module.subnet_addresses[count.index].network_cidr_blocks["endpoint"],
#   ]
# 
#   service_endpoints = [
#     "Microsoft.Storage",
#     "Microsoft.KeyVault",
#   ]
# 
#   enforce_private_link_endpoint_network_policies = true
# }
# 
# resource "azurerm_subnet_network_security_group_association" "endpoint_to_nsg_private" {
#   count = length(azurerm_subnet.endpoint_subnet)
# 
#   subnet_id                 = azurerm_subnet.endpoint_subnet[count.index].id
#   network_security_group_id = azurerm_network_security_group.vnet_nsg_private[count.index].id
# }

# /* Public subnet */
# resource "azurerm_subnet" "public_subnet" {
#   count                = length(var.vnets)
#   name                 = "public"
#   resource_group_name  = var.resource_group
#   virtual_network_name = var.vnets[count.index].name
# 
#   address_prefixes = [
#     module.subnet_addresses[count.index].network_cidr_blocks["public"],
#   ]
# 
#   service_endpoints = [
#     "Microsoft.ContainerRegistry",
#     "Microsoft.Storage",
#     "Microsoft.KeyVault",
#   ]
# 
#   delegation {
#     name = "server_farms"
#     service_delegation {
#       name = "Microsoft.Web/serverFarms"
#       actions = [
#         "Microsoft.Network/virtualNetworks/subnets/action",
#       ]
#     }
#   }
# 
#   lifecycle {
#     ignore_changes = [
#       delegation[0].name, # FW team renamed this, and if we change it, a new resource will be created
#     ]
#   }
# }
# 
# resource "azurerm_subnet_network_security_group_association" "public_to_nsg_public" {
#   count                     = length(azurerm_subnet.public_subnet)
#   subnet_id                 = azurerm_subnet.public_subnet[count.index].id
#   network_security_group_id = azurerm_network_security_group.vnet_nsg_public[count.index].id
# }
# 
# /* Container subnet */
# resource "azurerm_subnet" "container_subnet" {
#   count                = length(var.vnets)
#   name                 = "container"
#   resource_group_name  = var.resource_group
#   virtual_network_name = var.vnets[count.index].name
#   address_prefixes = [
#     module.subnet_addresses[count.index].network_cidr_blocks["container"],
#   ]
#   service_endpoints = [
#     "Microsoft.Storage",
#     "Microsoft.KeyVault",
#   ]
#   delegation {
#     name = "container_groups"
#     service_delegation {
#       name = "Microsoft.ContainerInstance/containerGroups"
#       actions = [
#         "Microsoft.Network/virtualNetworks/subnets/action",
#       ]
#     }
#   }
# 
#   lifecycle {
#     ignore_changes = [
#       delegation[0].name, # FW team renamed this, and if we change it, a new resource will be created
#     ]
#   }
# }
# 
# resource "azurerm_subnet_network_security_group_association" "container_to_nsg_public" {
#   count                     = length(azurerm_subnet.container_subnet)
#   subnet_id                 = azurerm_subnet.container_subnet[count.index].id
#   network_security_group_id = azurerm_network_security_group.vnet_nsg_public[count.index].id
# }
# 