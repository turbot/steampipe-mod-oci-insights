dashboard "oci_compute_instance_dashboard" {

  title         = "OCI Compute Instance Dashboard"
  documentation = file("./dashboards/compute/docs/compute_instance_dashboard.md")

  tags = merge(local.compute_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.oci_compute_instance_count
      width = 2
    }

    card {
      query = query.oci_compute_instance_total_cores
      width = 2
    }

    card {
      query = query.oci_compute_instance_public_instance_count
      width = 2
    }

    card {
      query = query.oci_compute_instance_monitoring_disabled_count
      width = 2
    }

  }

  container {

    title = "Assesments"

    chart {
      title = "Public/Private"
      query = query.oci_compute_instance_by_public_ip
      type  = "donut"
      width = 3

      series "count" {
        point "private" {
          color = "ok"
        }
        point "public" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Monitoring Status"
      query = query.oci_compute_instance_by_monitoring
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
      title = "Instances by Tenancy"
      query = query.oci_compute_instance_by_tenancy
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Compartment"
      query = query.oci_compute_instance_by_compartment
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Region"
      query = query.oci_compute_instance_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Age"
      query = query.oci_compute_instance_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Shape"
      query = query.oci_compute_instance_by_type
      type  = "column"
      width = 4
    }

  }

  container {

    title = "Performance & Utilization"

    chart {
      title = "Top 10 CPU - Last 7 days"
      query = query.oci_compute_top10_cpu_past_week
      type  = "line"
      width = 6
    }


    chart {
      title = "Average max daily CPU - Last 30 days"
      query = query.oci_compute_instances_by_cpu_utilization_category
      type  = "column"
      width = 6
    }
  }

}

# Card Queries

query "oci_compute_instance_count" {
  sql = <<-EOQ
    select count(*) as "Instances" from oci_core_instance where lifecycle_state <> 'TERMINATED';
  EOQ
}

query "oci_compute_instance_total_cores" {
  sql = <<-EOQ
    select
      sum(shape_config_ocpus)  as "Total OCPUs"
    from
      oci_core_instance
    where
      lifecycle_state <> 'TERMINATED';
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
        i.id = a.instance_id and a.public_ip is not null and i.lifecycle_state <> 'TERMINATED'
    )
    select
      count(*) as value,
      'Public Instances' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      public_ips;
  EOQ
}

query "oci_compute_instance_monitoring_disabled_count" {
  sql = <<-EOQ
    with instance_monitoring as (
      select
        distinct display_name
      from
        oci_core_instance,
        jsonb_array_elements(agent_config -> 'pluginsConfig') as config
      where
        config ->> 'name' = 'Compute Instance Monitoring'
        and config ->> 'desiredState' = 'DISABLED'
    )
    select
      count(*) as value,
      'Monitoring Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      instance_monitoring;
  EOQ
}

# Assesments Queries

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
        i.id = a.instance_id and i.lifecycle_state <> 'TERMINATED'
    )
    select
      visibility,
      count(*)
    from
      instances
    group by
      visibility;
  EOQ
}

query "oci_compute_instance_by_monitoring" {
  sql = <<-EOQ
    with instance_monitoring as (
      select
        distinct display_name
      from
        oci_core_instance,
        jsonb_array_elements(agent_config -> 'pluginsConfig') as config
      where
        config ->> 'name' = 'Compute Instance Monitoring'
        and config ->> 'desiredState' = 'ENABLED'
    )
    select
      case when m.display_name is null then 'disabled' else 'enabled' end as status,
      count(*)
    from
      oci_core_instance as i
      left join instance_monitoring as m on i.display_name = m.display_name
    group by
      status;
  EOQ
}

# Analysis Queries

query "oci_compute_instance_by_tenancy" {
  sql = <<-EOQ
    select
      t.title as "Tenancy",
      count(i.*) as "Instances"
    from
      oci_core_instance as i,
      oci_identity_tenancy as t
    where
      t.id = i.tenant_id and i.lifecycle_state <> 'TERMINATED'
    group by
      t.title
    order by
      t.title;
  EOQ
}

query "oci_compute_instance_by_compartment" {
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
      count(i.*) as "Instances"
    from
      oci_core_instance as i,
      compartments as c
    where
      c.id = i.compartment_id and i.lifecycle_state <> 'TERMINATED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_compute_instance_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as "Regions"
    from
      oci_core_instance as i
    where
      lifecycle_state <> 'TERMINATED'
    group by
      region;
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
      where
        lifecycle_state <> 'TERMINATED'
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

query "oci_compute_instance_by_type" {
  sql = <<-EOQ
    select
      shape as "Shape",
      count(*) as "Instances"
    from
      oci_core_instance
    where
      lifecycle_state <> 'TERMINATED'
    group by
      shape
    order by
      shape;
  EOQ
}

# Performance & Utilization Queries

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
      timestamp;
  EOQ
}

query "oci_compute_instances_by_cpu_utilization_category" {
  sql = <<-EOQ
    with compute_buckets as (
      select
    unnest(array ['Unused (<1%)','Underutilized (1-10%)','Right-sized (10-90%)', 'Overutilized (>90%)' ]) as compute_bucket
    ),
    max_averages as (
      select
        id,
        case
          when max(average) <= 1 then 'Unused (<1%)'
          when max(average) between 1 and 10 then 'Underutilized (1-10%)'
          when max(average) between 10 and 90 then 'Right-sized (10-90%)'
          when max(average) > 90 then 'Overutilized (>90%)'
        end as compute_bucket,
        max(average) as max_avg
      from
        oci_core_instance_metric_cpu_utilization_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        id
    )
    select
      b.compute_bucket as "CPU Utilization",
      count(a.*)
    from
      compute_buckets as b
    left join max_averages as a on b.compute_bucket = a.compute_bucket
    group by
      b.compute_bucket
  EOQ
}
