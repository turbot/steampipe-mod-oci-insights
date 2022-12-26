locals {
  blockstorage_common_tags = {
    service = "OCI/BlockStorage"
  }
}

category "blockstorage_block_volume" {
  title = "Blockstorage Block Volume"
  icon  = "hard_drive"
  color = local.storage_color
}

category "blockstorage_boot_volume" {
  title = "Blockstorage Boot Volume"
  icon  = "hard_drive"
  color = local.storage_color
}