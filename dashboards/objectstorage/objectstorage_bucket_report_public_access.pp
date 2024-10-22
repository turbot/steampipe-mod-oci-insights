dashboard "objectstorage_bucket_public_access_report" {

  title         = "OCI Object Storage Bucket Public Access Report"
  documentation = file("./dashboards/objectstorage/docs/objectstorage_bucket_report_public_access.md")

  tags = merge(local.objectstorage_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      query = query.objectstorage_bucket_count
      width = 3
    }

    card {
      query = query.objectstorage_bucket_public_access_count
      width = 3
    }

    card {
      query = query.objectstorage_bucket_read_only_access_count
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

    query = query.objectstorage_bucket_public_access_report
  }

}

query "objectstorage_bucket_public_access_report" {
  sql = <<-EOQ
      select
        b.name as "Name",
        public_access_type as "Bucket Access Type",
        b.is_read_only as "Read Only",
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
