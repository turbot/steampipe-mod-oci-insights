report "oci_block_volume_Unattached_report" {

  title = "OCI Block Volume Unattached Report"

  container {

    card {
      sql = query.oci_block_volume_unattached_volumes_count.sql
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
        v.display_name as "Block Volume",
        case when a.id is null then 'Unattached' else 'Attached' end as "Attachment Status",
        c.title as "Compartment",
        v.region as "Region",
        v.id as "Block Volume ID"
      from
        oci_core_volume as v
        left join oci_core_volume_attachment as a on a.volume_id = v.id
        left join compartments as c on c.id = v.Compartment_id
      where 
        v.lifecycle_state <> 'DELETED';
    EOQ
  }

}