query "oci_block_volume_customer_managed_encryption_count" {
  sql = <<-EOQ
    select count(*) as "Customer Managed"
      from 
    oci_core_volume 
    where 
    kms_key_id is not null and lifecycle_state <> 'DELETED'
  EOQ
}

report "oci_block_volume_encryption_report" {

  title = "OCI Block Volume Encryption Report"

  container {

    card {
      sql = query.oci_block_volume_customer_managed_encryption_count.sql
      width = 2
    }

    card {
      sql = query.oci_block_volume_default_encrypted_volumes_count.sql
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
        v.display_name as "Block Volume",
        case when v.kms_key_id is not null then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
        k.algorithm as "Algorithm",
        v.kms_key_id as "KMS Key ID",
        c.title as "Compartment",
        v.region as "Region",
        v.id as "Block Volume ID"
      from
        oci_core_volume as v
        left join oci_kms_key as k on k.id = v.kms_key_id
        left join compartments as c on c.id = v.Compartment_id
      where
        v.lifecycle_state <> 'DELETED';
    EOQ
  }

}