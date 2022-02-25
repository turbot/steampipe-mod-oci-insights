query "oci_objectstorage_bucket_report_customer_managed_encryption_count" {
  sql = <<-EOQ
    select count(*) as "Customer Managed Encryption"
      from
    oci_objectstorage_bucket
    where
    kms_key_id is not null;
  EOQ
}

dashboard "oci_objectstorage_bucket_encryption_report" {

  title = "OCI Object Storage Bucket Encryption Report"

  container {

    card {
      sql   = query.oci_objectstorage_bucket_count.sql
      width = 2
    }

    card {
      sql = query.oci_objectstorage_bucket_report_customer_managed_encryption_count.sql
      width = 2
    }

    card {
      sql = query.oci_objectstorage_bucket_default_encryption_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        v.name as "Name",
        case when v.kms_key_id is not null then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
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
        v.title;
    EOQ
  }

}

