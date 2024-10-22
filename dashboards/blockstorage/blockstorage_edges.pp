edge "blockstorage_block_volume_backup_policy_to_blockstorage_block_volume_backup" {
  title = "backup"

  sql = <<-EOQ
    select
      v.volume_backup_policy_id as from_id,
      b.id as to_id
    from
      oci_core_volume_backup as b,
      oci_core_volume as v,
      oci_core_volume_backup_policy as p
    where
      v.volume_backup_policy_id is not null
      and v.volume_backup_policy_id = p.id
      and p.id = any($1);
  EOQ

  param "blockstorage_block_volume_backup_policy_ids" {}
}

edge "blockstorage_block_volume_default_backup_policy_to_blockstorage_block_volume_backup" {
  title = "backup"

  sql = <<-EOQ
    select
      v.volume_backup_policy_id as from_id,
      b.id as to_id
    from
      oci_core_volume_backup as b,
      oci_core_volume as v,
      oci_core_volume_default_backup_policy as p
    where
      v.volume_backup_policy_id is not null
      and v.volume_backup_policy_id = p.id
      and p.id = any($1);
  EOQ

  param "blockstorage_block_volume_default_backup_policy_ids" {}
}

edge "blockstorage_block_volume_to_blockstorage_block_volume_backup" {
  title = "backup"

  sql = <<-EOQ
    select
      coalesce(
        v.volume_backup_policy_id,
        v.id
      ) as from_id,
      b.id as to_id
    from
      oci_core_volume_backup as b,
      oci_core_volume as v
    where
      v.id = b.volume_id
      and v.id = any($1);
  EOQ

  param "blockstorage_block_volume_ids" {}
}

edge "blockstorage_block_volume_to_blockstorage_block_volume_backup_policy" {
  title = "uses"

  sql = <<-EOQ
    select
      id as from_id,
      volume_backup_policy_id as to_id
    from
      oci_core_volume
    where
      volume_backup_policy_id is not null
      and id = any($1);
  EOQ

  param "blockstorage_block_volume_ids" {}
}

edge "blockstorage_block_volume_to_blockstorage_block_volume_default_backup_policy" {
  title = "uses"

  sql = <<-EOQ
    select
      id as from_id,
      volume_backup_policy_id as to_id
    from
      oci_core_volume
    where
      volume_backup_policy_id is not null
      and id = any($1);
  EOQ

  param "blockstorage_block_volume_ids" {}
}

edge "blockstorage_block_volume_to_blockstorage_block_volume_clone" {
  title = "clone block volume"

  sql = <<-EOQ
    select
      source_details ->> 'id' as from_id,
      id as to_id
    from
      oci_core_volume
    where
      id = any($1)
      and source_details is not null;
  EOQ

  param "blockstorage_block_volume_ids" {}
}

edge "blockstorage_block_volume_to_blockstorage_block_volume_replica" {
  title = "replica"

  sql = <<-EOQ
    select
      block_volume_id as from_id,
      id as to_id
    from
      oci_core_block_volume_replica
    where
      block_volume_id = any($1);
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

edge "blockstorage_block_volume_to_kms_vault" {
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

edge "blockstorage_boot_volume_backup_policy_to_blockstorage_boot_volume_backup" {
  title = "backup"

  sql = <<-EOQ
    select
      v.volume_backup_policy_id as from_id,
      b.id as to_id
    from
      oci_core_volume_backup as b,
      oci_core_boot_volume as v,
      oci_core_volume_backup_policy as p
    where
      v.volume_backup_policy_id is not null
      and v.volume_backup_policy_id = p.id
      and p.id = any($1);
  EOQ

  param "blockstorage_boot_volume_backup_policy_ids" {}
}

edge "blockstorage_boot_volume_backup_to_compute_image" {
  title = "image"

  sql = <<-EOQ
    select
      id as from_id,
      image_id as to_id
    from
      oci_core_boot_volume_backup
    where
      id = any($1);
  EOQ

  param "blockstorage_boot_volume_backup_ids" {}
}

edge "blockstorage_boot_volume_default_backup_policy_to_blockstorage_boot_volume_backup" {
  title = "backup"

  sql = <<-EOQ
    select
      v.volume_backup_policy_id as from_id,
      b.id as to_id
    from
      oci_core_volume_backup as b,
      oci_core_boot_volume as v,
      oci_core_volume_default_backup_policy as p
    where
      v.volume_backup_policy_id is not null
      and v.volume_backup_policy_id = p.id
      and p.id = any($1);
  EOQ

  param "blockstorage_boot_volume_default_backup_policy_ids" {}
}

edge "blockstorage_boot_volume_to_blockstorage_boot_volume_backup" {
  title = "backup"

  sql = <<-EOQ
    select
      boot_volume_id as from_id,
      id as to_id
    from
      oci_core_boot_volume_backup
    where
      boot_volume_id = any($1);
  EOQ

  param "blockstorage_boot_volume_ids" {}
}

edge "blockstorage_boot_volume_to_blockstorage_boot_volume_backup_policy" {
  title = "uses"

  sql = <<-EOQ
    select
      id as from_id,
      volume_backup_policy_id as to_id
    from
      oci_core_boot_volume
    where
      volume_backup_policy_id is not null
      and id = any($1);
  EOQ

  param "blockstorage_boot_volume_ids" {}
}

edge "blockstorage_boot_volume_to_blockstorage_boot_volume_clone" {
  title = "clone boot volume"

  sql = <<-EOQ
    select
      source_details ->> 'id' as from_id,
      id as to_id
    from
      oci_core_boot_volume
    where
      id = any($1)
      and source_details is not null;
  EOQ

  param "blockstorage_boot_volume_ids" {}
}

edge "blockstorage_boot_volume_to_blockstorage_boot_volume_replica" {
  title = "replica"

  sql = <<-EOQ
    select
      boot_volume_id as from_id,
      id as to_id
    from
      oci_core_boot_volume_replica
    where
      boot_volume_id = any($1);
  EOQ

  param "blockstorage_boot_volume_ids" {}
}

edge "blockstorage_boot_volume_to_kms_key_version" {
  title = "key version"

  sql = <<-EOQ
    select
      b.id as from_id,
      k.current_key_version as to_id
    from
      oci_core_boot_volume as b,
      oci_kms_key as k
    where
      k.id = b.kms_key_id
      and b.id = any($1);
  EOQ

  param "blockstorage_boot_volume_ids" {}
}

edge "blockstorage_boot_volume_to_kms_vault" {
  title = "key vault"

  sql = <<-EOQ
    select
      v.id as from_id,
      k.vault_id as to_id
    from
      oci_core_boot_volume as v,
      oci_kms_key as k
    where
      k.id = v.kms_key_id
      and v.id = any($1);
  EOQ

  param "blockstorage_boot_volume_ids" {}
}