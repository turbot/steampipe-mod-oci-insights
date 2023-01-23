edge "objectstorage_bucket_to_kms_key" {
  title = "key"

  sql = <<-EOQ
    select
      id as from_id,
      kms_key_id as to_id
    from
      oci_objectstorage_bucket
    where
      id = any($1);
  EOQ

  param "objectstorage_bucket_ids" {}
}
