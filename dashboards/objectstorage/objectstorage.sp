locals {
  objectstorage_common_tags = {
    service = "OCI/ObjectStorage"
  }
}

category "objectstorage_bucket" {
  title = "Objectstorage Bucket"
  color = local.storage_color
  href  = "/oci_insights.dashboard.objectstorage_bucket_detail?input.bucket_id={{.properties.'ID' | @uri}}"
  icon  = "cleaning_bucket"
}

category "objectstorage_object" {
  title = "Objectstorage Oject"
  color = local.storage_color
  icon  = "cleaning_bucket"
}
