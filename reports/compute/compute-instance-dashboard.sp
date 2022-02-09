# Added to report
query "oci_compute_instance_count" {
  sql = <<-EOQ
    select count(*) as "Instances" from oci_core_instance
  EOQ
}
# Added to report
query "oci_compute_instance_total_cores" {
  sql = <<-EOQ
    select
      sum(shape_config_ocpus)  as "Total Cores"
    from
      oci_core_instance
  EOQ
}

# Added to report
query "oci_compute_instance_total_memory" {
  sql = <<-EOQ
    select
      sum(shape_config_memory_in_gbs)  as "Total Memory"
    from
      oci_core_instance
  EOQ
}

# Not added report
query "oci_compute_instance_shape_by_total_memory" {
  sql = <<-EOQ
    select
      sum(shape_config_memory_in_gbs)  as "Total Memory",
      shape as "Shape"
    from
      oci_core_instance group by shape
  EOQ
}

// Added to report
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
# Added to report
query "oci_compute_instance_by_compartment" {
  sql = <<-EOQ
    select
      c.title as "compartment",
      count(i.*) as "total"
    from
      oci_core_instance as i,
      oci_identity_compartment as c
    where
      c.compartment_id = i.compartment_id and c.lifecycle_state <> 'DELETED'
    group by
      compartment
    order by count(i.*) desc

  EOQ
}

#Added to report
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

# Added
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

#Added
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

# New TBD
query "oci_compute_instance_by_pv_encryption_intransit_status" {
  sql = <<-EOQ
    select
      count(i.*) as "Total"
    from oci_core_instance i
      left join oci_core_boot_volume_attachment a on a.instance_id = i.id
      where a.is_pv_encryption_in_transit_enabled and a.lifecycle_state = 'ATTACHED'
  EOQ
}

# Added
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

# Note the CTE uses the dailt table to be efficient when filtering,
# and the hourly table to show granular line chart
# Added
query "ocu_compute_top10_cpu_past_week" {
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

# underused if avg CPU < 10% every day for last month
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


report "oci_compute_instance_summary" {

  title = "OCI Compute Dashboard"

  container {

    counter {
      sql   = query.oci_compute_instance_count.sql
      width = 2
    }

    counter {
      sql   = query.oci_compute_instance_total_cores.sql
      width = 2
    }

    counter {
      sql   = query.oci_compute_instance_total_memory.sql
      width = 2
    }

    counter {
      sql   = query.oci_compute_instance_running_above_90_days.sql
      width = 2
    }

    # counter {
    #   sql   = query.oci_compute_unencrypted_instances_count.sql
    #   width = 2
    # }


  #  counter {
  #     sql   = query.aws_ec2_instance_cost_last_30_counter.sql
  #     width = 2
  #   }

  # counter {
  #     sql   = query.aws_ec2_instance_cost_30_60_counter.sql
  #     width = 2
  #   }


    # chart {
    #   title = "EC2 Monthly Cost"
    #   type  = "column"
    #   sql   = query.aws_ec2_instance_cost_per_month.sql
    #   width = 2
    #   # axes {
    #   #   x {
    #   #     labels {
    #   #       display = "none"
    #   #     }
    #   #   }
    #   # }

    # }
  }


    container {
      title = "Analysis"


      #title = "Counts"
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
        title = "Instances by State"
        sql   = query.oci_compute_instance_by_state.sql
        type  = "column"
        width = 3
      }

      chart {
        title = "Instances by Shape"
        sql   = query.oci_compute_instance_by_type.sql
        type  = "column"
        width = 3
      }

    }


    container {
      title = "Assesments"
      width = 6

      chart {
        title  = "Encryption Status [To Do]"
        # sql    = query.oci_compute_instance_by_pv_encryption_intransit_status.sql
        # type   = "donut"
        width = 4
      }


    #  chart {
    #     title = "Public/Private"
    #     sql   = query.aws_ec2_instances_by_public_ip.sql
    #     type  = "donut"
    #     width = 4
    #   }

    }

  container {
    title  = "Performance & Utilization"

    chart {
      title = "Top 10 CPU - Last 7 days [ needs to be a crosstab?]"
      sql   = query.ocu_compute_top10_cpu_past_week.sql
      type  = "line"
      width = 6
    }


    chart {
      title = "Average max daily CPU - Last 30 days"
      sql   = query.oci_compute_instances_by_cpu_utilization_category.sql
      type  = "column"
      width = 6

      # 'Unused (<1%)','Underutilized (1-10%)','Right-sized (10-90%)', 'Overutilized (>90%)'
      # series "Underutilized (1-10%)" {
      #   color = "yellow"
      # }

    }

  }



  container {
    title   = "Resources by Age"

    chart {
      title = "Instance by Creation Month"
      sql   = query.oci_compute_instance_by_creation_month.sql
      type  = "column"
      width = 4

      series "month" {
        color = "green"
      }

    }

    #container {
    #  width = 4
      table {
        title = "Oldest instances"
        width = 4
        # Validate the query
        sql   = <<-EOQ
          select
            title as "instance",
            (current_date - time_created) as "Age in Days",
            compartment_id as "Compartment"
          from
            oci_core_instance
          where lifecycle_state <> 'DELETED'
          order by
            "Age in Days" desc,
            title
          limit 5
        EOQ
      }

      table {
        title = "Newest instances"
        width = 4

        sql   = <<-EOQ
          select
            title as "instance",
            current_date - time_created as "Age in Days",
            compartment_id as "Compartment"
          from
            oci_core_instance
          order by
            "Age in Days" asc,
            title
          limit 5
        EOQ
      }

    #}

  }

}