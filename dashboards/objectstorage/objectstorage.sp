locals {
  objectstorage_common_tags = {
    service = "OCI/ObjectStorage"
  }
}

category "objectstorage_bucket" {
  title = "Object Storage Bucket"
  color = local.storage_color
  href  = "/oci_insights.dashboard.objectstorage_bucket_detail?input.bucket_id={{.properties.'ID' | @uri}}"
  icon  = "cleaning_bucket"
}

category "objectstorage_object" {
  title = "Object Storage Oject"
  color = local.storage_color
  icon  = "data_object"
}
