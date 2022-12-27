node "blockstorage_block_volume" {
  category = category.blockstorage_block_volume

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_volume
    where
      id = any($1);
  EOQ

  param "blockstorage_block_volume_ids" {}
}

node "blockstorage_block_volume_backup" {
  category = category.blockstorage_block_volume_backup

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_volume_backup
    where
      id = any($1);
  EOQ

  param "blockstorage_block_volume_backup_ids" {}
}

node "blockstorage_boot_volume" {
  category = category.blockstorage_boot_volume

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_boot_volume
    where
      id = any($1);
  EOQ

  param "blockstorage_boot_volume_ids" {}
}