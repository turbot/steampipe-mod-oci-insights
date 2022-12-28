dashboard "filestorage_filesystem_dashboard" {

  title         = "OCI File Storage File System Dashboard"
  documentation = file("./dashboards/filestorage/docs/filestorage_filesystem_dashboard.md")

  tags = merge(local.filestorage_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.filestorage_filesystem_count.sql
      width = 2
    }

    card {
      sql   = query.filestorage_filesystem_cloned_count.sql
      width = 2
    }

    card {
      sql   = query.filestorage_filesystem_snapshot_count.sql
      width = 2
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "File Systems by Tenancy"
      sql   = query.filestorage_filesystem_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems by Compartment"
      sql   = query.filestorage_filesystem_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems by Region"
      sql   = query.filestorage_filesystem_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems Age"
      sql   = query.filestorage_filesystem_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "filestorage_filesystem_count" {
  sql = <<-EOQ
    select count(*) as "File Systems" from oci_file_storage_file_system where lifecycle_state <> 'DELETED';
  EOQ
}

query "filestorage_filesystem_snapshot_count" {
  sql = <<-EOQ
    select count(*) as "Snapshots" from oci_file_storage_snapshot where lifecycle_state <> 'DELETED';
  EOQ
}

query "filestorage_filesystem_cloned_count" {
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

query "filestorage_filesystem_by_tenancy" {
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

query "filestorage_filesystem_by_compartment" {
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
      count(f.*) as "File Systems"
    from
      oci_file_storage_file_system as f,
      compartments as c
    where
      c.id = f.compartment_id and f.lifecycle_state <> 'DELETED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "filestorage_filesystem_by_region" {
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

query "filestorage_filesystem_by_creation_month" {
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
