locals {
  objectstorage_common_tags = {
    service = "OCI/ObjectStorage"
  }
}

category "objectstorage_bucket" {
  title = "Objectstorage Bucket"
  href  = "/oci_insights.dashboard.objectstorage_bucket_detail?input.bucket_id={{.properties.'ID' | @uri}}"
  icon  = "cleaning_bucket"
  color = local.storage_color
}