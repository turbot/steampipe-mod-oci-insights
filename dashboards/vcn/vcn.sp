locals {
  vcn_common_tags = {
    service = "OCI/VCN"
  }
}

category "vcn_dhcp_option" {
  title = "VCN DHCP Option"
  icon  = "text:DHCP"
  color = local.networking_color
}

category "vcn_internet_gateway" {
  title = "VCN Internet Gateway"
  icon  = "gate"
  color = local.networking_color
}

category "vcn_load_balancer" {
  title = "VCN Load Balancer"
  icon  = "mediation"
  color = local.networking_color
}

category "vcn_local_peering_gateway" {
  title = "VCN Local Peering Gateway"
  icon  = "text:LPG"
  color = local.networking_color
}

category "vcn_nat_gateway" {
  title = "VCN Nat Gateway"
  icon  = "lan"
  color = local.networking_color
}

category "vcn_network_load_balancer" {
  title = "Network Load Balancer"
  icon  = "mediation"
  color = local.networking_color
}

category "vcn_network_security_group" {
  title = "VCN Network Security Group"
  href  = "/oci_insights.dashboard.vcn_network_security_group_detail?input.security_group_id={{.properties.'ID' | @uri}}"
  icon  = "enhanced-encryption"
  color = local.networking_color
}

category "vcn_route_table" {
  title = "VCN Route Table"
  icon  = "table-rows"
  color = local.networking_color
}

category "vcn_security_list" {
  title = "VCN Security List"
  icon  = "text:SL"
  color = local.networking_color
}

category "vcn_service_gateway" {
  title = "VCN Service Gateway"
  icon  = "text:SGW"
  color = local.networking_color
}

category "vcn_subnet" {
  title = "VCN Subnet"
  href  = "/oci_insights.dashboard.vcn_subnet_detail?input.subnet_id={{.properties.'Subnet ID' | @uri}}"
  icon  = "share"
  color = local.networking_color
}

category "vcn_vcn" {
  title = "VCN"
  href  = "/oci_insights.dashboard.vcn_detail?input.vcn_id={{.properties.'VCN ID' | @uri}}"
  icon  = "cloud"
  color = local.networking_color
}