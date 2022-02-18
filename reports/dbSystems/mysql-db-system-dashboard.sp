query "oci_mysql_db_system_count" {
  sql = <<-EOQ
  select 
    count(*) as "MySQL DB Systems" 
  from 
    oci_mysql_db_system 
  where 
    lifecycle_state <> 'DELETED'
  EOQ
}

query "oci_mysql_db_system_analytics_cluster_attached_count" {
  sql = <<-EOQ
   select
      count(*) as "Analytics Cluster Attached"
    from
      oci_mysql_db_system
    where
      is_analytics_cluster_attached and lifecycle_state <> 'DELETED'
  EOQ
}

query "oci_mysql_db_system_heat_wave_cluster_attached_count" {
  sql = <<-EOQ
   select
      count(*) as "Heat Wave Cluster Attached"
    from
      oci_mysql_db_system
    where
      is_heat_wave_cluster_attached and lifecycle_state <> 'DELETED'
  EOQ
}

query "oci_mysql_db_system_backup_disabled_count" {
  sql = <<-EOQ
   select
      count(v.*) as value,
      'Backups Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_mysql_db_system as v
    left join oci_mysql_backup as b on v.id = b.db_system_id
    where
      v.lifecycle_state <> 'DELETED'
    group by
      v.compartment_id,
      v.region,
      v.id
    having
      count(b.id) = 0
  EOQ
}

query "oci_mysql_db_system_inactive_lifecycle_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Inactive' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_mysql_db_system
    where
      lifecycle_state = 'INACTIVE'
  EOQ
}

query "oci_mysql_db_system_failed_lifecycle_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Failed' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_mysql_db_system
    where
      lifecycle_state = 'FAILED'
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
      region
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
      c.title as "compartment",
      count(d.*) as "MySQL DB Systems" 
    from 
      oci_mysql_db_system as d,
      compartments as c 
    where 
      c.id = d.compartment_id and lifecycle_state <> 'DELETED'
    group by 
      compartment
    order by 
      compartment
  EOQ
}

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
      lifecycle_state
  EOQ
}

query "oci_mysql_db_system_with_no_backups" {
  sql = <<-EOQ
    select
      v.display_name,
      v.compartment_id,
      v.region
    from
      oci_mysql_db_system as v
    left join oci_mysql_backup as b on v.id = b.db_system_id
    where
      v.lifecycle_state <> 'DELETED'
    group by
      v.compartment_id,
      v.region,
      v.display_name
    having
      count(b.id) = 0
  EOQ
}

query "oci_mysql_db_system_by_creation_month" {
  sql = <<-EOQ
    with mysql_dbSystems as (
      select
        display_name as name,
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
      timestamp
  EOQ
}

# underused if avg CPU < 10% every day for last month
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
      b.cpu_bucket
  EOQ
}

dashboard "oci_mysql_db_system_dashboard" {

  title = "OCI MySQL DB System Dashboard"

  container {
    card {
      sql = query.oci_mysql_db_system_count.sql
      width = 2
    }

    card {
      sql = query.oci_mysql_db_system_analytics_cluster_attached_count.sql
      width = 2
    }

    card {
      sql = query.oci_mysql_db_system_heat_wave_cluster_attached_count.sql
      width = 2
    }

    card {
      sql = query.oci_mysql_db_system_backup_disabled_count.sql
      width = 2
    } 

    card {
      sql = query.oci_mysql_db_system_inactive_lifecycle_count.sql
      width = 2
    }

    card {
      sql = query.oci_mysql_db_system_failed_lifecycle_count.sql
      width = 2
    } 
  }

  container {
      title = "Analysis"      

    chart {
      title = "MySQL DB Systems by Compartment"
      sql = query.oci_mysql_db_system_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "MySQL DB Systems by Region"
      sql = query.oci_mysql_db_system_by_region.sql
      type  = "column"
      width = 3
    }
  }

  container {
      title = "Assessments"
      
      chart {
        title = "Lifecycle State"
        sql = query.oci_mysql_db_system_by_lifecycle_state.sql
        type  = "donut"
        width = 3

      }

       table {
         title = "No Backups"
         sql = query.oci_mysql_db_system_with_no_backups.sql
         width = 3
       }
    }

   container {
    title = "Resources by Age" 
    width = 4
    chart {
      title = "MySQL DB Systems by Creation Month"
      sql = query.oci_mysql_db_system_by_creation_month.sql
      type  = "column"
      series "month" {
        color = "green"
      }
    }

    # table {
    #   title = "Oldest MySQL DB Systems"
    #   width = 4

    #   sql = <<-EOQ
    #     with compartments as ( 
    #       select
    #         id, title
    #       from
    #         oci_identity_tenancy
    #       union (
    #       select 
    #         id,title 
    #       from 
    #         oci_identity_compartment 
    #       where 
    #         lifecycle_state = 'ACTIVE'
    #       )  
    #    )
    #     select
    #       d.title as "MySQL DB Systems",
    #       current_date - d.time_created::date as "Age in Days",
    #       c.title as "Compartment"
    #     from
    #       oci_mysql_db_system as d
    #       left join compartments as c on c.id = d.compartment_id
    #     where 
    #       lifecycle_state <> 'DELETED'    
    #     order by
    #       "Age in Days" desc,
    #       d.title
    #     limit 5
    #   EOQ
    # }

    # table {
    #   title = "Newest MySQL DB Systems"
    #   width = 4

    #   sql = <<-EOQ
    #     with compartments as ( 
    #       select
    #         id, title
    #       from
    #         oci_identity_tenancy
    #       union (
    #       select 
    #         id,title 
    #       from 
    #         oci_identity_compartment 
    #       where 
    #         lifecycle_state = 'ACTIVE'
    #       )  
    #    )
    #     select
    #       d.title as "MySQL DB Systems",
    #       current_date - d.time_created::date as "Age in Days",
    #       c.title as "Compartment"
    #     from
    #       oci_mysql_db_system as d
    #       left join compartments as c on c.id = d.compartment_id
    #     where 
    #       lifecycle_state <> 'DELETED'    
    #     order by
    #       "Age in Days" asc,
    #       d.title
    #     limit 5
    #   EOQ
    # }

  }

  container {
    title  = "Performance & Utilization"
    width = 8

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
