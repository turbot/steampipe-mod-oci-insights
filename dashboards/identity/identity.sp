locals {
  identity_common_tags = {
    service = "OCI/Identity"
  }
}

category "identity_api_key" {
  title = "Identity API Key"
  color = local.iam_color
  icon  = "vpn_key"
}

category "identity_auth_token" {
  title = "Identity Auth Token"
  color = local.iam_color
  icon  = "vpn_key"
}

category "identity_group" {
  title = "Identity Group"
  color = local.iam_color
  href  = "/oci_insights.dashboard.identity_group_detail?input.group_id={{.properties.'ID' | @uri}}"
  icon  = "group"
}

category "identity_user" {
  title = "Identity User"
  color = local.iam_color
  href  = "/oci_insights.dashboard.identity_user_detail?input.user_id={{.properties.'ID' | @uri}}"
  icon  = "person"
}

category "identity_customer_secret_key" {
  title = "Identity Customer Secret Key"
  color = local.iam_color
  icon  = "vpn_key"
}
