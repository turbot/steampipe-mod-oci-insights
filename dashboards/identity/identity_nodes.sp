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
