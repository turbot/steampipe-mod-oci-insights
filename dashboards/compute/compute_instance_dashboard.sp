query "oci_compute_instance_count" {
  sql = <<-EOQ
    select count(*) as "Instances" from oci_core_instance
  EOQ
}

query "oci_compute_instance_total_cores" {
  sql = <<-EOQ
    select
      sum(shape_config_ocpus)  as "Total Cores"
    from
      oci_core_instance
  EOQ
}

query "oci_compute_instance_total_memory" {
  sql = <<-EOQ
    select
      sum(shape_config_memory_in_gbs)  as "Total Memory"
    from
      oci_core_instance
  EOQ
}

query "oci_compute_instance_public_instance_count" {
  sql = <<-EOQ
    with public_ips as (
      select 
        i.title as "title"
      from 
        oci_core_instance as i,
        oci_core_vnic_attachment as a 
      where 
        i.id = a.instance_id and a.public_ip is not null
    )
    select
      count(*) as value,
      'Public Instances' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      public_ips
  EOQ
}

query "oci_compute_instance_running_above_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      ' Running > 90 Days' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      oci_core_instance
    where
      date_part('day', now() - time_created) > 90
  EOQ
}

query "oci_compute_instance_by_public_ip" {
  sql = <<-EOQ
    with instances as (
      select
        case
          when a.public_ip is null then 'private'
          else 'public'
        end as visibility
      from
        oci_core_instance as i,
        oci_core_vnic_attachment as a
      where
        i.id = a.instance_id
    )
    select
      visibility,
      count(*)
    from
      instances
    group by
      visibility
  EOQ
}

query "oci_compute_instance_by_compartment" {
  sql = <<-EOQ
    select 
      c.title as "Compartment",
      count(b.*) as "instances" 
    from 
      oci_core_instance as b,
      oci_identity_compartment as c 
    where 
      c.id = b.compartment_id
    group by 
      c.title
    order by 
      c.title
  EOQ
}

query "oci_compute_instance_by_tenancy" {
  sql = <<-EOQ
    select 
      c.title as "Tenancy",
      count(v.*) as "instances" 
    from 
      oci_core_instance as v,
      oci_identity_tenancy as c 
    where 
      c.id = v.compartment_id and v.lifecycle_state <> 'TERMINATED'
    group by 
      c.title
    order by 
      c.title
  EOQ
}

query "oci_compute_instance_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      oci_core_instance as i
    group by
      region
  EOQ
}

query "oci_compute_instance_by_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_core_instance
    group by
      lifecycle_state
  EOQ
}

query "oci_compute_instance_by_type" {
  sql = <<-EOQ
    select
      shape as "Shape",
      count(*) as "instances"
    from
      oci_core_instance
    group by shape
    order by shape
  EOQ
}

query "oci_compute_instance_by_pv_encryption_intransit_status" {
  sql = <<-EOQ
    select
      count(i.*) as "Total"
    from oci_core_instance i
      left join oci_core_boot_volume_attachment a on a.instance_id = i.id
      where a.is_pv_encryption_in_transit_enabled and a.lifecycle_state = 'ATTACHED'
  EOQ
}

query "oci_compute_instance_by_creation_month" {
  sql = <<-EOQ
    with instances as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_core_instance
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
      -- instances_by_month.count
      coalesce(instances_by_month.count, 0)
    from
      months
      left join instances_by_month on months.month = instances_by_month.creation_month
    order by
      months.month desc;
  EOQ
}

query "oci_compute_top10_cpu_past_week" {
  sql = <<-EOQ
     with top_n as (
    select
      id,
      avg(average)
    from
      oci_core_instance_metric_cpu_utilization_daily
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
      oci_core_instance_metric_cpu_utilization_hourly
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      and id in (select id from top_n)
    order by
      timestamp
  EOQ
}

query "oci_compute_instances_by_cpu_utilization_category" {
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
        oci_core_instance_metric_cpu_utilization_daily
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


dashboard "oci_compute_instance_summary" {

  title = "OCI Compute Instance Dashboard"

  container {

    card {
      sql   = query.oci_compute_instance_count.sql
      width = 2
    }

    card {
      sql   = query.oci_compute_instance_total_cores.sql
      width = 2
    }

    card {
      sql   = query.oci_compute_instance_total_memory.sql
      width = 2
    }

    card {
      sql   = query.oci_compute_instance_public_instance_count.sql
      width = 2
    }

    card {
      sql   = query.oci_compute_instance_running_above_90_days.sql
      width = 2
    }

  }

  container {

    title = "Assesments"
    width = 12

    chart {
      title = "Volume State"
      sql   = query.oci_compute_instance_by_state.sql
      type  = "donut"
      width = 3
    }

    chart {
      title = "Public/Private"
      sql   = query.oci_compute_instance_by_public_ip.sql
      type  = "donut"
      width = 3
    }

  }


  container {

    title = "Analysis"

    chart {
      title = "Instances by Tenancy"
      sql = query.oci_compute_instance_by_tenancy.sql
      type  = "column"
      width = 3
    }   

    chart {
      title = "Instances by Compartment"
      sql   = query.oci_compute_instance_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Instances by Region"
      sql   = query.oci_compute_instance_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Instances by Shape"
      sql   = query.oci_compute_instance_by_type.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Instances by Age"
      sql   = query.oci_compute_instance_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

  container {

    title = "Performance & Utilization"

    chart {
      title = "Top 10 CPU - Last 7 days [ needs to be a crosstab?]"
      sql   = query.oci_compute_top10_cpu_past_week.sql
      type  = "line"
      width = 6
    }


    chart {
      title = "Average max daily CPU - Last 30 days"
      sql   = query.oci_compute_instances_by_cpu_utilization_category.sql
      type  = "column"
      width = 6
    }
  }

}
