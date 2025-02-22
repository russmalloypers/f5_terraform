# Description
Azure Route Server and BIG-IP using BGP and eCMP for traffic distribution

## To Do
- Community support only. Not F5 supported.
- TS still not used and not installed
- BIG-IP module automatically builds user-identity
  - User-identity is tied to key vault policy
  - User should be able to provide existing user-identity ID
  - See https://github.com/F5Networks/terraform-azure-bigip-module/issues/34
- Finish BIG-IP setup with test app
- Remove test network virtuals (10.100, 10.101, 10.102)...testing only


## Issues
- Find an issue? Fork, clone, create branch, fix and PR. I'll review and merge into the main branch. Or submit a GitHub issue with all necessary details and logs.

## Diagram

![Azure Route Server and BIG-IP](images/azure-route-server-overview.png)

## Prerequisites

- Azure CLI
- Terraform
- Azure Subscription
- Azure User with 'Owner' role

## Login to Azure Environment

```bash
# Login
az login

# Show subscriptions
az account show

# Set default
az account set -s <subscriptionId>
```

## Usage example

- Clone the repo and open the solution's directory
```bash
git clone https://github.com/JeffGiroux/f5_terraform.git
cd f5_terraform/Azure/Route_Server/
```

- Create the tfvars file and update it with your settings

```bash
cp admin.auto.tfvars.example admin.auto.tfvars
# MODIFY TO YOUR SETTINGS
vi admin.auto.tfvars
```

- Run the setup script to deploy all of the components into your Azure account (remember that you are responsible for the cost of those components)

```bash
./setup.sh
```

## Test your setup

- View the created objects in Azure Portal. Choose a VM instance or NIC from a spoke VNet and view "Effective Routes". You will see BIG-IP advertised routes via BGP across the VNet peering. This deployment will launch a single BIG-IP instance, but if you modified 'instanceCountBigIp' then you will see identical network prefixes advertised from multiple BIG-IP devices (aka BGP peers) like the screenshot below. The 10.255.10.4 is BIG-IP #1 and 10.255.10.6 is BIG-IP #2.

![Azure Effective Routes](images/azure-effective-routes.png)

- View BPG peering on the Azure Route Server object in the portal - https://aka.ms/routeserver

![Azure BGP Peering](images/azure-bgp-peering.png)

- Validate BGP peering on BIG-IP using tmsh
```bash
(tmos)# show net routing bgp
------------------------------------------
Net::BGP Instance (route-domain: 0)
------------------------------------------
  Name                               myBGP
  Local AS                           65530

  ----------------------------------------------------------------------------
  | Net::BGP Neighbor - 10.255.255.5 via 10.255.10.4
  ----------------------------------------------------------------------------
  | Remote AS                   0
  | State                       established   0:06:24
  | Notification                Cease/Administratively Shutdown.
  | Address Family              IPv4 Unicast  IPv6 Unicast
  |  Prefix
  |   Accepted                  3
  |   Announced                 6
  |  Table Version
  |   Local                     6
  |   Neighbor                  6
  | Message/Notification/Queue  Sent          Received
  |  Message                    27            26
  |  Notification               0             2
  |  Queued                     0             0
  | Route Refresh               0             0
```

- View running config on BIG-IP using imish
```bash
(tmos)# imish
f5vm01.example.com[0]#show running-config
!
service password-encryption
!
bgp extended-asn-cap
!
router bgp 65530
 bgp graceful-restart restart-time 120
 aggregate-address 10.100.0.0/16 summary-only
 aggregate-address 10.101.0.0/16 summary-only
 aggregate-address 10.102.0.0/16 summary-only
 redistribute kernel
 neighbor Neighbor peer-group
 neighbor Neighbor remote-as 65515
 neighbor Neighbor ebgp-multihop 2
 no neighbor Neighbor capability route-refresh
 neighbor Neighbor soft-reconfiguration inbound
 neighbor Neighbor prefix-list /Common/myPrefixList1 out
 neighbor 10.255.255.4 peer-group Neighbor
 neighbor 10.255.255.5 peer-group Neighbor
 !
 address-family ipv6
 neighbor Neighbor activate
 no neighbor 10.255.255.4 activate
 no neighbor 10.255.255.4 capability graceful-restart
 no neighbor 10.255.255.5 activate
 no neighbor 10.255.255.5 capability graceful-restart
 exit-address-family
!
ip route 0.0.0.0/0 10.255.10.1
!
ip prefix-list /Common/myPrefixList1 seq 10 permit 10.0.0.0/8 ge 16
!
line con 0
 login
line vty 0 39
 login
!
end
```

- Validate BGP on BIG-IP using imish
```bash
f5vm01.example.com[0]>show ip bgp summary
BGP router identifier 10.255.20.4, local AS number 65530
BGP table version is 6
2 BGP AS-PATH entries
0 BGP community entries

Neighbor        V    AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
10.255.255.4    4 65515      20      17        6    0    0 00:02:38        3
10.255.255.5    4 65515      19      20        6    0    0 00:02:38        3

Total number of neighbors 2

##
f5vm01.example.com[0]>show ip bgp
BGP table version is 6, local router ID is 10.255.20.4
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal, l - labeled
              S Stale
Origin codes: i - IGP, e - EGP, ? - incomplete

   Network          Next Hop            Metric     LocPrf     Weight Path
*  10.1.0.0/16      10.255.255.5             0                     0 65515 i
*>                  10.255.255.4             0                     0 65515 i
*  10.2.0.0/16      10.255.255.5             0                     0 65515 i
*>                  10.255.255.4             0                     0 65515 i
*> 10.100.0.0/16    0.0.0.0                                    32768 ?
*> 10.101.0.0/16    0.0.0.0                                    32768 ?
*> 10.102.0.0/16    0.0.0.0                                    32768 ?
*  10.255.0.0/16    10.255.255.5             0                     0 65515 i
*>                  10.255.255.4             0                     0 65515 i

Total number of prefixes 6
```

## Troubleshooting
If you don't see routes in the spoke VNets, then try deleting the VNet peering and re-run Terraform to have it create the peer again. If you happen to run into this issue, open an issue directly with Azure support to provide feedback.

You can view BIG-IP onboard logs in /var/log/cloud. Review logs for failure message.

You can view BIG-IP onboard config files in /config/cloud. Review the declarative onboarding JSON file as well as the runtime init YAML file for accuracy. Did the variables render correctly?

If BIG-IP imish commands do not provide results to "show ip bgp" or "show run" but you do see "tmsh list net routing", then something happen in the preview tmsh BGP/routing feature. You should simply delete and recreate the device.
```bash
# taint BIG-IP resource
terraform taint module.bigip[0].azurerm_linux_virtual_machine.f5vm01
terraform taint module.bigip[0].azurerm_virtual_machine_extension.vmext
# re-run terraform
./setup.sh
```

You can manually re-run BIG-IP Runtime init and force declarations to re-run. SSH to the BIG-IP, enter 'bash' mode and run this command.
```bash
f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml
```

## Cleanup
Use the following command to destroy all of the resources

```bash
./destroy.sh
```

<!-- markdownlint-disable no-inline-html -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_app"></a> [app](#module\_app) | Azure/compute/azurerm | n/a |
| <a name="module_bigip"></a> [bigip](#module\_bigip) | github.com/F5Networks/terraform-azure-bigip-module | n/a |
| <a name="module_client"></a> [client](#module\_client) | Azure/compute/azurerm | n/a |
| <a name="module_network"></a> [network](#module\_network) | Azure/vnet/azurerm | n/a |
| <a name="module_nsg-external"></a> [nsg-external](#module\_nsg-external) | Azure/network-security-group/azurerm | n/a |
| <a name="module_nsg-internal"></a> [nsg-internal](#module\_nsg-internal) | Azure/network-security-group/azurerm | n/a |
| <a name="module_nsg-mgmt"></a> [nsg-mgmt](#module\_nsg-mgmt) | Azure/network-security-group/azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_public_ip.routeServerPip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_route_table.rt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_virtual_hub.routeServer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_hub) | resource |
| [azurerm_virtual_hub_bgp_connection.bigip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_hub_bgp_connection) | resource |
| [azurerm_virtual_hub_ip.routeServerIp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_hub_ip) | resource |
| [azurerm_virtual_network_peering.hubToSpoke](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [azurerm_virtual_network_peering.spokeToHub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [random_id.buildSuffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [azurerm_subnet.externalSubnetHub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_subnet.internalSubnetHub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_subnet.mgmtSubnetHub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_subnet.routeServerSubnetHub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [local_file.appOnboard](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | public key used for authentication in /path/file format (e.g. /.ssh/id\_rsa.pub) | `string` | n/a | yes |
| <a name="input_AS3_URL"></a> [AS3\_URL](#input\_AS3\_URL) | URL to download the BIG-IP Application Service Extension 3 (AS3) module | `string` | `"https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.38.0/f5-appsvcs-3.38.0-4.noarch.rpm"` | no |
| <a name="input_DO_URL"></a> [DO\_URL](#input\_DO\_URL) | URL to download the BIG-IP Declarative Onboarding module | `string` | `"https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.31.0/f5-declarative-onboarding-1.31.0-6.noarch.rpm"` | no |
| <a name="input_FAST_URL"></a> [FAST\_URL](#input\_FAST\_URL) | URL to download the BIG-IP FAST module | `string` | `"https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.19.0/f5-appsvcs-templates-1.19.0-1.noarch.rpm"` | no |
| <a name="input_INIT_URL"></a> [INIT\_URL](#input\_INIT\_URL) | URL to download the BIG-IP runtime init | `string` | `"https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.5.1/dist/f5-bigip-runtime-init-1.5.1-1.gz.run"` | no |
| <a name="input_TS_URL"></a> [TS\_URL](#input\_TS\_URL) | URL to download the BIG-IP Telemetry Streaming module | `string` | `"https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.30.0/f5-telemetry-1.30.0-1.noarch.rpm"` | no |
| <a name="input_adminSrcAddr"></a> [adminSrcAddr](#input\_adminSrcAddr) | Allowed Admin source IP prefix | `string` | `"0.0.0.0/0"` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Azure Availability Zone for BIG-IP 1 | `number` | `1` | no |
| <a name="input_az_keyvault_authentication"></a> [az\_keyvault\_authentication](#input\_az\_keyvault\_authentication) | Whether to use key vault to pass authentication | `bool` | `false` | no |
| <a name="input_bigIqHost"></a> [bigIqHost](#input\_bigIqHost) | This is the BIG-IQ License Manager host name or IP address | `string` | `""` | no |
| <a name="input_bigIqHypervisor"></a> [bigIqHypervisor](#input\_bigIqHypervisor) | BIG-IQ hypervisor | `string` | `"azure"` | no |
| <a name="input_bigIqLicensePool"></a> [bigIqLicensePool](#input\_bigIqLicensePool) | BIG-IQ license pool name | `string` | `""` | no |
| <a name="input_bigIqLicenseType"></a> [bigIqLicenseType](#input\_bigIqLicenseType) | BIG-IQ license type | `string` | `"licensePool"` | no |
| <a name="input_bigIqPassword"></a> [bigIqPassword](#input\_bigIqPassword) | Admin Password for BIG-IQ | `string` | `"Default12345!"` | no |
| <a name="input_bigIqSkuKeyword1"></a> [bigIqSkuKeyword1](#input\_bigIqSkuKeyword1) | BIG-IQ license SKU keyword 1 | `string` | `"key1"` | no |
| <a name="input_bigIqSkuKeyword2"></a> [bigIqSkuKeyword2](#input\_bigIqSkuKeyword2) | BIG-IQ license SKU keyword 2 | `string` | `"key2"` | no |
| <a name="input_bigIqUnitOfMeasure"></a> [bigIqUnitOfMeasure](#input\_bigIqUnitOfMeasure) | BIG-IQ license unit of measure | `string` | `"hourly"` | no |
| <a name="input_bigIqUsername"></a> [bigIqUsername](#input\_bigIqUsername) | Admin name for BIG-IQ | `string` | `"azureuser"` | no |
| <a name="input_bigip_version"></a> [bigip\_version](#input\_bigip\_version) | BIG-IP Version | `string` | `"16.1.301000"` | no |
| <a name="input_dns_server"></a> [dns\_server](#input\_dns\_server) | Leave the default DNS server the BIG-IP uses, or replace the default DNS server with the one you want to use | `string` | `"8.8.8.8"` | no |
| <a name="input_f5_password"></a> [f5\_password](#input\_f5\_password) | BIG-IP Password or Key Vault secret name (value should be Key Vault secret name when az\_key\_vault\_authentication = true, ex. my-bigip-secret) | `string` | `"Default12345!"` | no |
| <a name="input_f5_username"></a> [f5\_username](#input\_f5\_username) | User name for the BIG-IP | `string` | `"azureuser"` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | F5 SKU (image) to deploy. Note: The disk size of the VM will be determined based on the option you select.  **Important**: If intending to provision multiple modules, ensure the appropriate value is selected, such as ****AllTwoBootLocations or AllOneBootLocation****. | `string` | `"f5-big-best-plus-hourly-200mbps"` | no |
| <a name="input_instanceCountBigIp"></a> [instanceCountBigIp](#input\_instanceCountBigIp) | Number of BIG-IP instances to deploy | `number` | `1` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Azure instance type to be used for the BIG-IP VE | `string` | `"Standard_DS4_v2"` | no |
| <a name="input_keyvault_rg"></a> [keyvault\_rg](#input\_keyvault\_rg) | The name of the resource group in which the Azure Key Vault exists | `string` | `""` | no |
| <a name="input_keyvault_url"></a> [keyvault\_url](#input\_keyvault\_url) | The URL of the Azure Key Vault to use (ex. https://myKeyVault123.vault.azure.net) | `string` | `""` | no |
| <a name="input_libs_dir"></a> [libs\_dir](#input\_libs\_dir) | Directory on the BIG-IP to download the A&O Toolchain into | `string` | `"/config/cloud/azure/node_modules"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure Location of the deployment | `string` | `"westus2"` | no |
| <a name="input_ntp_server"></a> [ntp\_server](#input\_ntp\_server) | Leave the default NTP server the BIG-IP uses, or replace the default NTP server with the one you want to use | `string` | `"0.us.pool.ntp.org"` | no |
| <a name="input_product"></a> [product](#input\_product) | Azure BIG-IP VE Offer | `string` | `"f5-big-ip-best"` | no |
| <a name="input_projectPrefix"></a> [projectPrefix](#input\_projectPrefix) | This value is inserted at the beginning of each Azure object (alpha-numeric, no special character) | `string` | `"demo"` | no |
| <a name="input_resourceOwner"></a> [resourceOwner](#input\_resourceOwner) | This is a tag used for object creation. Example is last name. | `string` | `null` | no |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | If you would like to change the time zone the BIG-IP uses, enter the time zone you want to use. This is based on the tz database found in /usr/share/zoneinfo (see the full list [here](https://github.com/F5Networks/f5-azure-arm-templates/blob/master/azure-timezone-list.md)). Example values: UTC, US/Pacific, US/Eastern, Europe/London or Asia/Singapore. | `string` | `"UTC"` | no |
| <a name="input_user_identity"></a> [user\_identity](#input\_user\_identity) | The ID of the managed user identity to assign to the BIG-IP instance | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_appPrivateIP"></a> [appPrivateIP](#output\_appPrivateIP) | The private ip address allocated for the webapp in Spoke 2 |
| <a name="output_appPublicIP"></a> [appPublicIP](#output\_appPublicIP) | The public ip address allocated for the app in Spoke 2 |
| <a name="output_bigip-private-ips"></a> [bigip-private-ips](#output\_bigip-private-ips) | The private ip address for BIG-IP |
| <a name="output_bigipPassword"></a> [bigipPassword](#output\_bigipPassword) | The password for the BIG-IP (if dynamic\_password is choosen it will be random generated password or if azure\_keyvault is choosen it will be key vault secret name ) |
| <a name="output_bigipPublicIP"></a> [bigipPublicIP](#output\_bigipPublicIP) | The public ip address allocated for the BIG-IP |
| <a name="output_bigipUserName"></a> [bigipUserName](#output\_bigipUserName) | The user name for the BIG-IP |
| <a name="output_clientPrivateIP"></a> [clientPrivateIP](#output\_clientPrivateIP) | The private ip address allocated for the client/jumphost in Spoke 1 |
| <a name="output_clientPublicIP"></a> [clientPublicIP](#output\_clientPublicIP) | The public ip address allocated for the client/jumphost in Spoke 1 |
| <a name="output_vnetIdHub"></a> [vnetIdHub](#output\_vnetIdHub) | Hub VNet ID |
| <a name="output_vnetIdSpoke1"></a> [vnetIdSpoke1](#output\_vnetIdSpoke1) | Spoke1 VNet ID |
| <a name="output_vnetIdSpoke2"></a> [vnetIdSpoke2](#output\_vnetIdSpoke2) | Spoke2 VNet ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html -->


## How to Contribute

Submit a pull request

# Authors
Jeff Giroux
