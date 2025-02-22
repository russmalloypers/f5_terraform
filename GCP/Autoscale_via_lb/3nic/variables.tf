# Variables

variable "projectPrefix" {
  type        = string
  default     = "demo"
  description = "This value is inserted at the beginning of each Google object (alpha-numeric, no special character)"
}
variable "gcp_project_id" {
  type        = string
  default     = null
  description = "GCP Project ID for provider"
}
variable "gcp_region" {
  type        = string
  default     = "us-west1"
  description = "GCP Region for provider"
}
variable "gcp_zone_1" {
  type        = string
  default     = "us-west1-a"
  description = "GCP Zone 1 for provider"
}
variable "extVpc" {
  type        = string
  default     = null
  description = "External VPC network"
}
variable "intVpc" {
  type        = string
  default     = null
  description = "Internal VPC network"
}
variable "mgmtVpc" {
  type        = string
  default     = null
  description = "Management VPC network"
}
variable "extSubnet" {
  type        = string
  default     = null
  description = "External subnet"
}
variable "intSubnet" {
  type        = string
  default     = null
  description = "Internal subnet"
}
variable "mgmtSubnet" {
  type        = string
  default     = null
  description = "Management subnet"
}
variable "auto_healing_initial_delay_sec" {
  type        = number
  default     = 900
  description = "The number of seconds that the managed instance group waits before it applies autohealing policies to new instances or recently recreated instances"
}
variable "update_policy_type" {
  type        = string
  default     = "PROACTIVE"
  description = "The type of autoscale update process"
}
variable "update_policy_minimal_action" {
  type        = string
  default     = "REPLACE"
  description = "Minimal action to be taken on an autoscale instance"
}
variable "update_policy_max_surge_fixed" {
  type        = number
  default     = 3
  description = "The maximum number of instances that can be created above the specified targetSize during the update process"
}
variable "update_policy_max_unavailable_fixed" {
  type        = number
  default     = 0
  description = "The maximum number of instances that can be unavailable during the update process"
}
variable "update_policy_min_ready_sec" {
  type        = number
  default     = 0
  description = "Minimum number of seconds to wait for after a newly created instance becomes available"
}
variable "autoscaling_max_replicas" {
  type        = number
  default     = 4
  description = "The maximum number of instances that the autoscaler can scale up to"
}
variable "autoscaling_min_replicas" {
  type        = number
  default     = 2
  description = "The minimum number of replicas that the autoscaler can scale down to"
}
variable "autoscaling_cooldown_period" {
  type        = number
  default     = 900
  description = "The number of seconds that the autoscaler should wait before it starts collecting information from a new instance"
}
variable "autoscaling_cpu_target" {
  type        = string
  default     = ".7"
  description = "The target CPU utilization that the autoscaler should maintain"
}
variable "machine_type" {
  type        = string
  default     = "n1-standard-8"
  description = "Google machine type to be used for the BIG-IP VE"
}
variable "image_name" {
  type        = string
  default     = "projects/f5-7626-networks-public/global/images/f5-bigip-16-1-3-1-0-0-11-payg-best-plus-200mbps-220721054505"
  description = "F5 SKU (image) to deploy. Note: The disk size of the VM will be determined based on the option you select.  **Important**: If intending to provision multiple modules, ensure the appropriate value is selected, such as ****AllTwoBootLocations or AllOneBootLocation****."
}
variable "customImage" {
  type        = string
  default     = ""
  description = "A custom SKU (image) to deploy that you provide. This is useful if you created your own BIG-IP image with the F5 image creator tool."
}
variable "customUserData" {
  type        = string
  default     = ""
  description = "The custom user data to deploy when using the 'customImage' paramater too."
}
variable "f5_username" {
  type        = string
  default     = "admin"
  description = "User name for the BIG-IP"
}
variable "f5_password" {
  type        = string
  default     = "Default12345!"
  description = "BIG-IP Password or Google secret name (value should be Google secret name when gcp_secret_manager_authentication = true, ex. my-bigip-secret)"
}
variable "ssh_key" {
  type        = string
  description = "public key used for authentication in /path/file format (e.g. /.ssh/id_rsa.pub)"
}
variable "gcp_secret_manager_authentication" {
  type        = bool
  default     = false
  description = "Whether to use secret manager to pass authentication"
}
variable "svc_acct" {
  type        = string
  default     = null
  description = "Service Account for VM instance"
}
variable "telemetry_secret" {
  type        = string
  default     = ""
  description = "Contains the value of the 'svc_acct' private key. Currently used for BIG-IP telemetry streaming to Google Cloud Monitoring (aka StackDriver). If you are not using this feature, you do not need this secret in Secret Manager."
}
variable "telemetry_privateKeyId" {
  type        = string
  default     = ""
  description = "ID of private key for the 'svc_acct' used in Telemetry Streaming to Google Cloud Monitoring. If you are not using this feature, you do not need this secret in Secret Manager."
}
variable "dns_server" {
  type        = string
  default     = "169.254.169.254"
  description = "Leave the default DNS server the BIG-IP uses, or replace the default DNS server with the one you want to use"
}
variable "dns_suffix" {
  type        = string
  default     = "example.com"
  description = "DNS suffix for your domain in the GCP project"
}
variable "ntp_server" {
  type        = string
  default     = "0.us.pool.ntp.org"
  description = "Leave the default NTP server the BIG-IP uses, or replace the default NTP server with the one you want to use"
}
variable "timezone" {
  type        = string
  default     = "UTC"
  description = "If you would like to change the time zone the BIG-IP uses, enter the time zone you want to use. This is based on the tz database found in /usr/share/zoneinfo (see the full list [here](https://cloud.google.com/dataprep/docs/html/Supported-Time-Zone-Values_66194188)). Example values: UTC, US/Pacific, US/Eastern, Europe/London or Asia/Singapore."
}
variable "DO_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.31.0/f5-declarative-onboarding-1.31.0-6.noarch.rpm"
  description = "URL to download the BIG-IP Declarative Onboarding module"
}
variable "AS3_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.38.0/f5-appsvcs-3.38.0-4.noarch.rpm"
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
}
variable "TS_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.30.0/f5-telemetry-1.30.0-1.noarch.rpm"
  description = "URL to download the BIG-IP Telemetry Streaming module"
}
variable "FAST_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.19.0/f5-appsvcs-templates-1.19.0-1.noarch.rpm"
  description = "URL to download the BIG-IP FAST module"
}
variable "INIT_URL" {
  type        = string
  default     = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.5.1/dist/f5-bigip-runtime-init-1.5.1-1.gz.run"
  description = "URL to download the BIG-IP runtime init"
}
variable "libs_dir" {
  type    = string
  default = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.5.0/dist/f5-bigip-runtime-init-1.5.0-1.gz.run"
}
variable "bigIqHost" {
  type        = string
  default     = ""
  description = "This is the BIG-IQ License Manager host name or IP address"
}
variable "bigIqUsername" {
  type        = string
  default     = "admin"
  description = "Admin name for BIG-IQ"
}
variable "bigIqPassword" {
  type        = string
  default     = "Default12345!"
  description = "Admin Password for BIG-IQ"
}
variable "bigIqLicenseType" {
  type        = string
  default     = "licensePool"
  description = "BIG-IQ license type"
}
variable "bigIqLicensePool" {
  type        = string
  default     = ""
  description = "BIG-IQ license pool name"
}
variable "bigIqSkuKeyword1" {
  type        = string
  default     = "key1"
  description = "BIG-IQ license SKU keyword 1"
}
variable "bigIqSkuKeyword2" {
  type        = string
  default     = "key2"
  description = "BIG-IQ license SKU keyword 2"
}
variable "bigIqUnitOfMeasure" {
  type        = string
  default     = "hourly"
  description = "BIG-IQ license unit of measure"
}
variable "bigIqHypervisor" {
  type        = string
  default     = "gce"
  description = "BIG-IQ hypervisor"
}
variable "resourceOwner" {
  type        = string
  default     = null
  description = "This is a tag used for object creation. Example is last name."
}
