edge "blockstorage_block_volume_to_blockstorage_block_volume_backup" {
  title = "backup"

  sql = <<-EOQ
    select
      volume_id as from_id,
      id as to_id
    from
      oci_core_volume_backup
    where
      volume_id = any($1);
  EOQ

  param "blockstorage_block_volume_ids" {}
}

edge "blockstorage_block_volume_to_compute_instance" {
  title = "mounts"

  sql = <<-EOQ
    select
      instance_id as from_id,
      volume_id as to_id
    from
      oci_core_volume_attachment
    where
      volume_id = any($1);
  EOQ

  param "blockstorage_block_volume_ids" {}
}

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

edge "blockstorage_block_volume_to_kms_key_vault" {
  title = "key vault"

  sql = <<-EOQ
    select
      v.id as from_id,
      vault_id as to_id
    from
      oci_core_volume as v,
      oci_kms_key as k
    where
      k.id = v.kms_key_id
      and v.id = any($1);
  EOQ

  param "blockstorage_block_volume_ids" {}
}
