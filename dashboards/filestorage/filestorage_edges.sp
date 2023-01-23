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

edge "filestorage_file_system_to_kms_key" {
  title = "key"

  sql = <<-EOQ
    select
      k.vault_id as from_id,
      f.kms_key_id as to_id
    from
      oci_file_storage_file_system as f
      left join oci_kms_key as k on k.id = f.kms_key_id
    where
      f.id = any($1);
  EOQ

  param "filestorage_file_system_ids" {}
}

edge "filestorage_file_system_to_kms_vault" {
  title = "vault"

  sql = <<-EOQ
    select
      f.id as from_id,
      k.vault_id as to_id
    from
      oci_file_storage_file_system as f
      left join oci_kms_key as k on k.id = f.kms_key_id
    where
      vault_id is not null
      and f.id = any($1);
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
    with file_system_export_ids as (
      select
        jsonb_array_elements(exports)->> 'exportSetId' as export_set_id
      from
        oci_file_storage_file_system
    )
    select
      m.id as from_id,
      m.subnet_id as to_id
    from
      file_system_export_ids as e,
      oci_file_storage_mount_target as m
    where
      e.export_set_id = m.export_set_id
      and m.id = any($1);
  EOQ

  param "filestorage_mount_target_ids" {}
}