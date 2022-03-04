dashboard "oci_block_storage_boot_volume_dashboard" {

  title = "OCI Block Storage Boot Volume Dashboard"

  tags = merge(local.blockstorage_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_block_storage_boot_volume_count.sql
      width = 2
    }

    card {
      sql   = query.oci_block_storage_boot_volume_storage_total.sql
      width = 2
    }

    card {
      sql   = query.oci_block_storage_boot_volume_default_encrypted_volumes_count.sql
      width = 2
    }

    card {
      sql   = query.oci_block_storage_boot_volume_faulty_volumes_count.sql
      width = 2
    }

    card {
      sql   = query.oci_block_storage_boot_volume_with_no_backups_count.sql
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Lifecycle State"
      sql   = query.oci_block_storage_boot_volume_by_lifecycle_state.sql
      type  = "donut"
      width = 3

      series "count" {
        point "faulty" {
          color = "alert"
        }
        point "ok" {
          color = "ok"
        }
      }
    }

    chart {
      title = "Backup Status"
      sql   = query.oci_block_storage_boot_volume_with_backups.sql
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
      title = "Boot Volumes by Tenancy"
      sql   = query.oci_block_storage_boot_volume_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Boot Volumes by Compartment"
      sql   = query.oci_block_storage_boot_volume_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Boot Volumes by Region"
      sql   = query.oci_block_storage_boot_volume_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Boot Volume by Age"
      sql   = query.oci_block_storage_boot_volume_by_creation_month.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Encryption Status by Type"
      sql   = query.oci_block_storage_boot_volume_by_encryption_status.sql
      type  = "column"
      width = 3
    }

  }

  container {

    chart {
      title = "Storage by Tenancy (GB)"
      sql   = query.oci_block_storage_boot_volume_storage_by_tenancy.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Compartment (GB)"
      sql   = query.oci_block_storage_boot_volume_storage_by_compartment.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Region (GB)"
      sql   = query.oci_block_storage_boot_volume_storage_by_region.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Age (GB)"
      sql   = query.oci_block_storage_boot_volume_storage_by_creation_month.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }
  }

}

# Card Queries

query "oci_block_storage_boot_volume_count" {
  sql = <<-EOQ
    select count(*) as "Boot Volumes" from oci_core_boot_volume where lifecycle_state <> 'TERMINATED';
  EOQ
}

query "oci_block_storage_boot_volume_storage_total" {
  sql = <<-EOQ
    select
      sum(size_in_gbs) as "Total Storage (GB)"
    from
      oci_core_boot_volume
    where
      lifecycle_state <> 'TERMINATED';
  EOQ
}

query "oci_block_storage_boot_volume_default_encrypted_volumes_count" {
  sql = <<-EOQ
    select
      count(*) as "OCI Managed Encryption"
    from
      oci_core_boot_volume
    where
      kms_key_id is null and lifecycle_state <> 'TERMINATED';
  EOQ
}

query "oci_block_storage_boot_volume_faulty_volumes_count" {
  sql = <<-EOQ
   select
      count(*) as value,
      'Faulty' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_core_boot_volume
    where
      lifecycle_state = 'FAULTY';
  EOQ
}


query "oci_block_storage_boot_volume_with_no_backups_count" {
  sql = <<-EOQ
    select
      count(v.*) as value,
      'Without Backups' as label,
      case count(v.*) when 0 then 'ok' else 'alert' end as type
    from
      oci_core_boot_volume as v
    left join oci_core_boot_volume_backup as b on v.id = b.boot_volume_id
    where
      b.id is null and v.lifecycle_state <> 'TERMINATED';
  EOQ
}

# Assessment Queries

query "oci_block_storage_boot_volume_by_lifecycle_state" {
  sql = <<-EOQ
    select
      case when lifecycle_state = 'FAULTY' then 'faulty' else 'ok' end as status,
      count(*)
    from
      oci_core_boot_volume
    where
      lifecycle_state <> 'TERMINATED'
    group by
      status;
  EOQ
}

query "oci_block_storage_boot_volume_with_backups" {
  sql = <<-EOQ
    select
      case when b.id is null then 'disabled' else 'enabled' end as status,
      count(*)
    from
      oci_core_boot_volume as v
      left join oci_core_boot_volume_backup as b on v.id = b.boot_volume_id
    where
      v.lifecycle_state <> 'TERMINATED'
    group by
      status;
  EOQ
}

# Analysis Queries

query "oci_block_storage_boot_volume_by_tenancy" {
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

query "oci_block_storage_boot_volume_by_compartment" {
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
      count(v.*) as "Volumes"
    from
      oci_core_boot_volume as v,
      oci_identity_tenancy as t,
      compartments as c
    where
      c.id = v.compartment_id and v.tenant_id = t.id and v.lifecycle_state <> 'TERMINATED'
    group by
      t.title,
      c.title
    order by
      t.title,
      c.title;
  EOQ
}

query "oci_block_storage_boot_volume_by_region" {
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

query "oci_block_storage_boot_volume_by_creation_month" {
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

query "oci_block_storage_boot_volume_storage_by_tenancy" {
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

query "oci_block_storage_boot_volume_storage_by_compartment" {
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
      sum(v.size_in_gbs) as "GB"
    from
      oci_core_boot_volume as v,
      oci_identity_tenancy as t,
      compartments as c
    where
      c.id = v.compartment_id and v.tenant_id = t.id and v.lifecycle_state <> 'TERMINATED'
    group by
      t.title,
      c.title
    order by
      t.title,
      c.title;
  EOQ
}

query "oci_block_storage_boot_volume_storage_by_region" {
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

query "oci_block_storage_boot_volume_storage_by_creation_month" {
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

query "oci_block_storage_boot_volume_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select
        id,
        case
          when kms_key_id is null then 'oci_managed'
          else 'customer_managed'
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
