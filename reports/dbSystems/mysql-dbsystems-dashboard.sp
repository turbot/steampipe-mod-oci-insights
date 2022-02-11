# Added to report
query "oci_mysql_db_system_count" {
  sql = <<-EOQ
    select count(*) as "MySQL DB Systems" from oci_mysql_db_system
  EOQ
}

# Added to report
query "oci_mysql_db_system_analytics_cluster_attached_count" {
  sql = <<-EOQ
   select
      count(*) as "Analytics Cluster Attached"
    from
      oci_mysql_db_system
    where
      is_analytics_cluster_attached  
  EOQ
}

# Added to report
query "oci_mysql_db_system_heat_wave_cluster_attached_count" {
  sql = <<-EOQ
   select
      count(*) as "Heat Wave Cluster Attached"
    from
      oci_mysql_db_system
    where
      is_heat_wave_cluster_attached  
  EOQ
}

# Added to report
query "oci_mysql_db_system_automatic_backup_disabled_count" {
  sql = <<-EOQ
   select
      count(*) as "Automatic Backup Disabled"
    from
      oci_mysql_db_system
    where
      backup_policy ->> 'isEnabled' = 'false'
  EOQ
}

# Added to report
query "oci_mysql_db_system_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "MySQL DB Systems" 
    from 
      oci_mysql_db_system 
    group by 
      region 
    order by 
      region
  EOQ
}

# Added to report
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
      where lifecycle_state = 'ACTIVE')  
    )
   select 
      c.title as "compartment",
      count(d.*) as "MySQL DB Systems" 
    from 
      oci_mysql_db_system as d,
      compartments as c 
    where 
      c.id = d.compartment_id
    group by 
      compartment
    order by 
      compartment
  EOQ
}

#Added to report
query "oci_mysql_db_system_by_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_mysql_db_system
    group by
      lifecycle_state
  EOQ
}

#Added to report
query "oci_mysql_db_system_with_no_backups" {
  sql = <<-EOQ
    select
      v.id,
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
      v.id
    having
      count(b.id) = 0
  EOQ
}

# Added
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

report "oci_mysql_db_system_dashboard" {

  title = "OCI MySQL DB Systems Dashboard"

  container {
    ## Analysis ...

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
      sql = query.oci_mysql_db_system_automatic_backup_disabled_count.sql
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

    # donut charts in a 2 x 2 layout
    container {
      title = "Assessments"

      chart {
        title = "MySQL DB Systems State"
        sql = query.oci_mysql_db_system_by_state.sql
        type  = "donut"
        width = 3

      }

       table {
         title = "MySQL DB Systems with no backups"
         sql = query.oci_mysql_db_system_with_no_backups.sql
         width = 3
       }
    }

  container {
    title = "Resources by Age" 

    chart {
      title = "MySQL DB Systems by Creation Month"
      sql = query.oci_mysql_db_system_by_creation_month.sql
      type  = "column"
      width = 4
      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest MySQL DB Systems"
      width = 4

      sql = <<-EOQ
        select
          title as "MySQL DB Systems",
          current_date - time_created::date as "Age in Days",
          compartment_id as "Compartment"
        from
          oci_mysql_db_system
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }

    table {
      title = "Newest MySQL DB Systems"
      width = 4

      sql = <<-EOQ
        select
          title as "MySQL DB Systems",
          current_date - time_created::date as "Age in Days",
          compartment_id as "Compartment"
        from
          oci_mysql_db_system
        order by
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }

  }

}