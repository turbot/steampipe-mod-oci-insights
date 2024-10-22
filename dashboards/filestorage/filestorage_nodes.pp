node "filestorage_file_system" {
  category = category.filestorage_file_system

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_file_storage_file_system
    where
      id = any($1);
  EOQ

  param "filestorage_file_system_ids" {}
}

node "filestorage_mount_target" {
  category = category.filestorage_mount_target

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_file_storage_mount_target
    where
      id = any($1);
  EOQ

  param "filestorage_mount_target_ids" {}
}

node "filestorage_snapshot" {
  category = category.filestorage_snapshot

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', name,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_file_storage_snapshot
    where
      id = any($1);
  EOQ

  param "filestorage_snapshot_ids" {}
}
