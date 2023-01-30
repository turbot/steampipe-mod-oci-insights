edge "ons_notification_topic_to_ons_subscription" {
  title = "subscription"

  sql = <<-EOQ
    select
      topic_id as from_id,
      id as to_id
    from
      oci_ons_subscription
    where
      topic_id = any($1);
  EOQ

  param "ons_notification_topic_ids" {}
}

edge "compute_instance_to_ons_notification_topic" {
  title = "notifies"

  sql = <<-EOQ
    with jsondata as (
      select
        topic_id,
        tags::json as tags
      from
        oci_ons_notification_topic
    )
    select
      value as from_id,
      topic_id as to_id
    from
      jsondata,
      json_each_text(tags)
    where
      key = 'CTX_NOTIFICATIONS_COMPUTE_ID'
      and value = any($1)
  EOQ

  param "compute_instance_ids" {}
}