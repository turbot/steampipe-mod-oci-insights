edge "filestorage_file_system_to_filestorage_mount_target" {
  title = "mount target"

  sql = <<-EOQ
    with export_ids as (
      select
        jsonb_array_elements(exports)->> 'exportSetId' as export_set_id,
        id
      from
        oci_file_storage_file_system
      where
        id = any($1)
    )
    select
      e.id as from_id,
      m.id as to_id
    from
      export_ids as e,
      oci_file_storage_mount_target as m
    where
      e.export_set_id = m.export_set_id;
  EOQ

  param "filestorage_file_system_ids" {}
}

edge "filestorage_file_system_to_filestorage_snapshot" {
  title = "snapshot"

  sql = <<-EOQ
    select
      file_system_id as from_id,
      id as to_id
    from
      oci_file_storage_snapshot
    where
      file_system_id = any($1);
  EOQ

  param "filestorage_file_system_ids" {}
}

edge "filestorage_mount_target_to_vcn_network_security_group" {
  title = "nsg"

  sql = <<-EOQ
    select
      id as from_id,
      jsonb_array_elements(nsg_ids) as to_id
    from
      oci_file_storage_mount_target
    where
      id = any($1);
  EOQ

  param "filestorage_mount_target_ids" {}
}

edge "filestorage_mount_target_to_vcn_subnet" {
  title = "subnet"

  sql = <<-EOQ
    with export_ids as (
      select
        jsonb_array_elements(exports)->> 'exportSetId' as export_set_id
      from
        oci_file_storage_file_system
    ),
    nsg_ids as (
      select
        jsonb_array_elements_text(nsg_ids) as security_group_id,
        export_set_id,
        subnet_id
      from
        oci_file_storage_mount_target
      where
        id = any($1)
    )
    select
      s.id as from_id,
      n.subnet_id as to_id
    from
      export_ids as e,
      nsg_ids as n,
      oci_core_network_security_group as s
    where
      e.export_set_id = n.export_set_id
      and n.security_group_id = s.id;
  EOQ

  param "filestorage_mount_target_ids" {}
}