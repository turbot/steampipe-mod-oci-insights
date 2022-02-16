query "oci_database_autonomous_database_count" {
  sql = <<-EOQ
    select count(*) as "Autonomous Database" from oci_database_autonomous_database where lifecycle_state <> 'TERMINATED'
  EOQ
}

# AVAILABLE, AVAILABLE_NEEDS_ATTENTION, BACKUP_IN_PROGRESS, MAINTENANCE_IN_PROGRESS, PROVISIONING, RESTORE_FAILED, RESTORE_IN_PROGRESS, SCALE_IN_PROGRESS, STARTING, STOPPED, STOPPING, TERMINATED, TERMINATING, UNAVAILABLE, UPDATING
query "oci_database_autonomous_database_need_attention_count" {
  sql = <<-EOQ
    select
      count(*) as  value,
      'DB Needs Attention State' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_database_autonomous_database
    where
      lifecycle_state = 'AVAILABLE_NEEDS_ATTENTION'
  EOQ
}

query "oci_database_autonomous_database_restore_failed_count" {
  sql = <<-EOQ
    select
      count(*) as  value,
      'DB Failed Restore State' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_database_autonomous_database
    where
      lifecycle_state = 'RESTORE_FAILED'
  EOQ
}

query "oci_database_autonomous_database_unavailable_count" {
  sql = <<-EOQ
    select
      count(*) as  value,
      'DB Not Available State' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_database_autonomous_database
    where
      lifecycle_state = 'UNAVAILABLE'
  EOQ
}

# cpu_core_count
query "oci_database_autonomous_db_total_cores" {
  sql = <<-EOQ
    select
      sum(cpu_core_count)  as "Total CPU Cores"
    from
      oci_database_autonomous_database
  EOQ
}

# cpu_core_count
query "oci_database_autonomous_db_total_size" {
  sql = <<-EOQ
    select
      sum(data_storage_size_in_gbs)  as "Total Size"
    from
      oci_database_autonomous_database
  EOQ
}

query "oci_database_autonomous_db_with_data_guard" {
  sql = <<-EOQ
    select count(*) as "DB With Data Guard Enabled" from oci_database_autonomous_database where is_data_guard_enabled
  EOQ
}

query "oci_database_autonomous_db_by_compartment" {
  sql = <<-EOQ
    select
      c.title as "compartment",
      count(a.*) as "total"
    from
      oci_database_autonomous_database as a,
      oci_identity_compartment as c
    where
      c.compartment_id = a.compartment_id and a.lifecycle_state <> 'DELETED'
    group by
      compartment
    order by count(a.*) desc
  EOQ
}

query "oci_database_autonomous_db_by_region" {
  sql = <<-EOQ
    select
      region,
      count(db.*) as total
    from
      oci_database_autonomous_database as db
    group by
      region
  EOQ
}

query "oci_database_autonomous_db_by_workload_type" {
  sql = <<-EOQ
    select
      db_workload as "Workload Type",
      count(*) as "instances"
    from
      oci_database_autonomous_database
      group by db_workload order by db_workload
  EOQ
}

# oci_database_autonomous_db_with_data_guard
query "oci_database_autonomous_db_data_guard_status" {
  sql = <<-EOQ
    with dataguard_stat as (
      select
        db_name as name
      from
        oci_database_autonomous_database
      where
        is_data_guard_enabled
      )
      select
        'Enabled' as "Data Guard Status",
        count(name) as "Total"
      from
        dataguard_stat
    union
    select
      'Disabled' as "Data Guard Status",
      count( db_name) as "Total"
    from
      oci_database_autonomous_database as s where s.db_name not in (select name from dataguard_stat);
  EOQ
}

# operations_insights_status
query "oci_database_autonomous_db_by_operations_insights_status_1" {
  sql = <<-EOQ
    select
      operations_insights_status,
      count(operations_insights_status)
    from
      oci_database_autonomous_database
    group by
      operations_insights_status
  EOQ
}

# Alternative operations_insights_status
query "oci_database_autonomous_db_by_operations_insights_status_2" {
  sql = <<-EOQ
    select
      insight_status,
      count(*)
    from (
      select operations_insights_status,
        case when operations_insights_status = 'NOT_ENABLED' then
          'Disabled'
        else
          'Enabled'
        end insight_status
      from
        oci_database_autonomous_database) as t
    group by
      insight_status
    order by
      insight_status desc
  EOQ
}

# permission_level RESTRICTED, UNRESTRICTED
# The Autonomous Database permission level. Restricted mode allows access only to admin users. Default UNRESTRICTED
query "oci_database_autonomous_db_by_permission_level" {
  sql = <<-EOQ
    select
      permission_status,
      count(*)
    from (
      select permission_level,
        case when permission_level = 'RESTRICTED' then
          'Restricted'
        else
          'Unrestricted'
        end permission_status
      from
        oci_database_autonomous_database) as t
    group by
      permission_status
    order by
      permission_status desc
  EOQ
}

query "oci_database_autonomous_db_by_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_database_autonomous_database
    group by
      lifecycle_state
  EOQ
}

query "oci_database_autonomous_db_by_creation_month" {
  sql = <<-EOQ
    with instances as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_database_autonomous_database
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
                from instances)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    instances_by_month as (
      select
        creation_month,
        count(*)
      from
        instances
      group by
        creation_month
    )
    select
      months.month,
      instances_by_month.count
    from
      months
      left join instances_by_month on months.month = instances_by_month.creation_month
    order by
      months.month desc;
  EOQ
}

# Note the CTE uses the dailt table to be efficient when filtering,
# and the hourly table to show granular line chart

query "oci_database_autonomous_db_top10_cpu_past_week" {
  sql = <<-EOQ
    with top_n as (
      select
        id,
        avg(average)
      from
        oci_database_autonomous_database_metric_cpu_utilization_daily
      where
        timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      group by
        id
      order by
        avg desc
      limit 10
  )
  select
    timestamp,
    id,
    average
    from
      oci_database_autonomous_database_metric_cpu_utilization_hourly
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      and id in (select id from top_n)
    order by
      timestamp
  EOQ
}

# underused if avg CPU < 10% every day for last month
query "oci_database_autonomous_db_by_cpu_utilization_category" {
  sql = <<-EOQ
    with cpu_buckets as (
      select
    unnest(array ['Unused (<1%)','Underutilized (1-10%)','Right-sized (10-90%)', 'Overutilized (>90%)' ]) as cpu_bucket
    ),
    max_averages as (
      select
        id,
        case
          when max(average) <= 1 then 'Unused (<1%)'
          when max(average) between 1 and 10 then 'Underutilized (1-10%)'
          when max(average) between 10 and 90 then 'Right-sized (10-90%)'
          when max(average) > 90 then 'Overutilized (>90%)'
        end as cpu_bucket,
        max(average) as max_avg
      from
        oci_database_autonomous_database_metric_cpu_utilization_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        id
    )
    select
      b.cpu_bucket as "CPU Utilization",
      count(a.*)
    from
      cpu_buckets as b
    left join max_averages as a on b.cpu_bucket = a.cpu_bucket
    group by
      b.cpu_bucket
  EOQ
}

report "oci_database_autonomous_db_summary" {

  title = "OCI Autonomous Database Dashboard"

  container {

    card {
      sql   = query.oci_database_autonomous_database_count.sql
      width = 2
    }

    card {
      sql   = query.oci_database_autonomous_db_total_cores.sql
      width = 2
    }

    card {
      sql   = query.oci_database_autonomous_db_total_size.sql
      width = 2
    }

    card {
      sql   = query.oci_database_autonomous_database_need_attention_count.sql
      width = 2
    }
    card {
      sql   = query.oci_database_autonomous_database_restore_failed_count.sql
      width = 2
    }

    card {
      sql   = query.oci_database_autonomous_database_unavailable_count.sql
      width = 2
    }

    card {
      sql   = query.oci_database_autonomous_db_with_data_guard.sql
      width = 2
    }
  }


  container {
    title = "Analysis"

    chart {
      title = "Autonomous Databases by Compartment"
      sql   = query.oci_database_autonomous_db_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Autonomous Databases by Region"
      sql   = query.oci_database_autonomous_db_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Autonomous Database by Lifecycle State"
      sql   = query.oci_database_autonomous_db_by_state.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Autonomous Database by Workload Type"
      sql   = query.oci_database_autonomous_db_by_workload_type.sql
      type  = "column"
      width = 3
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Data Guard Status"
      sql   = query.oci_database_autonomous_db_data_guard_status.sql
      type  = "donut"
      width = 3

    }
    chart {
      title = "Operations Insight Status1"
      sql   = query.oci_database_autonomous_db_by_operations_insights_status_1.sql
      type  = "donut"
      width = 3
    }

    chart {
      title = "Operations Insight Status2"
      sql   = query.oci_database_autonomous_db_by_operations_insights_status_2.sql
      type  = "donut"
      width = 3

      series "Enabled" {
        color = "green"
      }
    }

    chart {
      title = "Permission Level Status"
      sql   = query.oci_database_autonomous_db_by_permission_level.sql
      type  = "donut"
      width = 3

      series "Restricted" {
        color = "green"
      }
    }
  }

  container {
    title = "Performance & Utilization"

    chart {
      title = "Top 10 CPU - Last 7 days [ needs to be a crosstab?]"
      sql   = query.oci_database_autonomous_db_top10_cpu_past_week.sql
      type  = "line"
      width = 6
    }

    chart {
      title = "Average max daily CPU - Last 30 days"
      sql   = query.oci_database_autonomous_db_by_cpu_utilization_category.sql
      type  = "column"
      width = 6

      # 'Unused (<1%)','Underutilized (1-10%)','Right-sized (10-90%)', 'Overutilized (>90%)'
      # series {
      #   color = "yellow"
      # }
    }

  }

  container {
    title = "Resources by Age"

    chart {
      title = "Autonomous Database by Creation Month"
      sql   = query.oci_database_autonomous_db_by_creation_month.sql
      type  = "column"
      width = 4

      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest Autonomous Databases"
      width = 4

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
          d.title as "instance",
          current_date - d.time_created::date as "Age in Days",
          c.title as "Compartment"
        from
          oci_database_autonomous_database as d
          left join compartments as c on c.id = d.compartment_id
        where
          lifecycle_state <> 'TERMINATED'
        order by
          "Age in Days" desc,
          d.title
        limit 5
      EOQ
    }

    table {
      title = "Newest Autonomous Databases"
      width = 4

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
          d.title as "instance",
          current_date - d.time_created::date as "Age in Days",
          c.title as "Compartment"
        from
          oci_database_autonomous_database as d
          left join compartments as c on c.id = d.compartment_id
        where
          lifecycle_state <> 'TERMINATED'
        order by
          "Age in Days" asc,
          d.title
        limit 5
      EOQ
    }
  }
}

