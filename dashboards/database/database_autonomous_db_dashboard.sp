dashboard "oci_database_autonomous_db_dashboard" {

  title = "OCI Database Autonomous DB Dashboard"

  tags = merge(local.database_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_database_autonomous_db_count.sql
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
      sql   = query.oci_database_autonomous_db_with_data_guard_count.sql
      width = 2
    }

    card {
      sql   = query.oci_database_autonomous_db_by_operations_insights_count.sql
      width = 2
    }
  }

  container {

    title = "Assessments"

    chart {
      title = "Data Guard Status"
      sql   = query.oci_database_autonomous_db_data_guard_status.sql
      type  = "donut"
      width = 3

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Operations Insight Status"
      sql   = query.oci_database_autonomous_db_by_operations_insights_status.sql
      type  = "donut"
      width = 3

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }
  }

  container {
    title = "Analysis"

    chart {
      title = "Autonomous Databases by Tenancy"
      sql   = query.oci_database_autonomous_db_by_tenancy.sql
      type  = "column"
      width = 3
    }

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
      title = "Autonomous Databases by Age"
      sql   = query.oci_database_autonomous_db_by_creation_month.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Autonomous Databases by Workload Type"
      sql   = query.oci_database_autonomous_db_by_workload_type.sql
      type  = "column"
      width = 3
    }

  }

  container {
    title = "Performance & Utilization"

    chart {
      title = "Top 10 Average CPU - Last 7 days"
      type  = "line"
      width = 6
      sql   = query.oci_database_autonomous_db_by_cpu_utilization.sql
    }

    chart {
      title = "Top 10 Average Storage - Last 7 days"
      type  = "line"
      width = 6
      sql   = query.oci_database_autonomous_db_by_storage_utilization.sql
    }
  }

}

# Card Queries

query "oci_database_autonomous_db_count" {
  sql = <<-EOQ
    select count(*) as "Autonomous DBs" from oci_database_autonomous_database where lifecycle_state <> 'TERMINATED';
  EOQ
}

query "oci_database_autonomous_db_total_cores" {
  sql = <<-EOQ
    select
      sum(cpu_core_count) as "Total OCPUs"
    from
      oci_database_autonomous_database;
  EOQ
}

query "oci_database_autonomous_db_total_size" {
  sql = <<-EOQ
    select
      sum(data_storage_size_in_gbs) as "Total Size (GB)"
    from
      oci_database_autonomous_database;
  EOQ
}

query "oci_database_autonomous_db_with_data_guard_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Data Guard Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_database_autonomous_database
    where
      not is_data_guard_enabled;
  EOQ
}

query "oci_database_autonomous_db_by_operations_insights_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Operations Insight Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_database_autonomous_database
    where
      operations_insights_status = 'NOT_ENABLED';
  EOQ
}

# Assessment Queries

query "oci_database_autonomous_db_data_guard_status" {
  sql = <<-EOQ
    with dataguard_stat as (
      select
        case
          when is_data_guard_enabled then 'enabled'
          else 'disabled'
        end as dataguard_stat
      from
        oci_database_autonomous_database
      )
  select
    dataguard_stat,
    count(*)
  from
    dataguard_stat
    group by dataguard_stat
  EOQ
}

query "oci_database_autonomous_db_by_operations_insights_status" {
  sql = <<-EOQ
    select
      insight_status,
      count(*)
    from (
      select operations_insights_status,
        case when operations_insights_status = 'NOT_ENABLED' then
          'disabled'
        else
          'enabled'
        end insight_status
      from
        oci_database_autonomous_database) as t
    group by
      insight_status
    order by
      insight_status desc;
  EOQ
}

# Analysis Queries

query "oci_database_autonomous_db_by_tenancy" {
  sql = <<-EOQ
    select
       t.name as "Tenancy",
       count(a.id)::numeric as "Autonomous DBs"
    from
      oci_database_autonomous_database as a,
      oci_identity_tenancy as t
    where
      t.id = a.tenant_id
    group by
      t.name
    order by
      t.name;
  EOQ
}

query "oci_database_autonomous_db_by_compartment" {
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
      count(a.*) as "Autonomous DBs"
    from
      oci_database_autonomous_database as a,
      oci_identity_tenancy as t,
      compartments as c
    where
      c.id = a.compartment_id and a.tenant_id = t.id
    group by
      t.title,
      c.title
    order by
      t.title,
      c.title;
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
      region;
  EOQ
}

query "oci_database_autonomous_db_by_creation_month" {
  sql = <<-EOQ
    with databases as (
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
                from databases)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    databases_by_month as (
      select
        creation_month,
        count(*)
      from
        databases
      group by
        creation_month
    )
    select
      months.month,
      databases_by_month.count
    from
      months
      left join databases_by_month on months.month = databases_by_month.creation_month
    order by
      months.month desc;
  EOQ
}

query "oci_database_autonomous_db_by_workload_type" {
  sql = <<-EOQ
    select
      db_workload as "Workload Type",
      count(*) as "databases"
    from
      oci_database_autonomous_database
      group by db_workload order by db_workload;
  EOQ
}

# Performance & Utilization Queries

query "oci_database_autonomous_db_by_cpu_utilization" {
  sql = <<-EOQ
    with top_n as (
      select
        id,
        avg(average)
      from
        oci_database_autonomous_db_metric_cpu_utilization_daily
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
      oci_database_autonomous_db_metric_cpu_utilization_hourly
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      and id in (select id from top_n);
  EOQ
}

query "oci_database_autonomous_db_by_storage_utilization" {
  sql = <<-EOQ
    with top_n as (
      select
        id,
        avg(average)
      from
        oci_database_autonomous_db_metric_storage_utilization_daily
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
      oci_database_autonomous_db_metric_storage_utilization_hourly
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      and id in (select id from top_n);
  EOQ
}
