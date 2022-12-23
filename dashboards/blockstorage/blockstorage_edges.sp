edge "blockstorage_block_volume_to_kms_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      v.id as from_id,
      current_key_version as to_id
    from
      oci_core_volume as v,
      oci_kms_key as k
    where
      k.id = v.kms_key_id
      and v.id = any($1);
  EOQ

  param "blockstorage_block_volume_ids" {}
}
