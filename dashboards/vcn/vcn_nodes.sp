node "vcn_vcn" {
  category = category.vcn_vcn

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'Display Name', display_name,
        'Lifecycle State', lifecycle_state,
        'CIDR Block', cidr_block,
        'DNS Label', dns_label,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_vcn
    where
      id = any($1);
  EOQ

  param "vcn_vcn_ids" {}
}
