dashboard "oci_ons_notification_topic_detail" {

  title = "OCI Notification Topic Detail"

  tags = merge(local.ons_common_tags, {
    type     = "Report"
    category = "Detail"
  })

  input "topic_id" {
    title = "Select a topic:"
    sql   = query.oci_ons_notification_topic_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.oci_ons_notification_topic_state
      args = {
        id = self.input.topic_id.value
      }
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.oci_ons_notification_topic_overview
        args = {
          id = self.input.topic_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_ons_notification_topic_tag
        args = {
          id = self.input.topic_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Subscriptions Details"
        query = query.oci_ons_notification_topic_subscription
        args = {
          id = self.input.topic_id.value
        }
      }
    }

  }
}

query "oci_ons_notification_topic_input" {
  sql = <<EOQ
    select
      n.name as label,
      n.topic_id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'n.region', region,
        't.name', t.name
      ) as tags
    from
      oci_ons_notification_topic as n
      left join oci_identity_compartment as c on n.compartment_id = c.id
      left join oci_identity_tenancy as t on n.tenant_id = t.id
    where
      n.lifecycle_state <> 'DELETED'
    order by
      n.name;
EOQ
}

query "oci_ons_notification_topic_state" {
  sql = <<-EOQ
    select
      lifecycle_state as "Lifecycle State"
    from
      oci_ons_notification_topic
    where
      topic_id = $1;
  EOQ

  param "id" {}
}

query "oci_ons_notification_topic_overview" {
  sql = <<-EOQ
    select
      name as "Topic Name",
      time_created as "Time Created",
      api_endpoint as "API Endpoint",
      topic_id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_ons_notification_topic
    where
      topic_id = $1;
  EOQ

  param "id" {}
}

query "oci_ons_notification_topic_tag" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      oci_ons_notification_topic
    where
      topic_id = $1
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
  EOQ

  param "id" {}
}

query "oci_ons_notification_topic_subscription" {
  sql = <<-EOQ
    select
      endpoint as "Endpoint",
      s.lifecycle_state as "State",
      protocol as "Protocol"
    from
      oci_ons_notification_topic t
      left join oci_ons_subscription as s on s.topic_id = t.topic_id
    where
      t.topic_id = $1;
  EOQ

  param "id" {}
}
