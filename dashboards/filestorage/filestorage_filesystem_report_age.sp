dashboard "oci_filestorage_filesystem_age_report" {

  title         = "OCI File Storage File System Age Report"
  documentation = file("./dashboards/filestorage/docs/filestorage_filesystem_age_report.md")

  tags = merge(local.filestorage_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.oci_filestorage_filesystem_count.sql
      width = 2
    }

    card {
      sql   = query.oci_filestorage_filesystem_24_hrs.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_filestorage_filesystem_30_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_filestorage_filesystem_90_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_filestorage_filesystem_365_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_filestorage_filesystem_1_year.sql
      width = 2
      type  = "info"
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    sql = query.oci_filestorage_filesystem_age_table.sql
  }

}

query "oci_filestorage_filesystem_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_file_storage_file_system
    where
      lifecycle_state <> 'DELETED' and time_created > now() - '1 days' :: interval;
  EOQ
}

query "oci_filestorage_filesystem_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_file_storage_file_system
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "oci_filestorage_filesystem_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_file_storage_file_system
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "oci_filestorage_filesystem_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_file_storage_file_system
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "oci_filestorage_filesystem_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_file_storage_file_system
    where
      lifecycle_state <> 'DELETED' and time_created <= now() - '1 year' :: interval;
  EOQ
}

query "oci_filestorage_filesystem_age_table" {
  sql = <<-EOQ
    select
      f.display_name as "Name",
      now()::date - f.time_created::date as "Age in Days",
      f.time_created as "Create Time",
      f.lifecycle_state as "Lifecycle State",
      coalesce(c.title, 'root') as "Compartment",
      t.title as "Tenancy",
      f.region as "Region",
      f.id as "OCID"
    from
      oci_file_storage_file_system as f
      left join oci_identity_compartment as c on f.compartment_id = c.id
      left join oci_identity_tenancy as t on f.tenant_id = t.id
    where
      f.lifecycle_state <> 'DELETED'
    order by
      f.display_name;
  EOQ
}
