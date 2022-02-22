dashboard "oci_block_storage_block_volume_faulty_report" {

  title = "OCI Block Storage Block Volume Faulty Report"

  container {

    card {
      sql = query.oci_block_storage_block_volume_faulty_volumes_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        v.display_name as "Name",
        now()::date - v.time_created::date as "Age in Days",
        v.time_created as "Create Time",
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
          v.time_created,
          v.title
    EOQ
  }

}