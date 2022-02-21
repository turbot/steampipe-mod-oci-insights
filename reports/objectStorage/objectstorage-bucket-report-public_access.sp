dashboard "oci_objectstorage_bucket_public_access_report" {

  title = "OCI Object Storage Bucket Public Access Report"

  container {

    card {
      sql = query.oci_objectstorage_bucket_public_access_count.sql
      width = 2
    }

    card {
      sql = query.oci_objectstorage_bucket_read_only_access_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        v.name as "Name",
        case when v.public_access_type = 'NoPublicAccess' then 'Not Public' else 'Public' end as "Bucket Access",
        v.is_read_only as "Read Only",
        now()::date - v.time_created::date as "Age in Days",
        v.time_created as "Create Time",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        v.region as "Region",
        v.id as "OCID"
      from
        oci_objectstorage_bucket as v
        left join oci_identity_compartment as c on v.compartment_id = c.id
        left join oci_identity_tenancy as t on v.tenant_id = t.id
        order by
          v.time_created,
          v.title
    EOQ
  }

}