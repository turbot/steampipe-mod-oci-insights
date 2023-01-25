edge "database_autonomous_database_to_kms_key" {
  title = "key"

  sql = <<-EOQ
    select
      vault_id as from_id,
      kms_key_id as to_id
    from
      oci_database_autonomous_database
    where
      id = any($1);
  EOQ

  param "database_autonomous_database_ids" {}
}

edge "database_autonomous_database_to_kms_vault" {
  title = "vault"

  sql = <<-EOQ
    select
      id as from_id,
      vault_id as to_id
    from
      oci_database_autonomous_database
    where
      id = any($1);
  EOQ

  param "database_autonomous_database_ids" {}
}