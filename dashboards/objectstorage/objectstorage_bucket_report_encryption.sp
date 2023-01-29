dashboard "objectstorage_bucket_encryption_report" {

  title         = "OCI Object Storage Bucket Encryption Report"
  documentation = file("./dashboards/objectstorage/docs/objectstorage_bucket_report_encryption.md")

  tags = merge(local.objectstorage_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.objectstorage_bucket_count
      width = 3
    }

    card {
      query = query.objectstorage_bucket_report_customer_managed_encryption_count
      width = 3
    }

    card {
      query = query.objectstorage_bucket_default_encryption_count
      width = 3
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.objectstorage_bucket_detail.url_path}?input.bucket_id={{.OCID | @uri}}"
    }

    query = query.objectstorage_bucket_encryption_report
  }

}

query "objectstorage_bucket_report_customer_managed_encryption_count" {
  sql = <<-EOQ
    select count(*) as "Customer-Managed Encryption"
      from
    oci_objectstorage_bucket
    where
    kms_key_id is not null;
  EOQ
}

query "objectstorage_bucket_encryption_report" {
  sql = <<-EOQ
      select
        b.name as "Name",
        case when b.kms_key_id is not null then 'Customer-Managed' else 'Oracle-Managed' end as "Encryption Status",
        b.kms_key_id as "KMS Key ID",
        t.title as "Tenancy",
        coalesce(c.title, 'root') as "Compartment",
        b.region as "Region",
        b.id as "OCID"
      from
        oci_objectstorage_bucket as b
        left join oci_identity_compartment as c on b.compartment_id = c.id
        left join oci_identity_tenancy as t on b.tenant_id = t.id
      order by
        b.name;
  EOQ
}
