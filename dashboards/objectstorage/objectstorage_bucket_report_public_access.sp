dashboard "oci_objectstorage_bucket_public_access_report" {

  title = "OCI Object Storage Bucket Public Access Report"

  tags = merge(local.objectstorage_common_tags, {
    type     = "Report"
    category = "PublicAccess"
  })

  container {

    card {
      sql   = query.oci_objectstorage_bucket_count.sql
      width = 2
    }

    card {
      sql   = query.oci_objectstorage_bucket_public_access_count.sql
      width = 2
    }

    card {
      sql   = query.oci_objectstorage_bucket_read_only_access_count.sql
      width = 2
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    sql = query.oci_objectstorage_bucket_public_access_table.sql
  }

}

query "oci_objectstorage_bucket_public_access_table" {
  sql = <<-EOQ
      select
        b.name as "Name",
        public_access_type as "Bucket Access Type",
        b.is_read_only as "Read Only",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
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
