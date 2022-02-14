# Added to report
query "oci_boot_volume_unencrypted_count" {
  sql = <<-EOQ
    select 
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from 
      oci_core_boot_volume 
    where 
    kms_key_id is null and lifecycle_state <> 'DELETED'
  EOQ
}

report "oci_boot_volume_encryption_report" {

  title = "OCI Boot Volume Encryption Report"

  container {

    card {
      sql = query.oci_boot_volume_unencrypted_count.sql
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
      where lifecycle_state = 'ACTIVE')  
    )
      select
        v.display_name as "Boot Volume",
        case when v.kms_key_id is not null then 'Enabled' else 'Oracle Managed' end as "Encryption Status",
        k.algorithm as "Algorithm",
        v.kms_key_id as "KMS Key ID",
        c.title as "Compartment",
        v.region as "Region",
        v.id as "Boot Volume ID"
      from
        oci_core_boot_volume as v
        left join oci_kms_key as k on k.id = v.kms_key_id
        left join compartments as c on c.id = v.Compartment_id
      where
        v.lifecycle_state <> 'DELETED';
    EOQ
  }

}