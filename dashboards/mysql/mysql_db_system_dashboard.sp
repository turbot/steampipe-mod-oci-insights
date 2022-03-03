dashboard "oci_mysql_db_system_dashboard" {

  title = "OCI MySQL DB System Dashboard"

  tags = merge(local.mysql_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_mysql_db_system_count.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_db_system_storage_total.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_db_system_analytics_cluster_attached_count.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_db_system_heat_wave_cluster_attached_count.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_db_system_failed_lifecycle_count.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_db_system_backup_disabled_count.sql
      width = 2
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Lifecycle State"
      sql   = query.oci_mysql_db_system_by_lifecycle_state.sql
      type  = "donut"
      width = 3

      series "count" {
        point "ACTIVE" {
          color = "ok"
        }
        point "FAILED" {
          color = "alert"
        }
      }

    }

    chart {
      title = "Backup Status"
      sql   = query.oci_mysql_db_system_with_backups.sql
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
      title = "DB Systems by Tenancy"
      sql   = query.oci_mysql_db_system_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "DB Systems by Compartment"
      sql   = query.oci_mysql_db_system_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "DB Systems by Region"
      sql   = query.oci_mysql_db_system_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "DB Systems by Age"
      sql   = query.oci_mysql_db_system_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

  container {
    chart {
      title = "Storage by Tenancy (GB)"
      sql   = query.oci_mysql_db_system_storage_by_tenancy.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Compartment (GB)"
      sql   = query.oci_mysql_db_system_storage_by_compartment.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Region (GB)"
      sql   = query.oci_mysql_db_system_storage_by_region.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Age (GB)"
      sql   = query.oci_mysql_db_system_storage_by_creation_month.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

  }

  container {
    title = "Performance & Utilization"

    chart {
      title = "Top 10 CPU - Last 7 days"
      sql   = query.oci_mysql_db_system_top10_cpu_past_week.sql
      type  = "line"
      width = 6
    }

    chart {
      title = "Average max daily CPU - Last 30 days"
      sql   = query.oci_mysql_db_system_by_cpu_utilization_category.sql
      type  = "column"
      width = 6
    }

  }

}

# Card Queries

query "oci_mysql_db_system_count" {
  sql = <<-EOQ
  select
    count(*) as "DB Systems"
  from
    oci_mysql_db_system
  where
    lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_mysql_db_system_storage_total" {
  sql = <<-EOQ
    select
      sum(data_storage_size_in_gbs) as "Total Storage (GB)"
    from
      oci_mysql_db_system
    where
      lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_mysql_db_system_analytics_cluster_attached_count" {
  sql = <<-EOQ
   select
      count(*) as "Analytics Cluster Attached"
    from
      oci_mysql_db_system
    where
      is_analytics_cluster_attached and lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_mysql_db_system_heat_wave_cluster_attached_count" {
  sql = <<-EOQ
   select
      count(*) as "Heat Wave Cluster Attached"
    from
      oci_mysql_db_system
    where
      is_heat_wave_cluster_attached and lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_mysql_db_system_failed_lifecycle_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Failed' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_mysql_db_system
    where
      lifecycle_state = 'FAILED';
  EOQ
}

query "oci_mysql_db_system_backup_disabled_count" {
  sql = <<-EOQ
   select
      count(s.*) as value,
      'Backups Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_mysql_db_system as s
    left join oci_mysql_backup as b on s.id = b.db_system_id
    where
      b.id is null and s.lifecycle_state <> 'DELETED';
  EOQ
}

# Assessment Queries

query "oci_mysql_db_system_by_lifecycle_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_mysql_db_system
    where
      lifecycle_state <> 'DELETED'
    group by
      lifecycle_state;
  EOQ
}

query "oci_mysql_db_system_with_backups" {
  sql = <<-EOQ
    select
      case when b.id is null then 'disabled' else 'enabled' end as status,
      count(*)
    from
      oci_mysql_db_system as s
      left join oci_mysql_backup as b on s.id = b.db_system_id
    where
      s.lifecycle_state <> 'DELETED'
    group by
      status;
  EOQ
}

# Analysis Queries

query "oci_mysql_db_system_by_tenancy" {
  sql = <<-EOQ
    select
      t.title as "Tenancy",
      count(d.*) as "DB Systems"
    from
      oci_mysql_db_system as d,
      oci_identity_tenancy as t
    where
      t.id = d.tenant_id and lifecycle_state <> 'DELETED'
    group by
      t.title
    order by
      t.title;
  EOQ
}

query "oci_mysql_db_system_by_compartment" {
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
      count(a.*) as "Db Systems"
    from
      oci_mysql_db_system as a,
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

query "oci_mysql_db_system_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "MySQL DB Systems"
    from
      oci_mysql_db_system
    where
      lifecycle_state <> 'DELETED'
    group by
      region
    order by
      region;
  EOQ
}

query "oci_mysql_db_system_by_creation_month" {
  sql = <<-EOQ
    with mysql_dbSystems as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_mysql_db_system
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
                from mysql_dbSystems)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    mysql_dbSystems_by_month as (
      select
        creation_month,
        count(*)
      from
        mysql_dbSystems
      group by
        creation_month
    )
    select
      months.month,
      mysql_dbSystems_by_month.count
    from
      months
      left join mysql_dbSystems_by_month on months.month = mysql_dbSystems_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "oci_mysql_db_system_storage_by_tenancy" {
  sql = <<-EOQ
    select
      t.title as "Tenancy",
      sum(data_storage_size_in_gbs) as "GB"
    from
      oci_mysql_db_system as d,
      oci_identity_tenancy as t
    where
      t.id = d.tenant_id and lifecycle_state <> 'DELETED'
    group by
      t.title
    order by
      t.title;
  EOQ
}

query "oci_mysql_db_system_storage_by_compartment" {
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
        lifecycle_state <> 'DELETED'
        )
      )
    select
      b.title as "Tenancy",
      case when b.title = c.title then 'root' else c.title end as "Compartment",
      sum(a.data_storage_size_in_gbs) as "GB"
    from
      oci_mysql_db_system as a,
      oci_identity_tenancy as b,
      compartments as c
    where
      c.id = a.compartment_id and a.tenant_id = b.id and a.lifecycle_state <> 'DELETED'
    group by
      b.title,
      c.title
    order by
      b.title,
      c.title;
  EOQ
}

query "oci_mysql_db_system_storage_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      sum(data_storage_size_in_gbs) as "GB"
    from
      oci_mysql_db_system
    where
      lifecycle_state <> 'DELETED'
    group by
      region
    order by
      region;
  EOQ
}

query "oci_mysql_db_system_storage_by_creation_month" {
  sql = <<-EOQ
    with mysql_dbSystems as (
      select
        title,
        data_storage_size_in_gbs,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_mysql_db_system
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
                from mysql_dbSystems)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    mysql_dbSystems_by_month as (
      select
        creation_month,
        sum(data_storage_size_in_gbs) as size
      from
        mysql_dbSystems
      group by
        creation_month
    )
    select
      months.month,
      mysql_dbSystems_by_month.size as "GB"
    from
      months
      left join mysql_dbSystems_by_month on months.month = mysql_dbSystems_by_month.creation_month
    order by
      months.month;
  EOQ
}

# Performance & Utilization Queries

query "oci_mysql_db_system_top10_cpu_past_week" {
  sql = <<-EOQ
     with top_n as (
      select
        id,
        avg(average)
      from
        oci_mysql_db_system_metric_cpu_utilization_daily
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
      oci_mysql_db_system_metric_cpu_utilization_hourly
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      and id in (select id from top_n)
    order by
      timestamp;
  EOQ
}

# Underused if avg CPU < 10% every day for last month

query "oci_mysql_db_system_by_cpu_utilization_category" {
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
        oci_mysql_db_system_metric_cpu_utilization_daily
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
      b.cpu_bucket;
  EOQ
}

