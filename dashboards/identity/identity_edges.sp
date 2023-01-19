edge "identity_availability_domain_to_vcn_regional_subnet" {
  title = "subnet"

  sql = <<-EOQ
    with ad as (
      select
        a.id as ad_id,
        a.region as ad_region
      from
        oci_identity_availability_domain as a,
        oci_region as r
      where
        a.region = r.name
    )
    select
      ad_id as from_id,
      id as to_id
    from
      oci_core_subnet,
      ad
    where
      availability_domain is null
      and ad_region = region
      and ad_id = any($1);
  EOQ

  param "availability_domain_ids" {}
}

edge "identity_availability_domain_to_vcn_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      a.id as from_id,
      s.id as to_id
    from
      oci_core_subnet as s,
      oci_identity_availability_domain as a
    where
      s.availability_domain = a.name
      and a.id = any($1);
  EOQ

  param "availability_domain_ids" {}
}

edge "identity_group_to_identity_user" {
  title = "has member"

  sql = <<-EOQ
    select
      gid ->> 'groupId' as from_id,
      id as to_id
    from
      oci_identity_user,
      jsonb_array_elements(user_groups) as gid
    where
      gid ->> 'groupId' = any($1);
  EOQ

  param "identity_group_ids" {}
}