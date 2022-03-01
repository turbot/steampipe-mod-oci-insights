query "oci_ons_notification_topic_count" {
  sql = <<-EOQ
    select count(*) as "Topics" from oci_ons_notification_topic;
  EOQ
}

query "oci_ons_notification_topic_unused_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'No Active Subscription' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_ons_notification_topic
    where
      topic_id in (
    select
      topic_id
    from
      oci_ons_subscription
    where
      lifecycle_state <> 'ACTIVE'
      );
  EOQ
}

# Assessments

# query "oci_ons_notification_topic_by_lifecycle_state" {
#   sql = <<-EOQ
#     select
#       lifecycle_state,
#       count(lifecycle_state)
#     from
#       oci_ons_notification_topic
#     group by
#       lifecycle_state;
#   EOQ
# }

# https://pkg.go.dev/github.com/oracle/oci-go-sdk@v24.3.0+incompatible/ons#NotificationTopicLifecycleStateEnum
query "oci_ons_notification_topic_by_lifecycle_state" {
  sql = <<-EOQ
    with lifecycle_stat as (
      select
        case
          when lifecycle_state = 'CREATING' then 'creating'
          when lifecycle_state = 'DELETING' then 'deleting'
          else 'active'
        end as lifecycle_stat
      from
        oci_ons_notification_topic
    )
      select
        lifecycle_stat,
        count(*)
      from
        lifecycle_stat
      group by
        lifecycle_stat
  EOQ
}

query "oci_ons_notification_topic_by_subscription" {
  sql = <<-EOQ
    select
      name,
      count(name)
    from
      oci_ons_notification_topic
    where
      topic_id in (
    select
      topic_id
    from
      oci_ons_subscription
    where
      lifecycle_state <> 'ACTIVE'
      )
    group by
      name;
  EOQ
}

# Analysis
query "oci_ons_notification_topic_by_tenancy" {
  sql = <<-EOQ
    select
      c.title as "Tenancy",
      count(t.*) as "Topics"
    from
      oci_ons_notification_topic as t,
      oci_identity_tenancy as c
    where
      c.id = t.tenant_id
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_ons_notification_topic_by_compartment" {
  sql = <<-EOQ
    with compartments as (
      select
        id, title
      from
        oci_identity_tenancy
      union (
      select
        id,title
      from
        oci_identity_compartment
      where
        lifecycle_state = 'ACTIVE'
        )
      )
    select
      b.title as "Tenancy",
      case when b.title = c.title then 'root' else c.title end as "Compartment",
      count(a.*) as "Topics"
    from
      oci_kms_key as a,
      oci_identity_tenancy as b,
      compartments as c
    where
      c.id = a.compartment_id and a.tenant_id = b.id
    group by
      b.title,
      c.title
    order by
      b.title,
      c.title;
  EOQ
}

query "oci_ons_notification_topic_by_region" {
  sql = <<-EOQ
    select
    region as "Region",
    count(*) as "Topics"
    from
      oci_ons_notification_topic
    group by
      region
    order by
      region;
  EOQ
}

query "oci_ons_notification_topic_by_creation_month" {
  sql = <<-EOQ
    with topics as (
      select
        name,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_ons_notification_topic
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(time_created)
                from topics)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    topics_by_month as (
      select
        creation_month,
        count(*)
      from
        topics
      group by
        creation_month
    )
    select
      months.month,
      topics_by_month.count
    from
      months
      left join topics_by_month on months.month = topics_by_month.creation_month
    order by
      months.month;
  EOQ
}

dashboard "oci_ons_notification_topic_dashboard" {

  title = "OCI ONS Notification Topic Dashboard"

  tags = merge(local.ons_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_ons_notification_topic_count.sql
      width = 2
    }

    card {
      sql   = query.oci_ons_notification_topic_unused_count.sql
      width = 2
    }
  }

  container {
    title = "Assessments"

    chart {
      title = "Lifecycle State"
      sql   = query.oci_ons_notification_topic_by_lifecycle_state.sql
      type  = "donut"
      width = 3

      series "count" {
        point "active" {
          color = "green"
        }
      }
    }

    chart {
      title = "No Active Subscription"
      sql   = query.oci_ons_notification_topic_by_subscription.sql
      type  = "donut"
      width = 3
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Topics by Tenancy"
      sql   = query.oci_ons_notification_topic_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Topics by Compartment"
      sql   = query.oci_ons_notification_topic_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Topics by Region"
      sql   = query.oci_ons_notification_topic_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Topics by Age"
      sql   = query.oci_ons_notification_topic_by_creation_month.sql
      type  = "column"
      width = 3
    }
  }

}
