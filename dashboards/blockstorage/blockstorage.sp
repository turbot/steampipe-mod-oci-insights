locals {
  blockstorage_common_tags = {
    service = "OCI/BlockStorage"
  }
}

category "blockstorage_block_volume" {
  title = "Blockstorage Block Volume"
  href  = "/oci_insights.dashboard.blockstorage_block_volume_detail?input.block_volume_id={{.properties.'ID' | @uri}}"
  icon  = "hard_drive"
  color = local.storage_color
}

category "blockstorage_block_volume_backup" {
  title = "Blockstorage Block Volume Backup"
  icon  = "settings_backup_restore"
  color = local.storage_color
}

category "blockstorage_boot_volume" {
  title = "Blockstorage Boot Volume"
  href  = "/oci_insights.dashboard.blockstorage_boot_volume_detail?input.boot_volume_id={{.properties.'ID' | @uri}}"
  icon  = "hard_drive"
  color = local.storage_color
}
