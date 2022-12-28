node "objectstorage_bucket" {
  category = category.objectstorage_bucket

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', name,
        'Storage Tier', storage_tier,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_objectstorage_bucket
    where
      id = any($1);
  EOQ

  param "objectstorage_bucket_ids" {}
}