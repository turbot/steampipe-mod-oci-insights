locals {
  filestorage_common_tags = {
    service = "OCI/FileStorage"
  }
}

category "filestorage_file_system" {
  title = "File Storage File System"
  color = local.storage_color
  href  = "/oci_insights.dashboard.filestorage_filesystem_detail?input.filesystem_id={{.properties.'ID' | @uri}}"
  icon  = "home_storage"
}

category "filestorage_mount_target" {
  title = "File Storage Mount Target"
  color = local.storage_color
  icon  = "cloud_sync"
}

category "filestorage_snapshot" {
  title = "File Storage Snapshot"
  color = local.storage_color
  icon  = "add_a_photo"
}
