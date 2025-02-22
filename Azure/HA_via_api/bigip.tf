# BIG-IP Cluster

############################ Locals ############################

locals {
  # Retrieve all BIG-IP secondary IPs
  vm01_ext_ips = {
    0 = {
      ip = element(flatten(module.bigip.private_addresses["public_private"]["private_ips"][0]), 0)
    }
    1 = {
      ip = element(flatten(module.bigip.private_addresses["public_private"]["private_ips"][0]), 1)
    }
  }
  vm02_ext_ips = {
    0 = {
      ip = element(flatten(module.bigip2.private_addresses["public_private"]["private_ips"][0]), 0)
    }
    1 = {
      ip = element(flatten(module.bigip2.private_addresses["public_private"]["private_ips"][0]), 1)
    }
  }
  # Determine BIG-IP secondary IPs to be used for VIP
  vm01_vip_ips = {
    app1 = {
      ip = module.bigip.private_addresses["public_private"]["private_ip"][0] != local.vm01_ext_ips.0.ip ? local.vm01_ext_ips.0.ip : local.vm01_ext_ips.1.ip
    }
  }
  vm02_vip_ips = {
    app1 = {
      ip = module.bigip2.private_addresses["public_private"]["private_ip"][0] != local.vm02_ext_ips.0.ip ? local.vm02_ext_ips.0.ip : local.vm02_ext_ips.1.ip
    }
  }
  # Custom tags
  tags = {
    Owner = var.resourceOwner
  }
}

############################ Onboard Scripts ############################

# Setup Onboarding scripts
locals {
  f5_onboard1 = templatefile("${path.module}/f5_onboard.tmpl", {
    regKey                     = var.license1
    f5_username                = var.f5_username
    f5_password                = var.f5_password
    az_keyvault_authentication = var.az_keyvault_authentication
    vault_url                  = var.az_keyvault_authentication ? var.keyvault_url : ""
    ssh_keypair                = file(var.ssh_key)
    INIT_URL                   = var.INIT_URL
    DO_URL                     = var.DO_URL
    AS3_URL                    = var.AS3_URL
    TS_URL                     = var.TS_URL
    CFE_URL                    = var.CFE_URL
    FAST_URL                   = var.FAST_URL
    DO_VER                     = split("/", var.DO_URL)[7]
    AS3_VER                    = split("/", var.AS3_URL)[7]
    TS_VER                     = split("/", var.TS_URL)[7]
    CFE_VER                    = split("/", var.CFE_URL)[7]
    FAST_VER                   = split("/", var.FAST_URL)[7]
    dns_server                 = var.dns_server
    ntp_server                 = var.ntp_server
    timezone                   = var.timezone
    law_id                     = azurerm_log_analytics_workspace.law.workspace_id
    law_primkey                = azurerm_log_analytics_workspace.law.primary_shared_key
    bigIqLicenseType           = var.bigIqLicenseType
    bigIqHost                  = var.bigIqHost
    bigIqPassword              = var.bigIqPassword
    bigIqUsername              = var.bigIqUsername
    bigIqLicensePool           = var.bigIqLicensePool
    bigIqSkuKeyword1           = var.bigIqSkuKeyword1
    bigIqSkuKeyword2           = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure         = var.bigIqUnitOfMeasure
    bigIqHypervisor            = var.bigIqHypervisor
    # cluster info
    host1                   = module.bigip.private_addresses["mgmt_private"]["private_ip"][0]
    host2                   = module.bigip2.private_addresses["mgmt_private"]["private_ip"][0]
    remote_selfip_ext       = module.bigip2.private_addresses["public_private"]["private_ip"][0]
    vip_az1                 = local.vm01_vip_ips.app1.ip
    vip_az2                 = local.vm02_vip_ips.app1.ip
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    cfe_managed_route       = var.cfe_managed_route
  })
  f5_onboard2 = templatefile("${path.module}/f5_onboard.tmpl", {
    regKey                     = var.license2
    f5_username                = var.f5_username
    f5_password                = var.f5_password
    az_keyvault_authentication = var.az_keyvault_authentication
    vault_url                  = var.az_keyvault_authentication ? var.keyvault_url : ""
    ssh_keypair                = file(var.ssh_key)
    INIT_URL                   = var.INIT_URL
    DO_URL                     = var.DO_URL
    AS3_URL                    = var.AS3_URL
    TS_URL                     = var.TS_URL
    CFE_URL                    = var.CFE_URL
    FAST_URL                   = var.FAST_URL
    DO_VER                     = split("/", var.DO_URL)[7]
    AS3_VER                    = split("/", var.AS3_URL)[7]
    TS_VER                     = split("/", var.TS_URL)[7]
    CFE_VER                    = split("/", var.CFE_URL)[7]
    FAST_VER                   = split("/", var.FAST_URL)[7]
    dns_server                 = var.dns_server
    ntp_server                 = var.ntp_server
    timezone                   = var.timezone
    law_id                     = azurerm_log_analytics_workspace.law.workspace_id
    law_primkey                = azurerm_log_analytics_workspace.law.primary_shared_key
    bigIqLicenseType           = var.bigIqLicenseType
    bigIqHost                  = var.bigIqHost
    bigIqPassword              = var.bigIqPassword
    bigIqUsername              = var.bigIqUsername
    bigIqLicensePool           = var.bigIqLicensePool
    bigIqSkuKeyword1           = var.bigIqSkuKeyword1
    bigIqSkuKeyword2           = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure         = var.bigIqUnitOfMeasure
    bigIqHypervisor            = var.bigIqHypervisor
    # cluster info
    host1                   = module.bigip.private_addresses["mgmt_private"]["private_ip"][0]
    host2                   = module.bigip2.private_addresses["mgmt_private"]["private_ip"][0]
    remote_selfip_ext       = module.bigip.private_addresses["public_private"]["private_ip"][0]
    vip_az1                 = local.vm01_vip_ips.app1.ip
    vip_az2                 = local.vm02_vip_ips.app1.ip
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    cfe_managed_route       = var.cfe_managed_route
  })
}

############################ Compute ############################

# Create F5 BIG-IP VMs
module "bigip" {
  source                     = "github.com/F5Networks/terraform-azure-bigip-module"
  prefix                     = var.projectPrefix
  resource_group_name        = azurerm_resource_group.main.name
  f5_instance_type           = var.instance_type
  f5_image_name              = var.image_name
  f5_product_name            = var.product
  f5_version                 = var.bigip_version
  f5_username                = var.f5_username
  f5_ssh_publickey           = file(var.ssh_key)
  mgmt_subnet_ids            = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids     = [data.azurerm_network_security_group.mgmt.id]
  external_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.external.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  external_securitygroup_ids = [data.azurerm_network_security_group.external.id]
  internal_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "" }]
  internal_securitygroup_ids = [data.azurerm_network_security_group.internal.id]
  availability_zone          = var.availability_zone
  custom_user_data           = local.f5_onboard1
  sleep_time                 = "30s"
  tags                       = local.tags
  #az_user_identity           = var.user_identity
}

module "bigip2" {
  source                     = "github.com/F5Networks/terraform-azure-bigip-module"
  prefix                     = var.projectPrefix
  resource_group_name        = azurerm_resource_group.main.name
  f5_instance_type           = var.instance_type
  f5_image_name              = var.image_name
  f5_product_name            = var.product
  f5_version                 = var.bigip_version
  f5_username                = var.f5_username
  f5_ssh_publickey           = file(var.ssh_key)
  mgmt_subnet_ids            = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids     = [data.azurerm_network_security_group.mgmt.id]
  external_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.external.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  external_securitygroup_ids = [data.azurerm_network_security_group.external.id]
  internal_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "" }]
  internal_securitygroup_ids = [data.azurerm_network_security_group.internal.id]
  availability_zone          = var.availability_zone2
  custom_user_data           = local.f5_onboard2
  sleep_time                 = "30s"
  tags                       = local.tags
  #az_user_identity           = var.user_identity
}

############################ Assign Managed Identity to VMs ############################

# Retrieve VM info
data "azurerm_virtual_machine" "f5vm01" {
  name                = element(split("/", module.bigip.bigip_instance_ids), 8)
  resource_group_name = azurerm_resource_group.main.name
}
data "azurerm_virtual_machine" "f5vm02" {
  name                = element(split("/", module.bigip2.bigip_instance_ids), 8)
  resource_group_name = azurerm_resource_group.main.name
}

# Retrieve user identity info
data "azurerm_user_assigned_identity" "f5vm01" {
  name                = element(split("/", element(flatten(lookup(data.azurerm_virtual_machine.f5vm01.identity[0], "identity_ids")), 0)), 8)
  resource_group_name = azurerm_resource_group.main.name
}
data "azurerm_user_assigned_identity" "f5vm02" {
  name                = element(split("/", element(flatten(lookup(data.azurerm_virtual_machine.f5vm02.identity[0], "identity_ids")), 0)), 8)
  resource_group_name = azurerm_resource_group.main.name
}

# Configure user-identity with Contributor role
resource "azurerm_role_assignment" "f5vm01" {
  scope                = data.azurerm_subscription.main.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_user_assigned_identity.f5vm01.principal_id
}
resource "azurerm_role_assignment" "f5vm02" {
  scope                = data.azurerm_subscription.main.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_user_assigned_identity.f5vm02.principal_id
}

############################ Route Tables ############################

# Create Route Table
resource "azurerm_route_table" "udr" {
  name                          = format("%s-udr-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = false

  route {
    name                   = "route1"
    address_prefix         = var.cfe_managed_route
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.bigip2.private_addresses["public_private"]["private_ip"][0]
  }

  tags = {
    owner                   = var.resourceOwner
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    f5_self_ips             = "${module.bigip.private_addresses["public_private"]["private_ip"][0]},${module.bigip2.private_addresses["public_private"]["private_ip"][0]}"
  }
}

############################ Collect Network Info ############################

# JeffGiroux  Needed as workaround.
#             Currenly the BIG-IP module does not support
#             tagging of NICs. Cloud Failover Extension for
#             Azure has pre-reqs and some items need tagging.
#
#             https://github.com/F5Networks/terraform-azure-bigip-module/issues/33

# BIG-IP 1 NIC info
data "azurerm_network_interface" "bigip_ext" {
  name                = format("%s-ext-nic-public-0", element(split("-f5vm01", element(split("/", module.bigip.bigip_instance_ids), 8)), 0))
  resource_group_name = azurerm_resource_group.main.name
}
data "azurerm_network_interface" "bigip_int" {
  name                = format("%s-int-nic0", element(split("-f5vm01", element(split("/", module.bigip.bigip_instance_ids), 8)), 0))
  resource_group_name = azurerm_resource_group.main.name
}

# BIG-IP 2 NIC info
data "azurerm_network_interface" "bigip2_ext" {
  name                = format("%s-ext-nic-public-0", element(split("-f5vm01", element(split("/", module.bigip2.bigip_instance_ids), 8)), 0))
  resource_group_name = azurerm_resource_group.main.name
}
data "azurerm_network_interface" "bigip2_int" {
  name                = format("%s-int-nic0", element(split("-f5vm01", element(split("/", module.bigip2.bigip_instance_ids), 8)), 0))
  resource_group_name = azurerm_resource_group.main.name
}

############################ Tagging ############################

# Add Cloud Failover tags to BIG-IP 1 NICs
resource "null_resource" "f5vm01_nic_tags" {
  depends_on = [module.bigip]
  # Running AZ CLI to add tags
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      az network nic update -g ${azurerm_resource_group.main.name} -n ${data.azurerm_network_interface.bigip_ext.name} --set tags.f5_cloud_failover_label=${format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)} tags.f5_cloud_failover_nic_map=external
      az network nic update -g ${azurerm_resource_group.main.name} -n ${data.azurerm_network_interface.bigip_int.name} --set tags.f5_cloud_failover_label=${format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)} tags.f5_cloud_failover_nic_map=internal
    EOF
  }
}

# Add Cloud Failover tags to BIG-IP 2 NICs
resource "null_resource" "f5vm02_nic_tags" {
  depends_on = [module.bigip2]
  # Running AZ CLI to add tags
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      az network nic update -g ${azurerm_resource_group.main.name} -n ${data.azurerm_network_interface.bigip2_ext.name} --set tags.f5_cloud_failover_label=${format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)} tags.f5_cloud_failover_nic_map=external
      az network nic update -g ${azurerm_resource_group.main.name} -n ${data.azurerm_network_interface.bigip2_int.name} --set tags.f5_cloud_failover_label=${format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)} tags.f5_cloud_failover_nic_map=internal
    EOF
  }
}
