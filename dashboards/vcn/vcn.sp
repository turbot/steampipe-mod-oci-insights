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

category "vcn_flow_log" {
  title = "VCN Flow Log"
  icon  = "export_notes"
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
  icon  = "sync_alt"
  color = local.networking_color
}

category "vcn_nat_gateway" {
  title = "VCN Nat Gateway"
  icon  = "lan"
  color = local.networking_color
}

category "vcn_network_load_balancer" {
  title = "VCN Network Load Balancer"
  icon  = "mediation"
  color = local.networking_color
}

category "vcn_network_security_group" {
  title = "VCN Network Security Group"
  href  = "/oci_insights.dashboard.vcn_network_security_group_detail?input.security_group_id={{.properties.'ID' | @uri}}"
  icon  = "enhanced_encryption"
  color = local.networking_color
}

category "vcn_route_table" {
  title = "VCN Route Table"
  icon  = "table_rows"
  color = local.networking_color
}

category "vcn_security_list" {
  title = "VCN Security List"
  href  = "/oci_insights.dashboard.vcn_security_list_detail?input.security_list_id={{.properties.'ID' | @uri}}"
  icon  = "text:SL"
  color = local.networking_color
}

category "vcn_service_gateway" {
  title = "VCN Service Gateway"
  icon  = "vpn_lock"
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

category "vcn_vnic" {
  title = "VCN Virtual Network Interface Card"
  icon  = "memory"
  color = local.networking_color
}