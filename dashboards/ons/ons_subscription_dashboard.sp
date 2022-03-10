dashboard "oci_ons_subscription_dashboard" {

  title         = "OCI ONS Subscription Dashboard"
  documentation = file("./dashboards/ons/docs/ons_subscription_dashboard.md")

  tags = merge(local.ons_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_ons_subscription_count.sql
      width = 2
    }

    card {
      sql   = query.oci_ons_subscription_unused_count.sql
      width = 2
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Subscriptions by Tenancy"
      sql   = query.oci_ons_subscription_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subscriptions by Compartment"
      sql   = query.oci_ons_subscription_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subscriptions by Region"
      sql   = query.oci_ons_subscription_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subscriptions by Age"
      sql   = query.oci_ons_subscription_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "oci_ons_subscription_count" {
  sql = <<-EOQ
    select count(*) as "Subscriptions" from oci_ons_subscription;
  EOQ
}

query "oci_ons_subscription_unused_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Pending' as label
    from
      oci_ons_subscription
    where
      lifecycle_state <> 'ACTIVE';
  EOQ
}

# Assessment Queries

query "oci_ons_subscription_by_lifecycle_state" {
  sql = <<-EOQ
    select
      case when lifecycle_state = 'PENDING' then 'unused' else 'in_use' end as status,
      count(lifecycle_state)
    from
      oci_ons_subscription
    where
      lifecycle_state <> 'DELETED'
    group by
      status;
  EOQ
}

# Analysis Queries

query "oci_ons_subscription_by_tenancy" {
  sql = <<-EOQ
    select
       t.name as "Tenancy",
       count(s.id)::numeric as "Subscriptions"
    from
      oci_ons_subscription as s,
      oci_identity_tenancy as t
    where
      t.id = s.tenant_id
    group by
      t.name
    order by
      t.name;
  EOQ
}

query "oci_ons_subscription_by_compartment" {
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
      count(s.*) as "Subscriptions"
    from
      oci_ons_subscription as s,
      compartments as c
    where
      c.id = s.compartment_id
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_ons_subscription_by_region" {
  sql = <<-EOQ
    select
    region as "Region",
    count(*) as "Subscriptions"
    from
      oci_ons_subscription
    group by
      region
    order by
      region
  EOQ
}

query "oci_ons_subscription_by_creation_month" {
  sql = <<-EOQ
    with subscriptions as (
      select
        id,
        created_time,
        to_char(created_time,
          'YYYY-MM') as creation_month
      from
        oci_ons_subscription
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created_time)
                from subscriptions)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    subscriptions_by_month as (
      select
        creation_month,
        count(*)
      from
        subscriptions
      group by
        creation_month
    )
    select
      months.month,
      subscriptions_by_month.count
    from
      months
      left join subscriptions_by_month on months.month = subscriptions_by_month.creation_month
    order by
      months.month;
  EOQ
}
