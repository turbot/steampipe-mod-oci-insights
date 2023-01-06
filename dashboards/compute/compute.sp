locals {
  compute_common_tags = {
    service = "OCI/Compute"
  }
}

category "compute_image" {
  title = "Compute Image"
  color = local.compute_color
  icon  = "developer_board"
}

category "compute_instance" {
  title = "Compute Instance"
  color = local.compute_color
  href  = "/oci_insights.dashboard.compute_instance_detail?input.instance_id={{.properties.'ID' | @uri}}"
  icon  = "memory"
}