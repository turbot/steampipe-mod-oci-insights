locals {
  filestorage_common_tags = {
    service = "OCI/FileStorage"
  }
}

category "file_storage_file_system" {
  title = "File Storage File System"
  icon  = "home_storage"
  color = local.storage_color
}

category "file_storage_mount_target" {
  title = "File Storage Mount Target"
  icon  = "cloud_sync"
  color = local.storage_color
}

category "file_storage_snapshot" {
  title = "File Storage Snapshot"
  icon  = "add_a_photo"
  color = local.storage_color
}