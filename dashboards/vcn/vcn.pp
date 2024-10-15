locals {
  vcn_common_tags = {
    service = "OCI/VCN"
  }
}

category "vcn_dhcp_option" {
  title = "VCN DHCP Option"
  color = local.networking_color
  icon  = "dns"
}

category "vcn_flow_log" {
  title = "VCN Flow Log"
  color = local.networking_color
  icon  = "export_notes"
}

category "vcn_internet_gateway" {
  title = "VCN Internet Gateway"
  color = local.networking_color
  icon  = "gate"
}

category "vcn_load_balancer" {
  title = "VCN Load Balancer"
  color = local.networking_color
  icon  = "mediation"
}

category "vcn_local_peering_gateway" {
  title = "VCN Local Peering Gateway"
  color = local.networking_color
  icon  = "sync_alt"
}

category "vcn_nat_gateway" {
  title = "VCN Nat Gateway"
  color = local.networking_color
  icon  = "lan"
}

category "vcn_network_load_balancer" {
  title = "VCN Network Load Balancer"
  color = local.networking_color
  icon  = "mediation"
}

category "vcn_network_security_group" {
  title = "VCN Network Security Group"
  color = local.networking_color
  href  = "/oci_insights.dashboard.vcn_network_security_group_detail?input.security_group_id={{.properties.'ID' | @uri}}"
  icon  = "enhanced_encryption"
}

category "vcn_public_ip" {
  title = "VCN Public IP"
  color = local.networking_color
  href  = "/oci_insights.dashboard.vcn_public_ip_detail?input.public_ip_id={{.properties.'ID' | @uri}}"
  icon  = "swipe_right_alt"
}

category "vcn_route_table" {
  title = "VCN Route Table"
  color = local.networking_color
  icon  = "table_rows"
}

category "vcn_security_list" {
  title = "VCN Security List"
  color = local.networking_color
  href  = "/oci_insights.dashboard.vcn_security_list_detail?input.security_list_id={{.properties.'ID' | @uri}}"
  icon  = "enhanced_encryption"
}

category "vcn_service_gateway" {
  title = "VCN Service Gateway"
  color = local.networking_color
  icon  = "vpn_lock"
}

category "vcn_subnet" {
  title = "VCN Subnet"
  color = local.networking_color
  href  = "/oci_insights.dashboard.vcn_subnet_detail?input.subnet_id={{.properties.'Subnet ID' | @uri}}"
  icon  = "lan"
}

category "vcn_vcn" {
  title = "VCN"
  color = local.networking_color
  href  = "/oci_insights.dashboard.vcn_detail?input.vcn_id={{.properties.'VCN ID' | @uri}}"
  icon  = "cloud"
}

category "vcn_vnic" {
  title = "VCN Virtual Network Interface Card"
  color = local.networking_color
  icon  = "memory"
}