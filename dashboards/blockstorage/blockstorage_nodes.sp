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

node "blockstorage_block_volume_backup_policy" {
  category = category.blockstorage_block_volume_backup_policy

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_volume_backup_policy
    where
      id = any($1);
  EOQ

  param "blockstorage_block_volume_backup_policy_ids" {}
}

node "blockstorage_block_volume_default_backup_policy" {
  category = category.blockstorage_block_volume_default_backup_policy

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Backup Type', jsonb_array_elements(schedules)->'backupType',
        'Backup Offset Type', jsonb_array_elements(schedules)->'offsetType',
        'Time Created', time_created,
        'Tenant ID', tenant_id
      ) as properties
    from
      oci_core_volume_default_backup_policy
    where
      id = any($1);
  EOQ

  param "blockstorage_block_volume_default_backup_policy_ids" {}
}

node "blockstorage_block_volume_replica" {
  category = category.blockstorage_block_volume_replica

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Block Volume ID', block_volume_id,
        'Time Last Synced', time_last_synced,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_block_volume_replica
    where
      id = any($1);
  EOQ

  param "blockstorage_block_volume_replica_ids" {}
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

node "blockstorage_boot_volume_backup" {
  category = category.blockstorage_boot_volume_backup

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
      oci_core_boot_volume_backup
    where
      id = any($1);
  EOQ

  param "blockstorage_boot_volume_backup_ids" {}
}

node "blockstorage_boot_volume_backup_policy" {
  category = category.blockstorage_boot_volume_backup_policy

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_volume_backup_policy
    where
      id = any($1);
  EOQ

  param "blockstorage_boot_volume_backup_policy_ids" {}
}

node "blockstorage_boot_volume_default_backup_policy" {
  category = category.blockstorage_boot_volume_default_backup_policy

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Backup Type', jsonb_array_elements(schedules)->'backupType',
        'Backup Offset Type', jsonb_array_elements(schedules)->'offsetType',
        'Time Created', time_created,
        'Tenant ID', tenant_id
      ) as properties
    from
      oci_core_volume_default_backup_policy
    where
      id = any($1);
  EOQ

  param "blockstorage_boot_volume_default_backup_policy_ids" {}
}

node "blockstorage_boot_volume_replica" {
  category = category.blockstorage_boot_volume_replica

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
      oci_core_boot_volume_replica
    where
      id = any($1);
  EOQ

  param "blockstorage_boot_volume_replica_ids" {}
}