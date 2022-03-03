dashboard "oci_nosql_table_dashboard" {

  title = "OCI NoSQL Table Dashboard"

  tags = merge(local.nosql_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_nosql_table_count.sql
      width = 2
    }

    card {
      sql   = query.oci_nosql_table_auto_reclaimable_count.sql
      width = 2
    }

    card {
      sql   = query.oci_nosql_table_stalled_more_than_90_days_count.sql
      width = 2
    }
  }

  container {
    title = "Assessments"

    chart {
      title = "Lifecycle State"
      sql   = query.oci_nosql_table_by_lifecycle_state.sql
      type  = "donut"
      width = 3
    }

    chart {
      title = "Stalled More Than 90 Days"
      sql   = query.oci_nosql_table_stalled_more_than_90_days.sql
      type  = "donut"
      width = 3
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Tables by Tenancy"
      sql   = query.oci_nosql_table_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Tables by Compartment"
      sql   = query.oci_nosql_table_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Tables by Region"
      sql   = query.oci_nosql_table_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Tables by Age"
      sql   = query.oci_nosql_table_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

  container {
    title = "Performance & Utilization"

    chart {
      title = "Top 10 Storage - Last 7 days"
      sql   = query.oci_nosql_table_top10_storage_past_week.sql
      type  = "line"
      width = 6
    }

    chart {
      title = "Average Max Daily Storage - Last 30 days"
      sql   = query.oci_nosql_table_by_storage_utilization_category.sql
      type  = "column"
      width = 6
    }

  }

}

# Card Queries

query "oci_nosql_table_count" {
  sql = <<-EOQ
  select
    count(*) as "NoSQL Tables"
  from
    oci_nosql_table
  where
    lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_nosql_table_auto_reclaimable_count" {
  sql = <<-EOQ
   select
      count(*) as "Auto Reclaimable Tables"
    from
      oci_nosql_table
    where
      is_auto_reclaimable and lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_nosql_table_stalled_more_than_90_days_count" {
  sql = <<-EOQ
   select
      count(*) as value,
      'Stalled > 90 Days' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_nosql_table
    where
      date_part('day', now()-(time_updated::timestamptz)) > 90 and lifecycle_state <> 'DELETED';
  EOQ
}

# Assessment Queries

query "oci_nosql_table_by_lifecycle_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_nosql_table
    where
      lifecycle_state <> 'DELETED'
    group by
      lifecycle_state;
  EOQ
}

query "oci_nosql_table_stalled_more_than_90_days" {
  sql = <<-EOQ
    select
      name,
      count(name)
    from
      oci_nosql_table
    where
      date_part('day', now()-(time_updated::timestamptz)) > 90
      and lifecycle_state <> 'DELETED'
    group by
      name;
  EOQ
}

# Analysis Queries

query "oci_nosql_table_by_tenancy" {
  sql = <<-EOQ
    select
      c.title as "Tenancy",
      count(t.*) as "NoSQL Tables"
    from
      oci_nosql_table as t,
      oci_identity_tenancy as c
    where
      c.id = t.tenant_id and lifecycle_state <> 'DELETED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_nosql_table_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "NoSQL Tables"
    from
      oci_nosql_table
    where
      lifecycle_state <> 'DELETED'
    group by
      region
    order by
      region;
  EOQ
}

query "oci_nosql_table_by_compartment" {
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
      count(a.*) as "NoSQL Tables"
    from
      oci_nosql_table as a,
      oci_identity_tenancy as b,
      compartments as c
    where
      c.id = a.compartment_id and a.tenant_id = b.id and lifecycle_state <> 'DELETED'
    group by
      b.title,
      c.title
    order by
      b.title,
      c.title;
  EOQ
}

query "oci_nosql_table_by_creation_month" {
  sql = <<-EOQ
    with nosql as (
      select
        name,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_nosql_table
      where
      lifecycle_state <> 'DELETED'
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
                from nosql)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    nosql_by_month as (
      select
        creation_month,
        count(*)
      from
        nosql
      group by
        creation_month
    )
    select
      months.month,
      nosql_by_month.count
    from
      months
      left join nosql_by_month on months.month = nosql_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "oci_nosql_table_top10_storage_past_week" {
  sql = <<-EOQ
     with top_n as (
      select
        name,
        avg(average)
      from
        oci_nosql_table_metric_storage_utilization_daily
      where
        timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      group by
        name
      order by
        avg desc
      limit 10
    )
    select
      timestamp,
      name,
      average
    from
      oci_nosql_table_metric_storage_utilization_hourly
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      and name in (select name from top_n)
    order by
      timestamp;
  EOQ
}

query "oci_nosql_table_by_storage_utilization_category" {
  sql = <<-EOQ
    with storage_buckets as (
      select
    unnest(array ['Unused (<1%)','Underutilized (1-10%)','Right-sized (10-90%)', 'Overutilized (>90%)' ]) as storage_bucket
    ),
    max_averages as (
      select
        name,
        case
          when max(average) <= 1 then 'Unused (<1%)'
          when max(average) between 1 and 10 then 'Underutilized (1-10%)'
          when max(average) between 10 and 90 then 'Right-sized (10-90%)'
          when max(average) > 90 then 'Overutilized (>90%)'
        end as storage_bucket,
        max(average) as max_avg
      from
        oci_nosql_table_metric_storage_utilization_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        name
    )
    select
      b.storage_bucket as "storage Utilization",
      count(a.*)
    from
      storage_buckets as b
    left join max_averages as a on b.storage_bucket = a.storage_bucket
    group by
      b.storage_bucket;
  EOQ
}
