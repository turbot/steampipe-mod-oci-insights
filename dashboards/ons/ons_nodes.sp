node "ons_notification_topic" {
  category = category.ons_notification_topic

  sql = <<-EOQ
    select
      topic_id as id,
      title as title,
      jsonb_build_object(
        'ID', topic_id,
        'Short Topic ID', short_topic_id,
        'Name', name,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_ons_notification_topic
    where
      topic_id = any($1);
  EOQ

  param "ons_notification_topic_ids" {}
}

node "ons_subscription" {
  category = category.ons_subscription

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Protocol', protocol,
        'Lifecycle State', lifecycle_state,
        'Created Time', created_time,
        'Endpoint',endpoint,
        'Etag', etag,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_ons_subscription
    where
      id = any($1);
  EOQ

  param "ons_subscription_ids" {}
}

