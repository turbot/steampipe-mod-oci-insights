node "identity_api_key" {
  category = category.identity_api_key

  sql = <<-EOQ
    select
      key_id as id,
      title as title,
      jsonb_build_object(
        'ID', key_id,
        'Fingerprint', fingerprint,
        'Lifecycle State', lifecycle_state,
        'Time Created',time_created,
        'tenant_id', tenant_id
      ) as properties
    from
      oci_identity_api_key
    where
      key_id = any($1);
  EOQ

  param "identity_api_key_ids" {}
}

node "identity_auth_token" {
  category = category.identity_auth_token

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Description', description,
        'Lifecycle State', lifecycle_state,
        'Time Created',time_created,
        'tenant_id', tenant_id
      ) as properties
    from
      oci_identity_auth_token
    where
      id = any($1);
  EOQ

  param "identity_auth_token_ids" {}
}

node "identity_customer_secret_key" {
  category = category.identity_customer_secret_key

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Lifecycle State', lifecycle_state,
        'Time Created',time_created,
        'tenant_id', tenant_id
      ) as properties
    from
      oci_identity_customer_secret_key
    where
      id = any($1);
  EOQ

  param "identity_customer_secret_key_ids" {}
}

node "identity_availability_domain" {
  category = category.availability_domain

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', name,
        'Region', region
      ) as properties
    from
      oci_identity_availability_domain
    where
      id = any($1);
  EOQ

  param "availability_domain_ids" {}
}

node "identity_group" {
  category = category.identity_group

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Create Time', time_created,
        'Display Name', name,
        'Lifecycle State', lifecycle_state
      ) as properties
    from
      oci_identity_group
    where
      id = any($1);
  EOQ

  param "identity_group_ids" {}
}

node "identity_user" {
  category = category.identity_user

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'MFA Enabled', is_mfa_activated,
        'Lifecycle State', lifecycle_state,
        'Create Time', time_created,
        'Display Name', name,
        'User Type', user_type
      ) as properties
    from
      oci_identity_user
    where
      id = any($1);
  EOQ

  param "identity_user_ids" {}
}

node "regional_identity_availability_domain" {
  category = category.availability_domain

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', name,
        'Region', region
      ) as properties
    from
      oci_identity_availability_domain
    where
      id = any($1);
  EOQ

  param "availability_domain_ids" {}
}
