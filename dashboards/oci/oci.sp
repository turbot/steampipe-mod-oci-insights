locals {
  oci_common_tags = {
    service = "OCI"
  }
}

category "availability_domain" {
  title = "Availability Domain"
  icon  = "apartment"
  color = local.networking_color
}