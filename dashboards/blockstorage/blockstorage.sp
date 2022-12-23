locals {
  blockstorage_common_tags = {
    service = "OCI/BlockStorage"
  }
}

category "blockstorage_block_volume" {
  title = "Blockstorage Block Volume"
  icon  = "hard-drive"
  color = local.storage_color
}