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
