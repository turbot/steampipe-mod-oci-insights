query "oci_filestorage_filesystem_count" {
  sql = <<-EOQ
    select count(*) as "File Systems" from oci_file_storage_file_system where lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_filestorage_filesystem_snapshot_count" {
  sql = <<-EOQ
    select count(*) as "Snapshots" from oci_file_storage_snapshot where lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_filestorage_cloned_filesystem_count" {
  sql = <<-EOQ
    select
      count(*) as "Cloned File Systems"
    from
      oci_file_storage_file_system
    where
      is_clone_parent and lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_filestorage_uncloned_filesystem_count" {
  sql = <<-EOQ
    select
      count(*) as "Uncloned File Systems"
    from
      oci_file_storage_file_system
    where
      not is_clone_parent and lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_filestorage_cloned_snapshot_count" {
  sql = <<-EOQ
    select
      count(*) as "Cloned Snapshots"
    from
      oci_file_storage_snapshot
    where
      is_clone_source and lifecycle_state <> 'DELETED';
  EOQ
}

# Assessments
query "oci_filestorage_filesystem_by_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_file_storage_file_system
    where
      lifecycle_state <> 'DELETED'
    group by
      lifecycle_state;
  EOQ
}

# Analysis
query "oci_filestorage_filesystem_by_tenancy" {
  sql = <<-EOQ
    select
       t.name as "Tenancy",
       count(a.id)::numeric as "File Systems"
    from
      oci_file_storage_file_system as a,
      oci_identity_tenancy as t
    where
      t.id = a.tenant_id and a.lifecycle_state <> 'DELETED'
    group by
      t.name
    order by
      t.name;
  EOQ
}

query "oci_filestorage_filesystem_by_compartment" {
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
      count(a.*) as "File Systems"
    from
      oci_file_storage_file_system as a,
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

query "oci_filestorage_filesystem_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "FileSystems"
    from
      oci_file_storage_file_system
    where
      lifecycle_state <> 'DELETED'
    group by
      region
    order by
      region;
  EOQ
}


query "oci_filestorage_filesystem_by_creation_month" {
  sql = <<-EOQ
    with filesystems as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_file_storage_file_system
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
                from filesystems)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    filesystems_by_month as (
      select
        creation_month,
        count(*)
      from
        filesystems
      group by
        creation_month
    )
    select
      months.month,
      filesystems_by_month.count
    from
      months
      left join filesystems_by_month on months.month = filesystems_by_month.creation_month
    order by
      months.month;
  EOQ
}

dashboard "oci_filestorage_filesystem_dashboard" {

  title = "OCI File Storage File System Dashboard"

  container {

    card {
      sql   = query.oci_filestorage_filesystem_count.sql
      width = 2
    }

    card {
      sql   = query.oci_filestorage_cloned_filesystem_count.sql
      width = 2
    }

    card {
      sql   = query.oci_filestorage_uncloned_filesystem_count.sql
      width = 2
    }

    card {
      sql   = query.oci_filestorage_filesystem_snapshot_count.sql
      width = 2
    }

    card {
      sql   = query.oci_filestorage_cloned_snapshot_count.sql
      width = 2
    }
  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "File Systems by State"
      sql   = query.oci_filestorage_filesystem_by_state.sql
      type  = "donut"
      width = 4
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "File Systems by Tenancy"
      sql   = query.oci_filestorage_filesystem_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems by Compartment"
      sql   = query.oci_filestorage_filesystem_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems by Region"
      sql   = query.oci_filestorage_filesystem_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems Age"
      sql   = query.oci_filestorage_filesystem_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

}
