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
      and s.id = any($1);
  EOQ

  param "vcn_subnet_ids" {}
}