dashboard "objectstorage_bucket_lifecycle_report" {

  title         = "OCI Object Storage Bucket Lifecycle Report"
  documentation = file("./dashboards/objectstorage/docs/objectstorage_bucket_report_lifecycle.md")

  tags = merge(local.objectstorage_common_tags, {
    type     = "Report"
    category = "Lifecycle"
  })

  container {

    card {
      query = query.objectstorage_bucket_count
      width = 3
    }

    card {
      query = query.objectstorage_bucket_versioning_disabled_count
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

    query = query.objectstorage_bucket_lifecycle_report
  }

}

query "objectstorage_bucket_lifecycle_report" {
  sql = <<-EOQ
      select
        b.name as "Name",
        b.versioning as "Versioning",
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
