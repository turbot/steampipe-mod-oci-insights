dashboard "blockstorage_block_volume_unattached_report" {

  title         = "OCI Block Storage Block Volume Unattached Report"
  documentation = file("./dashboards/blockstorage/docs/blockstorage_block_volume_report_unattached.md")

  tags = merge(local.blockstorage_common_tags, {
    type     = "Report"
    category = "Unused"
  })

  container {

    card {
      query = query.blockstorage_block_volume_unattached_count
      width = 3
    }
  }

  table {
    column "OCID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.blockstorage_block_volume_detail.url_path}?input.block_volume_id={{.OCID | @uri}}"
    }

    query = query.blockstorage_block_volume_unattached_report
  }

}

query "blockstorage_block_volume_unattached_count" {
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

query "blockstorage_block_volume_unattached_report" {
  sql = <<-EOQ
      select
        v.display_name as "Name",
        a.lifecycle_state as "Attachment Status",
        i.display_name as "Instance Name",
        t.title as "Tenancy",
        coalesce(c.title, 'root') as "Compartment",
        v.region as "Region",
        v.id as "OCID"
      from
        oci_core_volume as v
        left join oci_core_volume_attachment as a on a.volume_id = v.id
        left join oci_core_instance as i on a.instance_id = i.id
        left join oci_identity_compartment as c on v.compartment_id = c.id
        left join oci_identity_tenancy as t on v.tenant_id = t.id
      where
        v.lifecycle_state <> 'TERMINATED'
      order by
        v.display_name;
  EOQ
}
