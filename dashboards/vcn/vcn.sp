locals {
  vcn_common_tags = {
    service = "OCI/VCN"
  }
}

category "vcn_vcn" {
  title = "VPC"
  href  = "/oci_insights.dashboard.vcn_detail?input.vcn_id={{.properties.'VCN ID' | @uri}}"
  icon  = "cloud"
  color = local.networking_color
}

category "vcn_subnet" {
  title = "VCN Subnet"
  href  = "/oci_insights.dashboard.vcn_subnet_detail?input.subnet_id={{.properties.'Subnet ID' | @uri}}"
  icon  = "share"
  color = local.networking_color
}

category "vcn_internet_gateway" {
  title = "VCN Internet Gateway"
  icon  = "gate"
  color = local.networking_color
}

category "vcn_network_security_group" {
  title = "VCN Network Security Group"
  href  = "/oci_insights.dashboard.vcn_network_security_group_detail?input.security_group_id={{.properties.'ID' | @uri}}"
  icon  = "enhanced-encryption"
  color = local.networking_color
}

category "vcn_load_balancer" {
  title = "VCN Load Balancer"
  icon  = "mediation"
  color = local.networking_color
}
