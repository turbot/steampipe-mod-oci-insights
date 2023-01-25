dashboard "ons_notification_topic_detail" {

  title = "OCI ONS Notification Topic Detail"

  tags = merge(local.ons_common_tags, {
    type = "Detail"
  })

  input "topic_id" {
    title = "Select a topic:"
    query = query.ons_notification_topic_input
    width = 4
  }

  container {

    card {
      width = 2

      query = query.ons_notification_topic_state
      args = {
        id = self.input.topic_id.value
      }
    }
  }


  with "compute_instances_for_ons_notification_topic" {
    query = query.compute_instances_for_ons_notification_topic
    args  = [self.input.topic_id.value]
  }

  with "ons_subscriptions_for_ons_notification_topic" {
    query = query.ons_subscriptions_for_ons_notification_topic
    args  = [self.input.topic_id.value]
  }


  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.ons_notification_topic
        args = {
          ons_notification_topic_ids = [self.input.topic_id.value]
        }
      }

      node {
        base = node.compute_instance
        args = {
          compute_instance_ids = with.compute_instances_for_ons_notification_topic.rows[*].instance_id
        }
      }

      node {
        base = node.ons_subscription
        args = {
          ons_subscription_ids = with.ons_subscriptions_for_ons_notification_topic.rows[*].ons_subscription_id
        }
      }

      edge {
        base = edge.compute_instance_to_ons_notification_topic
        args = {
          compute_instance_ids = with.compute_instances_for_ons_notification_topic.rows[*].instance_id
        }
      }

      edge {
        base = edge.ons_notification_topic_to_ons_subscription
        args = {
          ons_notification_topic_ids = [self.input.topic_id.value]
        }
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
        query = query.ons_notification_topic_overview
        args = {
          id = self.input.topic_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.ons_notification_topic_tag
        args = {
          id = self.input.topic_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Subscription Details"
        query = query.ons_notification_topic_subscription
        args = {
          id = self.input.topic_id.value
        }
      }
    }

  }
}

query "ons_notification_topic_input" {
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
    order by
      n.name;
EOQ
}

query "ons_notification_topic_state" {
  sql = <<-EOQ
    select
      initcap(lifecycle_state) as "Lifecycle State"
    from
      oci_ons_notification_topic
    where
      topic_id = $1;
  EOQ

  param "id" {}
}

query "ons_notification_topic_overview" {
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

query "ons_notification_topic_tag" {
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

query "ons_notification_topic_subscription" {
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

#with queries

query "ons_subscriptions_for_ons_notification_topic" {
  sql = <<-EOQ
    select
      id as ons_subscription_id
    from
      oci_ons_subscription
    where
      topic_id = $1;
  EOQ
}

query "compute_instances_for_ons_notification_topic" {
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
      value as instance_id
    from
      jsondata,
      json_each_text(tags)
    where
      key = 'CTX_NOTIFICATIONS_COMPUTE_ID';
  EOQ
}
