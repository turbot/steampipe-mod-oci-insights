dashboard "blockstorage_boot_volume_dashboard" {

  title         = "OCI Block Storage Boot Volume Dashboard"
  documentation = file("./dashboards/blockstorage/docs/blockstorage_boot_volume_dashboard.md")

  tags = merge(local.blockstorage_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.blockstorage_boot_volume_count
      width = 3
    }

    card {
      query = query.blockstorage_boot_volume_storage_total
      width = 3
    }

    card {
      query = query.blockstorage_boot_volume_with_no_backups_count
      width = 3
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Backup Policy Status"
      query = query.blockstorage_boot_volume_with_backups
      type  = "donut"
      width = 3

      series "count" {
        point "with backup policy" {
          color = "ok"
        }
        point "no backup policy" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Boot Volumes by Tenancy"
      query = query.blockstorage_boot_volume_by_tenancy
      type  = "column"
      width = 4
    }

    chart {
      title = "Boot Volumes by Compartment"
      query = query.blockstorage_boot_volume_by_compartment
      type  = "column"
      width = 4
    }

    chart {
      title = "Boot Volumes by Region"
      query = query.blockstorage_boot_volume_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Boot Volumes by Age"
      query = query.blockstorage_boot_volume_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Boot Volumes by Encryption Type"
      query = query.blockstorage_boot_volume_by_encryption_status
      type  = "column"
      width = 4
    }

  }

  container {

    chart {
      title = "Storage by Tenancy (GB)"
      query = query.blockstorage_boot_volume_storage_by_tenancy
      type  = "column"
      width = 4

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Compartment (GB)"
      query = query.blockstorage_boot_volume_storage_by_compartment
      type  = "column"
      width = 4

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Region (GB)"
      query = query.blockstorage_boot_volume_storage_by_region
      type  = "column"
      width = 4

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Age (GB)"
      query = query.blockstorage_boot_volume_storage_by_creation_month
      type  = "column"
      width = 4

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Encryption Type (GB)"
      query = query.blockstorage_boot_volume_storage_by_encryption_type
      type  = "column"
      width = 4

      series "GB" {
        color = "tan"
      }
    }

  }

  container {

    title = "Performance & Utilization"

    chart {
      title = "Top 10 Average Read IOPS - Last 7 days"
      type  = "line"
      width = 6
      query = query.blockstorage_boot_volume_top_10_read_ops_avg
    }

    chart {
      title = "Top 10 Average Write IOPS - Last 7 days"
      type  = "line"
      width = 6
      query = query.blockstorage_boot_volume_top_10_write_ops_avg
    }

  }
}

# Card Queries

query "blockstorage_boot_volume_count" {
  sql = <<-EOQ
    select count(*) as "Boot Volumes" from oci_core_boot_volume where lifecycle_state <> 'TERMINATED';
  EOQ
}

query "blockstorage_boot_volume_storage_total" {
  sql = <<-EOQ
    select
      sum(size_in_gbs) as "Total Storage (GB)"
    from
      oci_core_boot_volume
    where
      lifecycle_state <> 'TERMINATED';
  EOQ
}

query "blockstorage_boot_volume_default_encrypted_volumes_count" {
  sql = <<-EOQ
    select
      count(*) as "Oracle-Managed Encryption"
    from
      oci_core_boot_volume
    where
      kms_key_id is null and lifecycle_state <> 'TERMINATED';
  EOQ
}

query "blockstorage_boot_volume_with_no_backups_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Without Backup Policy' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_core_boot_volume
    where
      volume_backup_policy_assignment_id is null and lifecycle_state <> 'TERMINATED';
  EOQ
}

# Assessment Queries

query "blockstorage_boot_volume_with_backups" {
  sql = <<-EOQ
    select
      case when volume_backup_policy_assignment_id is null then 'no backup policy' else 'with backup policy' end as status,
      count(*)
    from
      oci_core_boot_volume
    where
      lifecycle_state <> 'TERMINATED'
    group by
      status;
  EOQ
}

# Analysis Queries

query "blockstorage_boot_volume_by_tenancy" {
  sql = <<-EOQ
    select
      t.title as "Tenancy",
      count(v.*) as "Boot volumes"
    from
      oci_core_boot_volume as v,
      oci_identity_tenancy as t
    where
      t.id = v.tenant_id and v.lifecycle_state <> 'TERMINATED'
    group by
      t.title
    order by
      t.title;
  EOQ
}

query "blockstorage_boot_volume_by_compartment" {
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
      count(v.*) as "Volumes"
    from
      oci_core_boot_volume as v,
      compartments as c
    where
      c.id = v.compartment_id and v.lifecycle_state <> 'TERMINATED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "blockstorage_boot_volume_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Boot Volumes"
    from
      oci_core_boot_volume
    where
      lifecycle_state <> 'TERMINATED'
    group by
      region;
  EOQ
}

query "blockstorage_boot_volume_by_creation_month" {
  sql = <<-EOQ
    with volumes as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_core_boot_volume
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
                from volumes)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    volumes_by_month as (
      select
        creation_month,
        count(*)
      from
        volumes
      group by
        creation_month
    )
    select
      months.month,
      volumes_by_month.count
    from
      months
      left join volumes_by_month on months.month = volumes_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "blockstorage_boot_volume_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select
        id,
        case
          when kms_key_id is null then 'oracle-managed'
          else 'customer-managed'
        end as encryption_status
      from
        oci_core_boot_volume
      where
        lifecycle_state <> 'TERMINATED') as v
      group by
        encryption_status
      order by
        encryption_status desc;
  EOQ
}

query "blockstorage_boot_volume_storage_by_tenancy" {
  sql = <<-EOQ
   select
      t.title as "Tenancy",
      sum(v.size_in_gbs) as "GB"
    from
      oci_core_boot_volume as v,
      oci_identity_tenancy as t
    where
      t.id = v.tenant_id and v.lifecycle_state <> 'TERMINATED'
    group by
      t.title
    order by
      t.title;
  EOQ
}

query "blockstorage_boot_volume_storage_by_compartment" {
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
      sum(v.size_in_gbs) as "GB"
    from
      oci_core_boot_volume as v,
      compartments as c
    where
      c.id = v.compartment_id and v.lifecycle_state <> 'TERMINATED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "blockstorage_boot_volume_storage_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      sum(size_in_gbs) as "GB"
    from
      oci_core_boot_volume
    where
      lifecycle_state <> 'TERMINATED'
    group by
      region;
  EOQ
}

query "blockstorage_boot_volume_storage_by_creation_month" {
  sql = <<-EOQ
    with volumes as (
      select
        title,
        size_in_gbs,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_core_boot_volume
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
                from volumes)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    volumes_by_month as (
      select
        creation_month,
        sum(size_in_gbs) as size
      from
        volumes
      group by
        creation_month
    )
    select
      months.month,
      volumes_by_month.size as "GB"
    from
      months
      left join volumes_by_month on months.month = volumes_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "blockstorage_boot_volume_storage_by_encryption_type" {
  sql = <<-EOQ
    select
        case
          when kms_key_id is null then 'oracle-managed'
          else 'customer-managed'
        end as encryption_type,
      sum(size_in_gbs) as "GB"
    from
      oci_core_boot_volume
    where
      lifecycle_state <> 'TERMINATED'
    group by
      encryption_type;
  EOQ
}

# Performance Queries

query "blockstorage_boot_volume_top_10_read_ops_avg" {
  sql = <<-EOQ
    with top_n as (
      select
        id,
        avg(average)
      from
        oci_core_boot_volume_metric_read_ops_daily
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
        oci_core_boot_volume_metric_read_ops_hourly
      where
        timestamp  >= CURRENT_DATE - INTERVAL '7 day'
        and id in (select id from top_n);
  EOQ
}

query "blockstorage_boot_volume_top_10_write_ops_avg" {
  sql = <<-EOQ
    with top_n as (
      select
        id,
        avg(average)
      from
        oci_core_boot_volume_metric_write_ops_daily
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
      oci_core_boot_volume_metric_write_ops_hourly
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      and id in (select id from top_n);
  EOQ
}
