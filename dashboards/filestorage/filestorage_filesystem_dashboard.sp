query "oci_filestorage_filesystem_count" {
  sql = <<-EOQ
    select count(*) as "File Systems" from oci_file_storage_file_system
  EOQ
}

query "oci_filestorage_filesystem_snapshot_count" {
  sql = <<-EOQ
    select count(*) as "Snapshots" from oci_file_storage_snapshot
  EOQ
}

query "oci_filestorage_cloned_filesystem_count" {
  sql = <<-EOQ
    select
      count(*) as "Cloned File System"
    from
      oci_file_storage_file_system
    where
      is_clone_parent
  EOQ
}

query "oci_filestorage_uncloned_filesystem_count" {
  sql = <<-EOQ
    select
      count(*) as "Uncloned File System"
    from
      oci_file_storage_file_system
    where
      not is_clone_parent
  EOQ
}

query "oci_filestorage_cloned_snapshot_count" {
  sql = <<-EOQ
    select
      count(*) as "Cloned Snapshot"
    from
      oci_file_storage_snapshot
    where
      is_clone_source
  EOQ
}

# metered_bytes ?

# Hydration: Indicates whether the clone is currently copying metadata from the source. Not Added in to report
# query "oci_filestorage_hydrated_filesystem_count" {
#   sql = <<-EOQ
#     select
#       count(*) as "Unhydratd File System"
#     from
#       oci_file_storage_file_system
#     where
#       not is_hydrated
#   EOQ
# }

query "oci_filestorage_filesystem_by_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_file_storage_file_system
    group by
      lifecycle_state
  EOQ
}

query "oci_filestorage_filesystem_by_tenancy" {
  sql = <<-EOQ
    select
       t.name as "tenancy",
       count(a.id)::numeric as "File Systems"
    from
      oci_file_storage_file_system as a,
      oci_identity_tenancy as t
    where
      t.id = a.tenant_id
    group by
      tenancy
    order by
      tenancy
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
      where lifecycle_state = 'ACTIVE')
    )
   select
      c.title as "compartment",
      count(b.*) as "filesystems"
    from
      oci_file_storage_file_system as b,
      compartments as c
    where
      c.id = b.compartment_id
    group by
      compartment
    order by
      compartment
  EOQ
}

query "oci_filestorage_filesystem_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "FileSystems"
    from
      oci_file_storage_file_system
    group by
      region
    order by
      region
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
      sql = query.oci_filestorage_filesystem_count.sql
      width = 2
    }

    card {
      sql = query.oci_filestorage_cloned_filesystem_count.sql
      width = 2
    }

    card {
      sql = query.oci_filestorage_uncloned_filesystem_count.sql
      width = 2
    }

    card {
      sql = query.oci_filestorage_filesystem_snapshot_count.sql
      width = 2
    }

    card {
      sql = query.oci_filestorage_cloned_snapshot_count.sql
      width = 2
    }
  }

container {
      title = "Assessments"
      width = 6

    chart {
      title = "File Systems by State"
      sql = query.oci_filestorage_filesystem_by_state.sql
      type  = "donut"
      width = 4
    }

}

  container {
      title = "Analysis"

    chart {
      title = "File Systems by Tenancy"
      sql = query.oci_filestorage_filesystem_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems by Compartment"
      sql = query.oci_filestorage_filesystem_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems by Region"
      sql = query.oci_filestorage_filesystem_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems Age"
      sql = query.oci_filestorage_filesystem_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

  # container {
  #   title = "Resources by Age"

  #   chart {
  #     title = "FileSystems by Creation Month"
  #     sql = query.oci_filestorage_filesystem_by_creation_month.sql
  #     type  = "column"
  #     width = 4
  #     series "month" {
  #       color = "green"
  #     }
  #   }

  #   table {
  #     title = "Oldest filesystems"
  #     width = 4

  #     sql = <<-EOQ
  #       with compartments as (
  #         select
  #           id, title
  #         from
  #           oci_identity_tenancy
  #         union (
  #         select
  #           id,title
  #         from
  #           oci_identity_compartment
  #         where
  #           lifecycle_state = 'ACTIVE'
  #         )
  #      )
  #      select
  #         s.title as "filesystem",
  #         current_date - s.time_created::date as "Age in Days",
  #         c.title as "Compartment"
  #       from
  #         oci_file_storage_file_system as s
  #         left join compartments as c on c.id = s.compartment_id
  #       where
  #         lifecycle_state <> 'DELETED'
  #       order by
  #         "Age in Days" desc,
  #         s.title
  #       limit 5
  #     EOQ
  #   }

  #   table {
  #     title = "Newest filesystems"
  #     width = 4

  #     sql = <<-EOQ
  #       with compartments as (
  #         select
  #           id, title
  #         from
  #           oci_identity_tenancy
  #         union (
  #         select
  #           id,title
  #         from
  #           oci_identity_compartment
  #         where
  #           lifecycle_state = 'ACTIVE'
  #         )
  #      )
  #      select
  #         s.title as "filesystem",
  #         current_date - s.time_created::date as "Age in Days",
  #         c.title as "Compartment"
  #       from
  #         oci_file_storage_file_system as s
  #         left join compartments as c on c.id = s.compartment_id
  #       where
  #         lifecycle_state <> 'DELETED'
  #       order by
  #         "Age in Days" asc,
  #         s.title
  #       limit 5
  #     EOQ
  #   }

  # }

}
