dashboard "oci_block_storage_boot_volume_unattached_report" {

  title         = "OCI Block Storage Boot Volume Unattached Report"
  documentation = file("./dashboards/blockstorage/docs/blockstorage_boot_volume_report_unattached.md")

  tags = merge(local.blockstorage_common_tags, {
    type     = "Report"
    category = "Unused"
  })

  container {

    card {
      sql   = query.oci_block_storage_boot_volume_count.sql
      width = 2
    }

    card {
      sql   = query.oci_block_storage_boot_volume_unattached_count.sql
      width = 2
    }
  }

  table {
    column "OCID" {
      display = "none"
    }

    sql = query.oci_block_storage_boot_volume_unattached_table.sql
  }

}

query "oci_block_storage_boot_volume_unattached_count" {
  sql = <<-EOQ
   select
      count(*) as value,
      'Unattached' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_core_boot_volume
    where
      id not in (
        select
          boot_volume_id
        from
          oci_core_boot_volume_attachment
      ) and lifecycle_state <> 'TERMINATED'
  EOQ
}

query "oci_block_storage_boot_volume_unattached_table" {
  sql = <<-EOQ
      select
        v.display_name as "Name",
        a.lifecycle_state as "Attachment Status",
        i.display_name as "Instance Name",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        v.region as "Region",
        v.id as "OCID"
      from
        oci_core_boot_volume as v
        left join oci_core_boot_volume_attachment as a on a.boot_volume_id = v.id
        left join oci_core_instance as i on a.instance_id = i.id
        left join oci_identity_compartment as c on v.compartment_id = c.id
        left join oci_identity_tenancy as t on v.tenant_id = t.id
      where
        v.lifecycle_state <> 'TERMINATED'
      order by
        v.display_name;
  EOQ
}
