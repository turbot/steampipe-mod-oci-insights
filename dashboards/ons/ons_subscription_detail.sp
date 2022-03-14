dashboard "oci_ons_subscription_detail" {

  title = "OCI ONS Subscription Detail"

  tags = merge(local.ons_common_tags, {
    type     = "Report"
    category = "Detail"
  })

  input "subscription_id" {
    title = "Select a subscription:"
    sql   = query.oci_ons_subscription_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.oci_ons_subscription_state
      args = {
        id = self.input.subscription_id.value
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
        query = query.oci_ons_subscription_overview
        args = {
          id = self.input.subscription_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_ons_subscription_tag
        args = {
          id = self.input.subscription_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Backoff Retry Policy"
        query = query.oci_ons_subscription_backoff
        args = {
          id = self.input.subscription_id.value
        }
      }
    }

  }
}

query "oci_ons_subscription_input" {
  sql = <<EOQ
    select
      s.display_name as label,
      s.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        's.region', region,
        't.name', t.name
      ) as tags
    from
      oci_ons_subscription as s
      left join oci_identity_compartment as c on s.compartment_id = c.id
      left join oci_identity_tenancy as t on s.tenant_id = t.id
    where
      s.lifecycle_state <> 'DELETED'
    order by
      s.display_name;
EOQ
}

query "oci_ons_subscription_state" {
  sql = <<-EOQ
    select
      lifecycle_state as "Lifecycle State"
    from
      oci_ons_subscription
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_ons_subscription_overview" {
  sql = <<-EOQ
    select
      t.name as "Topic Name",
      s.created_time as "Created Time",
      endpoint as "Endpoint",
      s.id as "OCID",
      s.compartment_id as "Compartment ID"
    from
      oci_ons_subscription s,
      oci_ons_notification_topic t
    where
      s.topic_id = t.topic_id and s.id = $1;
  EOQ

  param "id" {}
}

query "oci_ons_subscription_tag" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      oci_ons_subscription
    where
      id = $1
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

query "oci_ons_subscription_backoff" {
  sql = <<-EOQ
    select
      delivery_policy -> 'backoffRetryPolicy' ->> 'maxRetryDuration' as "Max Retry Duration",
      delivery_policy -> 'backoffRetryPolicy' ->> 'policyType' as "Policy Type"
    from
      oci_ons_subscription s
    where
      id = $1;
  EOQ

  param "id" {}
}
