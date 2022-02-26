query "oci_block_storage_boot_volume_count" {
  sql = <<-EOQ
    select count(*) as "Boot Volumes" from oci_core_boot_volume where lifecycle_state <> 'TERMINATED'
  EOQ
}

query "oci_block_storage_boot_volume_storage_total" {
  sql = <<-EOQ
    select
      sum(size_in_gbs) as "Total Storage (GB)"
    from
      oci_core_boot_volume
    where
      lifecycle_state <> 'TERMINATED'
  EOQ
}

query "oci_block_storage_boot_volume_default_encrypted_volumes_count" {
  sql = <<-EOQ
    select
      count(*) as "OCI Managed Encryption"
    from
      oci_core_boot_volume
    where
      kms_key_id is null and lifecycle_state <> 'TERMINATED'
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
      lifecycle_state = 'FAULTY'
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
      v.lifecycle_state <> 'TERMINATED'
    group by
      v.compartment_id,
      v.region,
      v.id
    having
      count(b.id) = 0
  EOQ
}

# Assessments
query "oci_block_storage_boot_volume_by_lifecycle_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_core_boot_volume
    where
      lifecycle_state <> 'TERMINATED'
    group by
      lifecycle_state
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
         when kms_key_id is null then 'OCI Managed'
         else 'Customer Managed'
         end as encryption_status
      from
        oci_core_boot_volume
      where
      lifecycle_state <> 'TERMINATED') as v
    group by
      encryption_status
    order by
      encryption_status desc
  EOQ
}

query "oci_block_storage_boot_volume_with_no_backups" {
  sql = <<-EOQ
    select
      v.display_name,
      count(v.display_name)
    from
      oci_core_boot_volume as v
    left join oci_core_boot_volume_backup as b on v.id = b.boot_volume_id
    where
      v.lifecycle_state <> 'TERMINATED'
    group by
      v.display_name
    having
      count(b.id) = 0
  EOQ
}

# Analysis

query "oci_block_storage_boot_volume_by_tenancy" {
  sql = <<-EOQ
    select
      c.title as "Tenancy",
      count(v.*) as "Boot volumes"
    from
      oci_core_boot_volume as v,
      oci_identity_tenancy as c
    where
      c.id = v.tenant_id and v.lifecycle_state <> 'TERMINATED'
    group by
      c.title
    order by
      c.title
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
      b.title as "Tenancy",
      case when b.title = c.title then 'root' else c.title end as "Compartment",
      count(a.*) as "Volumes"
    from
      oci_core_boot_volume as a,
      oci_identity_tenancy as b,
      compartments as c
    where
      c.id = a.compartment_id and a.tenant_id = b.id and a.lifecycle_state <> 'TERMINATED'
    group by
      b.title,
      c.title
    order by
      b.title,
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

# Analysis by Storage Size

query "oci_block_storage_boot_volume_storage_by_tenancy" {
  sql = <<-EOQ
   select
      c.title as "Tenancy",
      sum(v.size_in_gbs) as "GB"
    from
      oci_core_boot_volume as v,
      oci_identity_tenancy as c
    where
      c.id = v.tenant_id and v.lifecycle_state <> 'TERMINATED'
    group by
      c.title
    order by
      c.title;
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
      b.title as "Tenancy",
      case when b.title = c.title then 'root' else c.title end as "Compartment",
      sum(a.size_in_gbs) as "GB"
    from
      oci_core_boot_volume as a,
      oci_identity_tenancy as b,
      compartments as c
    where
      c.id = a.compartment_id and a.tenant_id = b.id and a.lifecycle_state <> 'TERMINATED'
    group by
      b.title,
      c.title
    order by
      b.title,
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

dashboard "oci_block_storage_boot_volume_dashboard" {

  title = "OCI Block Storage Boot Volume Dashboard"

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
    width = 6

    chart {
      title = "Lifecycle State"
      sql   = query.oci_block_storage_boot_volume_by_lifecycle_state.sql
      type  = "donut"
      width = 3
    }

    chart {
      title = "Encryption Status"
      sql   = query.oci_block_storage_boot_volume_by_encryption_status.sql
      type  = "donut"
      width = 3

      # series "Enabled" {
      #    color = "green"
      # }
    }

    chart {
      title = "No Backups"
      sql   = query.oci_block_storage_boot_volume_with_no_backups.sql
      type  = "donut"
      width = 3
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
