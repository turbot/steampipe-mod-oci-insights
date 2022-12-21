locals {
  filestorage_common_tags = {
    service = "OCI/FileStorage"
  }
}

category "file_storage_mount_target" {
  title = "File Storage Mount Target"
  icon  = "text:Target"
  color = local.storage_color
}