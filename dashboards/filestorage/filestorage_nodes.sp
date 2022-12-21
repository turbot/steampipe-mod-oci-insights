node "file_storage_mount_target" {
  category = category.file_storage_mount_target

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

  param "file_storage_mount_target_ids" {}
}