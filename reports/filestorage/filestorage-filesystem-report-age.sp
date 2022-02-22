

dashboard "oci_filestorage_filesystem_age_report" {

  title = "OCI File Storage File System Age Report"


  container {

    # Analysis
    card {
      sql   = query.oci_filestorage_filesystem_count.sql
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          oci_file_storage_file_system
        where
          time_created > now() - '1 days' :: interval
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '1-30 Days' as label
        from
          oci_file_storage_file_system
        where
          time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '30-90 Days' as label
        from
          oci_file_storage_file_system
        where
          time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '90-365 Days' as label
        from
          oci_file_storage_file_system
        where
          time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '> 1 Year' as label
        from
          oci_file_storage_file_system
        where
          time_created <= now() - '1 year' :: interval
      EOQ
      width = 2
      type  = "info"
    }

  }

  container {


    table {

      sql = <<-EOQ
        select
          k.display_name as "Name",
          now()::date - k.time_created::date as "Age in Days",
          k.time_created as "Create Time",
          k.lifecycle_state as "Lifecycle State",
          coalesce(c.title,'root') as "Compartment",
          t.title as "Tenancy",
          k.region as "Region",
          k.id as "OCID"
        from
          oci_file_storage_file_system as k
          left join oci_identity_compartment as c on k.compartment_id = c.id
          left join oci_identity_tenancy as t on k.tenant_id = t.id
        where
          k.lifecycle_state <> 'DELETED'
        order by
          k.time_created,
          k.title
      EOQ
    }


  }

}