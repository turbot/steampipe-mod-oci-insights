query "oci_block_storage_boot_volume_customer_managed_encryption_count" {
  sql = <<-EOQ
    select count(*) as "Customer Managed Encryption"
      from 
    oci_core_boot_volume 
    where 
    kms_key_id is not null and lifecycle_state <> 'DELETED'
  EOQ
}

dashboard "oci_block_storage_boot_volume_encryption_report" {

  title = "OCI Block Storage Boot Volume Encryption Report"

  container {

    card {
      sql = query.oci_block_storage_boot_volume_customer_managed_encryption_count.sql
      width = 2
    }

    card {
      sql = query.oci_block_storage_boot_volume_default_encrypted_volumes_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      with compartments as ( 
        select
          id, title
        from
          oci_identity_tenancy
        union (
        select 
          id,title 
        from 
          oci_identity_compartment 
        where 
          lifecycle_state = 'ACTIVE'
        )  
       )
      select
        v.display_name as "Name",
        case when v.kms_key_id is not null then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
        now()::date - v.time_created::date as "Age in Days",
        v.time_created as "Create Time",
        v.lifecycle_state as "Lifecycle State",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        v.region as "Region",
        v.id as "OCID"
      from
        oci_core_boot_volume as v
        left join oci_identity_compartment as c on v.compartment_id = c.id
        left join oci_identity_tenancy as t on v.tenant_id = t.id
        where
          v.lifecycle_state <> 'DELETED'
        order by
          v.time_created,
          v.title
    EOQ
  }

}