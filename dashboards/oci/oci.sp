locals {
  oci_common_tags = {
    service = "OCI"
  }
}

category "availability_domain" {
  title = "Availability Domain"
  color = local.networking_color
  icon  = "apartment"
}