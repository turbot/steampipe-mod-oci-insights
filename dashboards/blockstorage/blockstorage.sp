locals {
  blockstorage_common_tags = {
    service = "OCI/BlockStorage"
  }
}

category "blockstorage_block_volume" {
  title = "Blockstorage Block Volume"
  color = local.storage_color
  href  = "/oci_insights.dashboard.blockstorage_block_volume_detail?input.block_volume_id={{.properties.'ID' | @uri}}"
  icon  = "hard_drive"
}

category "blockstorage_block_volume_backup" {
  title = "Blockstorage Block Volume Backup"
  color = local.storage_color
  icon  = "settings_backup_restore"
}

category "blockstorage_boot_volume" {
  title = "Blockstorage Boot Volume"
  color = local.storage_color
  href  = "/oci_insights.dashboard.blockstorage_boot_volume_detail?input.boot_volume_id={{.properties.'ID' | @uri}}"
  icon  = "hard_drive"
}

category "blockstorage_boot_volume_backup" {
  title = "Blockstorage Boot Volume Backup"
  color = local.storage_color
  icon  = "settings_backup_restore"
}

category "blockstorage_boot_volume_replica" {
  title = "Blockstorage Boot Volume Replica"
  color = local.storage_color
  icon  = "text:replica"
}
