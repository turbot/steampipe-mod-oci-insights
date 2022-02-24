query "oci_objectstorage_bucket_report_versioning_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Versioning Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_objectstorage_bucket
    where
      versioning = 'Disabled'
  EOQ
}

dashboard "oci_objectstorage_bucket_lifecycle_report" {

  title = "OCI Object Storage Bucket Lifecycle Report"

  container {

    card {
      sql   = query.oci_objectstorage_bucket_count.sql
      width = 2
    }

    card {
      sql   = query.oci_objectstorage_bucket_report_versioning_disabled_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        v.name as "Name",
        v.versioning as "Versioning",
        v.time_created as "Create Time",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        v.region as "Region",
        v.id as "OCID"
      from
        oci_objectstorage_bucket as v
          left join oci_identity_compartment as c on v.compartment_id = c.id
          left join oci_identity_tenancy as t on v.tenant_id = t.id
        where
          v.versioning = 'Disabled'
        order by
          v.time_created,
          v.title
    EOQ
  }

}
