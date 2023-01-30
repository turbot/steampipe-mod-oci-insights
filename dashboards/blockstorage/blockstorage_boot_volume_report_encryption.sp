dashboard "blockstorage_boot_volume_encryption_report" {

  title         = "OCI Block Storage Boot Volume Encryption Report"
  documentation = file("./dashboards/blockstorage/docs/blockstorage_boot_volume_report_encryption.md")

  tags = merge(local.blockstorage_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.blockstorage_boot_volume_count
      width = 3
    }

    card {
      query = query.blockstorage_boot_volume_customer_managed_encryption_count
      width = 3
    }

    card {
      query = query.blockstorage_boot_volume_default_encrypted_volumes_count
      width = 3
    }
  }

  table {
    column "OCID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.blockstorage_boot_volume_detail.url_path}?input.boot_volume_id={{.OCID | @uri}}"
    }

    query = query.blockstorage_boot_volume_encryption_report
  }

}

query "blockstorage_boot_volume_customer_managed_encryption_count" {
  sql = <<-EOQ
    select
      count(*) as "Customer-Managed Encryption"
    from
      oci_core_boot_volume
    where
      kms_key_id is not null and lifecycle_state <> 'TERMINATED'
  EOQ
}

query "blockstorage_boot_volume_encryption_report" {
  sql = <<-EOQ
      select
        v.display_name as "Name",
        case when v.kms_key_id is not null then 'Customer-Managed' else 'Oracle-Managed' end as "Encryption Status",
        v.kms_key_id as "KMS Key ID",
        t.title as "Tenancy",
        coalesce(c.title, 'root') as "Compartment",
        v.region as "Region",
        v.id as "OCID"
      from
        oci_core_boot_volume as v
        left join oci_identity_compartment as c on v.compartment_id = c.id
        left join oci_identity_tenancy as t on v.tenant_id = t.id
      where
        v.lifecycle_state <> 'TERMINATED'
      order by
        v.display_name;
  EOQ
}
