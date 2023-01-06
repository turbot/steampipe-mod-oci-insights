locals {
  identity_common_tags = {
    service = "OCI/Identity"
  }
}

category "identity_group" {
  title = "Identity Group"
  color = local.iam_color
  icon  = "group"
}

category "identity_user" {
  title = "Identity User"
  color = local.iam_color
  href  = "/oci_insights.dashboard.identity_user_detail?input.user_id={{.properties.'ID' | @uri}}"
  icon  = "person"
}