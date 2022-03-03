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
    }

    chart {
      title = "Subscription Status"
      sql   = query.oci_ons_notification_topic_by_subscription.sql
      type  = "donut"
      width = 3

      series "count" {
        point "ACTIVE" {
          color = "ok"
        }
        point "NO_SUBSCRIPTION" {
          color = "alert"
        }
      }
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

# Card Queries

query "oci_ons_notification_topic_count" {
  sql = <<-EOQ
    select count(*) as "Topics" from oci_ons_notification_topic;
  EOQ
}

query "oci_ons_notification_topic_unused_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'No Subscription' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_ons_notification_topic t
      left join oci_ons_subscription s on t.topic_id = s.topic_id
    where
      s.id is null;
  EOQ
}

# Assessment Queries

query "oci_ons_notification_topic_by_lifecycle_state" {
  sql = <<-EOQ
     select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_ons_notification_topic
    group by
      lifecycle_state;
  EOQ
}

query "oci_ons_notification_topic_by_subscription" {
  sql = <<-EOQ
    select
      case when s.id is null then 'NO_SUBSCRIPTION' else s.lifecycle_state end as status,
      count(*)
    from
      oci_ons_notification_topic t
      left join oci_ons_subscription s on t.topic_id = s.topic_id
    group by
      status;
  EOQ
}

# Analysis Queries

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
      t.title as "Tenancy",
      case when t.title = c.title then 'root' else c.title end as "Compartment",
      count(n.*) as "Topics"
    from
      oci_ons_notification_topic as n,
      oci_identity_tenancy as t,
      compartments as c
    where
      c.id = n.compartment_id and n.tenant_id = t.id
    group by
      t.title,
      c.title
    order by
      t.title,
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
