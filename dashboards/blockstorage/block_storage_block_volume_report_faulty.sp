dashboard "oci_block_storage_block_volume_faulty_report" {

  title = "OCI Block Storage Block Volume Faulty Report"

  tags = merge(local.blockstorage_common_tags, {
    type = "Report"
  })

  container {

    card {
      sql   = query.oci_block_storage_block_volume_count.sql
      width = 2
    }

    card {
      sql   = query.oci_block_storage_block_volume_faulty_volumes_count.sql
      width = 2
    }
  }

  table {
    sql = query.oci_block_storage_block_volume_faulty_table.sql
  }

}

query "oci_block_storage_block_volume_faulty_table" {
  sql = <<-EOQ
      select
        v.display_name as "Name",
        v.lifecycle_state as "Lifecycle State",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        v.region as "Region",
        v.id as "OCID"
      from
        oci_core_volume as v
        left join oci_identity_compartment as c on v.compartment_id = c.id
        left join oci_identity_tenancy as t on v.tenant_id = t.id
      where
        v.lifecycle_state <> 'TERMINATED'
      order by
        v.display_name;
  EOQ
}
