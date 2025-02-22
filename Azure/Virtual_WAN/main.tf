# Main

# Azure Provider
provider "azurerm" {
  features {}
}

# Create a random id
resource "random_id" "buildSuffix" {
  byte_length = 2
}

############################ Locals ############################

locals {
  vnets = {
    nva = {
      location       = var.location
      addressSpace   = ["10.255.0.0/16"]
      subnetPrefixes = ["10.255.1.0/24", "10.255.10.0/24", "10.255.20.0/24"]
      subnetNames    = ["mgmt", "external", "internal"]
    }
    spoke1 = {
      location       = var.location
      addressSpace   = ["10.1.0.0/16"]
      subnetPrefixes = ["10.1.1.0/24", "10.1.10.0/24", "10.1.20.0/24"]
      subnetNames    = ["mgmt", "external", "internal"]
    }
    spoke2 = {
      location       = var.location
      addressSpace   = ["10.2.0.0/16"]
      subnetPrefixes = ["10.2.1.0/24", "10.2.10.0/24", "10.2.20.0/24"]
      subnetNames    = ["mgmt", "external", "internal"]
    }
  }

  spokeNvaPeerings = {
    spoke1 = {
    }
    spoke2 = {
    }
  }
}

############################ Resource Groups ############################

# Create Resource Groups
resource "azurerm_resource_group" "rg" {
  for_each = local.vnets
  name     = format("%s-rg-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)
  location = each.value["location"]

  tags = {
    Name      = format("%s-rg-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

############################ Route Tables ############################

# Create Route Tables
resource "azurerm_route_table" "rt" {
  for_each                      = local.vnets
  name                          = format("%s-rt-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)
  location                      = azurerm_resource_group.rg[each.key].location
  resource_group_name           = azurerm_resource_group.rg[each.key].name
  disable_bgp_route_propagation = false

  tags = {
    Name      = format("%s-rt-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

############################ Network Security Groups ############################

# Create Mgmt NSG
module "nsg-mgmt" {
  for_each              = local.vnets
  source                = "Azure/network-security-group/azurerm"
  resource_group_name   = azurerm_resource_group.rg[each.key].name
  location              = azurerm_resource_group.rg[each.key].location
  security_group_name   = format("%s-nsg-mgmt-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)
  source_address_prefix = [var.adminSrcAddr]

  custom_rules = [
    {
      name                   = "allow_http"
      priority               = "100"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "80"
    },
    {
      name                   = "allow_https"
      priority               = "110"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "443"
    },
    {
      name                   = "allow_ssh"
      priority               = "120"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "22"
    }
  ]

  tags = {
    Name      = format("%s-nsg-mgmt-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

# Create External NSG
module "nsg-external" {
  for_each              = local.vnets
  source                = "Azure/network-security-group/azurerm"
  resource_group_name   = azurerm_resource_group.rg[each.key].name
  location              = azurerm_resource_group.rg[each.key].location
  security_group_name   = format("%s-nsg-external-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)
  source_address_prefix = ["*"]

  custom_rules = [
    {
      name                   = "allow_http"
      priority               = "100"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "80"
    },
    {
      name                   = "allow_https"
      priority               = "110"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "443"
    }
  ]

  tags = {
    Name      = format("%s-nsg-external-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

# Create Internal NSG
module "nsg-internal" {
  for_each            = local.vnets
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = azurerm_resource_group.rg[each.key].location
  security_group_name = format("%s-nsg-internal-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)

  tags = {
    Name      = format("%s-nsg-internal-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

############################ VNets ############################

# Create VNets
module "network" {
  for_each            = local.vnets
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.rg[each.key].name
  vnet_name           = format("%s-vnet-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)
  address_space       = each.value["addressSpace"]
  subnet_prefixes     = each.value["subnetPrefixes"]
  subnet_names        = each.value["subnetNames"]

  nsg_ids = {
    external = module.nsg-external[each.key].network_security_group_id
    mgmt     = module.nsg-mgmt[each.key].network_security_group_id
  }

  route_tables_ids = {
    external = azurerm_route_table.rt[each.key].id
    internal = azurerm_route_table.rt[each.key].id
  }

  tags = {
    Name      = format("%s-vnet-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

# Retrieve NVA Subnet Data
data "azurerm_subnet" "mgmtSubnetNva" {
  name                 = "mgmt"
  virtual_network_name = module.network["nva"].vnet_name
  resource_group_name  = azurerm_resource_group.rg["nva"].name
  depends_on           = [module.network["nva"].vnet_subnets]
}

data "azurerm_subnet" "externalSubnetNva" {
  name                 = "external"
  virtual_network_name = module.network["nva"].vnet_name
  resource_group_name  = azurerm_resource_group.rg["nva"].name
  depends_on           = [module.network["nva"].vnet_subnets]
}

data "azurerm_subnet" "internalSubnetNva" {
  name                 = "internal"
  virtual_network_name = module.network["nva"].vnet_name
  resource_group_name  = azurerm_resource_group.rg["nva"].name
  depends_on           = [module.network["nva"].vnet_subnets]
}

############################ VNet Peering ############################

# Create NVA to spoke peerings
resource "azurerm_virtual_network_peering" "nvaToSpoke" {
  for_each                  = local.spokeNvaPeerings
  name                      = format("nva-to-%s", each.key)
  resource_group_name       = azurerm_resource_group.rg["nva"].name
  virtual_network_name      = module.network["nva"].vnet_name
  remote_virtual_network_id = module.network[each.key].vnet_id
  allow_forwarded_traffic   = true
}

# Create spoke to nva peerings
resource "azurerm_virtual_network_peering" "spokeToNva" {
  for_each                  = local.spokeNvaPeerings
  name                      = format("%s-to-nva", each.key)
  resource_group_name       = azurerm_resource_group.rg[each.key].name
  virtual_network_name      = module.network[each.key].vnet_name
  remote_virtual_network_id = module.network["nva"].vnet_id
  allow_forwarded_traffic   = true
}

############################ Virtual WAN ############################

# Create vWAN
resource "azurerm_virtual_wan" "vWan" {
  name                = format("%s-vWan-%s", var.projectPrefix, random_id.buildSuffix.hex)
  resource_group_name = azurerm_resource_group.rg["nva"].name
  location            = azurerm_resource_group.rg["nva"].location

  tags = {
    Name      = format("%s-vWan-%s", var.resourceOwner, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

# Create vHub
resource "azurerm_virtual_hub" "vHub" {
  name                = format("%s-vHub-%s", var.projectPrefix, random_id.buildSuffix.hex)
  resource_group_name = azurerm_resource_group.rg["nva"].name
  location            = azurerm_resource_group.rg["nva"].location
  sku                 = "Standard"
  virtual_wan_id      = azurerm_virtual_wan.vWan.id
  address_prefix      = "10.0.0.0/24"

  tags = {
    Name      = format("%s-vHub-%s", var.resourceOwner, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

# Create vHub connection to NVA VNet
resource "azurerm_virtual_hub_connection" "nva" {
  name                      = format("%s-nva-%s", var.projectPrefix, random_id.buildSuffix.hex)
  virtual_hub_id            = azurerm_virtual_hub.vHub.id
  remote_virtual_network_id = module.network["nva"].vnet_id
}

# Note: currently a bug in provider for BGP connection, must create manually
#       See https://github.com/hashicorp/terraform-provider-azurerm/issues/17872

# Create BGP peer between vHub and BIG-IP devices
# resource "azurerm_virtual_hub_bgp_connection" "bigip" {
#   count          = var.instanceCountBigIp
#   name           = "bigip-${count.index}"
#   virtual_hub_id = azurerm_virtual_hub.vHub.id
#   peer_asn       = 65530
#   peer_ip        = element(flatten(module.bigip[count.index].private_addresses.public_private.private_ip), 0)
# }

############################ VM for Client ############################

module "client" {
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.rg["spoke1"].name
  vm_hostname         = "client"
  vm_os_publisher     = "Canonical"
  vm_os_offer         = "0001-com-ubuntu-server-focal"
  vm_os_sku           = "20_04-lts"
  vnet_subnet_id      = module.network["spoke1"].vnet_subnets[0]
  ssh_key             = var.ssh_key
  remote_port         = "22"

  tags = {
    Name      = format("%s-client-%s", var.resourceOwner, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

############################ VM for App ############################

# App Onboarding script
data "local_file" "appOnboard" {
  filename = "${path.module}/scripts/init-app.sh"
}

module "app" {
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.rg["spoke2"].name
  vm_hostname         = "app"
  vm_os_publisher     = "Canonical"
  vm_os_offer         = "0001-com-ubuntu-server-focal"
  vm_os_sku           = "20_04-lts"
  vnet_subnet_id      = module.network["spoke2"].vnet_subnets[2]
  ssh_key             = var.ssh_key
  custom_data         = data.local_file.appOnboard.content_base64

  tags = {
    Name      = format("%s-app-%s", var.resourceOwner, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}
