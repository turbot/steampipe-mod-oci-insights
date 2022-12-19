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
