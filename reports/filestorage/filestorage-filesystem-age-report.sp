

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
        with compartments as (
          select
            id,
            title
          from
            oci_identity_tenancy
          union (
            select
              id,
              title
            from
              oci_identity_compartment
            where lifecycle_state = 'ACTIVE')
        )
        select
          v.title as "File System",
          'some other value' as "File System",



          date_trunc('day',age(now(),v.time_created))::text as "Age",
          v.time_created as "Create Time",
          a.title as "Compartment",
          v.id as "FileSystem OCID",
          v.lifecycle_state as "State"
        from
          oci_file_storage_file_system as v,
          compartments as a
        where
          v.tenant_id = a.id
        order by
          v.time_created,
          v.title
      EOQ
    }


  }

}
