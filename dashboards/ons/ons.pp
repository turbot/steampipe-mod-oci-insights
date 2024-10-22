locals {
  ons_common_tags = {
    service = "OCI/ONS"
  }
}

category "ons_notification_topic" {
  title = "ONS Notification Topic"
  color = local.application_integration_color
  href  = "/oci_insights.dashboard.ons_notification_topic_detail?input.topic_id={{.properties.'ID' | @uri}}"
  icon  = "podcasts"
}

category "ons_subscription" {
  title = "ONS Subscription"
  color = local.application_integration_color
  icon  = "broadcast_on_personal"
}
