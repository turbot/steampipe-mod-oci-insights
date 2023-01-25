dashboard "nosql_table_dashboard" {

  title         = "OCI NoSQL Table Dashboard"
  documentation = file("./dashboards/nosql/docs/nosql_table_dashboard.md")

  tags = merge(local.nosql_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.nosql_table_count.sql
      width = 3
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Tables by Tenancy"
      sql   = query.nosql_table_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Tables by Compartment"
      sql   = query.nosql_table_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Tables by Region"
      sql   = query.nosql_table_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Tables by Age"
      sql   = query.nosql_table_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

  # container {
  #   title = "Performance & Utilization"

  #   chart {
  #     title = "Top 10 Storage - Last 7 days"
  #     sql   = query.nosql_table_top10_storage_past_week.sql
  #     type  = "line"
  #     width = 6
  #   }

  #   chart {
  #     title = "Average Max Daily Storage - Last 30 days"
  #     sql   = query.nosql_table_by_storage_utilization_category.sql
  #     type  = "column"
  #     width = 6
  #   }

  # }

  container {
    title = "Performance & Utilization"

    chart {
      title = "Top 10 Average Read Throttle Count - Last 7 days"
      query   = query.nosql_table_top_10_read_throttle_count_avg
      type  = "line"
      width = 6
    }

    chart {
      title = "Top 10 Average Write Throttle Count - Last 7 days"
      query   = query.nosql_table_top_10_write_throttle_count_avg
      type  = "column"
      width = 6
    }

  }

}

# Card Queries

query "nosql_table_count" {
  sql = <<-EOQ
  select
    count(*) as "Tables"
  from
    oci_nosql_table
  where
    lifecycle_state <> 'DELETED';
  EOQ
}

# Analysis Queries

query "nosql_table_by_tenancy" {
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

query "nosql_table_by_region" {
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

query "nosql_table_by_compartment" {
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
      count(n.*) as "NoSQL Tables"
    from
      oci_nosql_table as n,
      compartments as c
    where
      c.id = n.compartment_id and n.lifecycle_state <> 'DELETED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "nosql_table_by_creation_month" {
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

# Performance Queries

# query "nosql_table_top10_storage_past_week" {
#   sql = <<-EOQ
#      with top_n as (
#       select
#         name,
#         avg(average)
#       from
#         oci_nosql_table_metric_storage_utilization_daily
#       where
#         timestamp  >= CURRENT_DATE - INTERVAL '7 day'
#       group by
#         name
#       order by
#         avg desc
#       limit 10
#     )
#     select
#       timestamp,
#       name,
#       average
#     from
#       oci_nosql_table_metric_storage_utilization_hourly
#     where
#       timestamp  >= CURRENT_DATE - INTERVAL '7 day'
#       and name in (select name from top_n)
#     order by
#       timestamp;
#   EOQ
# }

# query "nosql_table_by_storage_utilization_category" {
#   sql = <<-EOQ
#     with storage_buckets as (
#       select
#     unnest(array ['Unused (<1%)','Underutilized (1-10%)','Right-sized (10-90%)', 'Overutilized (>90%)' ]) as storage_bucket
#     ),
#     max_averages as (
#       select
#         name,
#         case
#           when max(average) <= 1 then 'Unused (<1%)'
#           when max(average) between 1 and 10 then 'Underutilized (1-10%)'
#           when max(average) between 10 and 90 then 'Right-sized (10-90%)'
#           when max(average) > 90 then 'Overutilized (>90%)'
#         end as storage_bucket,
#         max(average) as max_avg
#       from
#         oci_nosql_table_metric_storage_utilization_daily
#       where
#         date_part('day', now() - timestamp) <= 30
#       group by
#         name
#     )
#     select
#       b.storage_bucket as "storage Utilization",
#       count(a.*)
#     from
#       storage_buckets as b
#     left join max_averages as a on b.storage_bucket = a.storage_bucket
#     group by
#       b.storage_bucket;
#   EOQ
# }

query "nosql_table_top_10_read_throttle_count_avg" {
  sql = <<-EOQ
    with top_n as (
      select
        name,
        avg(average)
      from
        oci_nosql_table_metric_read_throttle_count_daily
      where
        timestamp >= CURRENT_DATE - INTERVAL '7 day'
      group by
        name
      order by
        avg desc
      limit
        10
    )
    select
      timestamp,
      name,
      average
    from
      oci_nosql_table_metric_read_throttle_count_hourly
    where
      timestamp >= CURRENT_DATE - INTERVAL '7 day'
      and name in (
        select
          name
        from top_n);
  EOQ
}

query "nosql_table_top_10_write_throttle_count_avg" {
  sql = <<-EOQ
    with top_n as (
      select
        name,
        avg(average)
      from
        oci_nosql_table_metric_write_throttle_count_daily
      where
        timestamp >= CURRENT_DATE - INTERVAL '7 day'
      group by
        name
      order by
        avg desc
      limit
        10
    )
    select
      timestamp,
      name,
      average
    from
      oci_nosql_table_metric_write_throttle_count_hourly
    where
      timestamp >= CURRENT_DATE - INTERVAL '7 day'
      and name in (
        select
          name
        from top_n);
  EOQ
}
