locals {
  filestorage_common_tags = {
    service = "OCI/FileStorage"
  }
}

category "filestorage_file_system" {
  title = "File Storage File System"
  href  = "/oci_insights.dashboard.filestorage_file_system_detail?input.filesystem_id={{.properties.'ID' | @uri}}"
  icon  = "home_storage"
  color = local.storage_color
}

category "filestorage_mount_target" {
  title = "File Storage Mount Target"
  icon  = "cloud_sync"
  color = local.storage_color
}

category "filestorage_snapshot" {
  title = "File Storage Snapshot"
  icon  = "add_a_photo"
  color = local.storage_color
}
