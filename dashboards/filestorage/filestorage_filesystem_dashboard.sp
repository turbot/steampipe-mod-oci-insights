dashboard "oci_filestorage_filesystem_dashboard" {

  title = "OCI File Storage File System Dashboard"

  tags = merge(local.filestorage_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_filestorage_filesystem_count.sql
      width = 2
    }

    card {
      sql   = query.oci_filestorage_filesystem_cloned_count.sql
      width = 2
    }

    card {
      sql   = query.oci_filestorage_filesystem_snapshot_count.sql
      width = 2
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "File Systems by Tenancy"
      sql   = query.oci_filestorage_filesystem_by_tenancy.sql
      type  = "column"
      width = 2
    }

    chart {
      title = "File Systems by Compartment"
      sql   = query.oci_filestorage_filesystem_by_compartment.sql
      type  = "column"
      width = 2
    }

    chart {
      title = "File Systems by Region"
      sql   = query.oci_filestorage_filesystem_by_region.sql
      type  = "column"
      width = 2
    }

    chart {
      title = "File Systems Age"
      sql   = query.oci_filestorage_filesystem_by_creation_month.sql
      type  = "column"
      width = 2
    }
    chart {
      title = "File Systems by Type"
      sql   = query.oci_filestorage_filesystem_type.sql
      type  = "column"
      width = 2
    }
  }

}

# Card Queries

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

query "oci_filestorage_filesystem_cloned_count" {
  sql = <<-EOQ
    select
      count(*) as "Cloned File Systems"
    from
      oci_file_storage_file_system
    where
      is_clone_parent and lifecycle_state <> 'DELETED';
  EOQ
}

# Analysis Queries

query "oci_filestorage_filesystem_by_tenancy" {
  sql = <<-EOQ
    select
       t.name as "Tenancy",
       count(f.id)::numeric as "File Systems"
    from
      oci_file_storage_file_system as f,
      oci_identity_tenancy as t
    where
      t.id = f.tenant_id and f.lifecycle_state <> 'DELETED'
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
      t.title as "Tenancy",
      case when t.title = c.title then 'root' else c.title end as "Compartment",
      count(f.*) as "File Systems"
    from
      oci_file_storage_file_system as f,
      oci_identity_tenancy as t,
      compartments as c
    where
      c.id = f.compartment_id and f.tenant_id = t.id and f.lifecycle_state <> 'DELETED'
    group by
      t.title,
      c.title
    order by
      t.title,
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

query "oci_filestorage_filesystem_type" {
  sql = <<-EOQ
    select
      case when not is_clone_parent then 'Uncloned' else 'Cloned' end as status,
      count(*)
    from
      oci_file_storage_file_system
    group by
      status;
  EOQ
}
