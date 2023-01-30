edge "database_autonomous_database_to_kms_key" {
  title = "key"

  sql = <<-EOQ
    select
      id as from_id,
      kms_key_id as to_id
    from
      oci_database_autonomous_database
    where
      id = any($1);
  EOQ

  param "database_autonomous_database_ids" {}
}

edge "database_autonomous_database_to_vcn_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      coalesce(
        nid,
        subnet_id
      )  as from_id,
      subnet_id as to_id
    from
      oci_database_autonomous_database,
      jsonb_array_elements_text(nsg_ids) as nid
    where
      id = any($1);
  EOQ

  param "database_autonomous_database_ids" {}
}

edge "database_autonomous_database_to_vcn_network_security_group" {
  title = "nsg"

  sql = <<-EOQ
    select
      id as from_id,
      nid as to_id
    from
      oci_database_autonomous_database,
      jsonb_array_elements_text(nsg_ids) as nid
    where
      id = any($1);
  EOQ

  param "database_autonomous_database_ids" {}
}
