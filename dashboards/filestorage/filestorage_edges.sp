edge "file_storage_file_system_to_file_storage_snapshot" {
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

  param "file_storage_file_system_ids" {}
}