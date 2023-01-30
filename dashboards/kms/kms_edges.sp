edge "kms_key_to_kms_vault" {
  title = "key vault"

  sql = <<-EOQ
    select
      id as from_id,
      vault_id as to_id
    from
      oci_kms_key
    where
      id = any($1);
  EOQ

  param "kms_key_ids" {}
}

edge "kms_key_to_kms_vault_secret" {
  title = "secret"

  sql = <<-EOQ
    select
      key_id as from_id,
      id as to_id
    from
      oci_vault_secret
    where
      key_id = any($1);
  EOQ

  param "kms_key_ids" {}
}

edge "kms_key_version_to_kms_key" {
  title = "key"

  sql = <<-EOQ
    select
      v.id as from_id,
      k.id as to_id
    from
      oci_kms_key_version as v
      left join oci_kms_key as k on k.id = v.key_id
    where
      v.management_endpoint = k.management_endpoint
      and v.region = k.region
      and v.id = any($1);
  EOQ

  param "kms_key_version_ids" {}
}

edge "kms_vault_to_kms_key" {
  title = "key"

  sql = <<-EOQ
    select
      vault_id as from_id,
      id as to_id
    from
      oci_kms_key
    where
      vault_id = any($1);
  EOQ

  param "kms_vault_ids" {}
}