dashboard "oci_ons_notification_topic_dashboard" {

  title         = "OCI ONS Notification Topic Dashboard"
  documentation = file("./dashboards/ons/docs/ons_notification_topic_dashboard.md")

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
      title = "Subscriptions Status"
      sql   = query.oci_ons_notification_topic_by_subscription.sql
      type  = "donut"
      width = 4

      series "count" {
        point "with subscriptions" {
          color = "ok"
        }
        point "no subscriptions" {
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
      'No Subscriptions' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_ons_notification_topic t
      left join oci_ons_subscription s on t.topic_id = s.topic_id
    where
      s.id is null;
  EOQ
}

# Assessment Queries

query "oci_ons_notification_topic_by_subscription" {
  sql = <<-EOQ
    select
      case when s.id is null then 'no subscriptions' else 'with subscriptions' end as status,
      count(distinct t.topic_id)
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
        id,
        'root [' || title || ']' as title
      from
        oci_identity_tenancy
      union (
      select
        c.id,
        c.title || ' [' || t.title || ']' as title
      from
        oci_identity_compartment c,
        oci_identity_tenancy t
      where
        c.tenant_id = t.id and c.lifecycle_state = 'ACTIVE'
      )
    )
    select
      c.title as "Title",
      count(t.*) as "Topics"
    from
      oci_ons_notification_topic as t,
      compartments as c
    where
      c.id = t.compartment_id
    group by
      c.title
    order by
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
