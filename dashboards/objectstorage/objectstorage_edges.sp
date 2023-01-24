edge "objectstorage_bucket_to_kms_key" {
  title = "key"

  sql = <<-EOQ
    select
      vault_id as from_id,
      kms_key_id as to_id
    from
      oci_objectstorage_bucket as b
      left join oci_kms_key as k on k.id = b.kms_key_id
    where
      vault_id is not null
      and b.id = any($1);
  EOQ

  param "objectstorage_bucket_ids" {}
}

edge "objectstorage_bucket_to_kms_vault" {
  title = "vault"

  sql = <<-EOQ
    select
      b.id as from_id,
      vault_id as to_id
    from
      oci_objectstorage_bucket as b
      left join oci_kms_key as k on k.id = b.kms_key_id
    where
      vault_id is not null
      and b.id = any($1);
  EOQ

  param "objectstorage_bucket_ids" {}
}

edge "objectstorage_bucket_to_identity_user" {
  title = "created by"

  sql = <<-EOQ
    select
      id as from_id,
      created_by as to_id
    from
      oci_objectstorage_bucket
    where
      id = any($1);
  EOQ

  param "objectstorage_bucket_ids" {}
}

edge "objectstorage_bucket_to_objectstorage_object" {
  title = "object"

  sql = <<-EOQ
   select
      b.id as from_id,
      o.name as to_id
    from
      oci_objectstorage_object as o
      left join oci_objectstorage_bucket as b on b.name = o.bucket_name
    where
      b.id = any($1);
  EOQ

  param "objectstorage_bucket_ids" {}
}
