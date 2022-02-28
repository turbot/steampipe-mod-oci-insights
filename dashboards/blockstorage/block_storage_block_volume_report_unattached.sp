query "oci_block_storage_block_volume_unattached_volumes_count" {
  sql = <<-EOQ
   select
      count(*) as value,
      'Unattached' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_core_volume
    where
      id not in (
        select
          volume_id
        from
          oci_core_volume_attachment
      ) and lifecycle_state <> 'TERMINATED';
  EOQ
}

dashboard "oci_block_storage_block_volume_unattached_report" {

  title = "OCI Block Storage Block Volume Unattached Report"

  tags = merge(local.blockstorage_common_tags, {
    type = "Report"
    category = "Unused"
  })

  container {

    card {
      sql   = query.oci_block_storage_block_volume_unattached_volumes_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        v.display_name as "Name",
        a.lifecycle_state as "Attachment Status",
        now()::date - v.time_created::date as "Age in Days",
        v.time_created as "Create Time",
        v.lifecycle_state as "Lifecycle State",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        v.region as "Region",
        v.id as "OCID"
      from
        oci_core_volume as v
        left join oci_core_volume_attachment as a on a.volume_id = v.id
        left join oci_identity_compartment as c on v.compartment_id = c.id
        left join oci_identity_tenancy as t on v.tenant_id = t.id
        where
          v.lifecycle_state <> 'TERMINATED'
        order by
          v.time_created,
          v.title;
    EOQ
  }

}
