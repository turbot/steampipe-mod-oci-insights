locals {
  compute_common_tags = {
    service = "OCI/Compute"
  }
}

category "compute_image" {
  title = "Compute Image"
  icon  = "developer_board"
  color = local.compute_color
}

category "compute_instance" {
  title = "Compute Instance"
  href  = "/oci_insights.dashboard.compute_instance_detail?input.instance_id={{.properties.'ID' | @uri}}"
  icon  = "memory"
  color = local.compute_color
}