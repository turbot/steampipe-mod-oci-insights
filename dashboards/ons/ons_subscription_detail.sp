query "oci_ons_subscription_input" {
  sql = <<EOQ
    select
      id as label,
      id as value
    from
      oci_ons_subscription
    order by
      id;
EOQ
}

query "oci_ons_subscription_name_for_subscription" {
  sql = <<-EOQ
    select
      id as "Subscription Id"
    from
      oci_ons_subscription
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_ons_subscription_unused_for_subscription" {
  sql = <<-EOQ
    select
      case when lifecycle_state <> 'ACTIVE' then 'true' else 'false' end as value,
      'Unused' as label,
      case when lifecycle_state <> 'ACTIVE' then 'alert' else 'ok' end as type
    from
      oci_ons_subscription
    where
      id = $1;
  EOQ

  param "id" {}
}

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

    # Assessments
    card {
      width = 3

      query = query.oci_ons_subscription_name_for_subscription
      args = {
        id = self.input.subscription_id.value
      }
    }

    card {
      width = 2

      query = query.oci_ons_subscription_unused_for_subscription
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
           s.topic_id = t.topic_id and
           s.id = $1;
        EOQ

        param "id" {}

        args = {
          id = self.input.subscription_id.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          WITH jsondata AS (
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

        args = {
          id = self.input.subscription_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Protocol"
        sql   = <<-EOQ
          select
            t.name as "Topic Name",
            s.created_time as "Created Time",
            protocol as "Protocol"
          from
            oci_ons_subscription s,
            oci_ons_notification_topic t
          where
           s.topic_id = t.topic_id and
           s.id = $1;
        EOQ

        param "id" {}

        args = {
          id = self.input.subscription_id.value
        }
      }

      table {
        title = "Backoff Retry Policy"
        sql   = <<-EOQ
          select
            t.name as "Topic Name",
            delivery_policy -> 'backoffRetryPolicy' ->> 'maxRetryDuration' as "Max Retry Duration",
            delivery_policy -> 'backoffRetryPolicy' ->> 'policyType' as "Policy Type"
          from
            oci_ons_subscription s,
            oci_ons_notification_topic t
          where
           s.topic_id = t.topic_id and
           s.id = $1;
        EOQ

        param "id" {}

        args = {
          id = self.input.subscription_id.value
        }
      }
    }

  }
}
