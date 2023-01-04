node "kms_key" {
  category = category.kms_key

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', name,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_kms_key
    where
      id = any($1);
  EOQ

  param "kms_key_ids" {}
}

node "kms_key_version" {
  category = category.kms_key_version

  sql = <<-EOQ
    select
      v.id as id,
      v.title as title,
      jsonb_build_object(
        'ID', v.id,
        'Lifecycle State', v.lifecycle_state,
        'Time Created', v.time_created,
        'Compartment ID', v.compartment_id,
        'Region', v.region
      ) as properties
    from
      oci_kms_key_version as v,
      oci_kms_key as k
    where
      v.key_id = k.id
      and v.management_endpoint = k.management_endpoint
      and v.region = k.region
      and v.id = any($1);
  EOQ

  param "kms_key_version_ids" {}
}

node "kms_vault" {
  category = category.kms_vault

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_kms_vault
    where
      id = any($1);
  EOQ

  param "kms_vault_ids" {}
}

node "kms_vault_secret" {
  category = category.kms_vault_secret

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', name,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_vault_secret
    where
      id = any($1);
  EOQ

  param "kms_vault_secret_ids" {}
}