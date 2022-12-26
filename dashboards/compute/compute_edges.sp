edge "compute_instance_to_blockstorage_block_volume" {
  title = "block volume"

  sql = <<-EOQ
    select
      instance_id as from_id,
      volume_id as to_id
    from
      oci_core_volume_attachment
    where
      instance_id = any($1);
  EOQ

  param "compute_instance_ids" {}
}

edge "compute_instance_to_blockstorage_boot_volume" {
  title = "boot volume"

  sql = <<-EOQ
    select
      instance_id as from_id,
      boot_volume_id as to_id
    from
      oci_core_boot_volume_attachment
    where
      instance_id = any($1);
  EOQ

  param "compute_instance_ids" {}
}

edge "compute_instance_to_compute_image" {
  title = "image"

  sql = <<-EOQ
    select
      id as from_id,
      source_details ->> 'imageId' as to_id
    from
      oci_core_instance
    where
      id = any($1);
  EOQ

  param "compute_instance_ids" {}
}

edge "compute_instance_to_vcn_load_balancer" {
  title = "load balancer"

  sql = <<-EOQ
    with subnet_list as (
      select
        jsonb_array_elements_text(subnet_ids) as subnet_id,
        id
      from
        oci_core_load_balancer
    )
    select
      a.instance_id as from_id,
      s.id as to_id
    from
      oci_core_vnic_attachment as a,
      subnet_list as s
    where
      s.subnet_id = a.subnet_id
      and a.instance_id = any($1);
  EOQ

  param "compute_instance_ids" {}
}

edge "compute_instance_to_vcn_network_load_balancer" {
  title = "network load balancer"

  sql = <<-EOQ
    select
      a.instance_id as from_id,
      n.id as to_id
    from
      oci_core_vnic_attachment as a,
      oci_core_network_load_balancer as n
    where
      n.subnet_id = a.subnet_id
      and a.instance_id = any($1);
  EOQ

  param "compute_instance_ids" {}
}

edge "compute_instance_to_vcn_network_security_group" {
  title = "nsg"

  sql = <<-EOQ
    with network_security_groups as (
      select
        jsonb_array_elements_text(nsg_ids) as n_id,
        instance_id
      from
        oci_core_vnic_attachment
    )
    select
      instance_id as from_id,
      n_id as to_id
    from
      oci_core_network_security_group,
      network_security_groups
    where
      id = n_id
      and instance_id = any($1)
  EOQ

  param "compute_instance_ids" {}
}

edge "compute_instance_to_vcn_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      i.id as from_id,
      s.id as to_id
    from
      oci_core_instance as i,
      oci_core_subnet as s,
      oci_core_vnic_attachment as v
    where
      v.instance_id = i.id
      and v.subnet_id = s.id
      and i.id = any($1);
  EOQ

  param "compute_instance_ids" {}
}

edge "compute_instance_to_vcn_vnic" {
  title = "vnic"

  sql = <<-EOQ
    select
      instance_id as from_id,
      vnic_id as to_id
    from
      oci_core_vnic_attachment
    where
      lifecycle_state = 'ATTACHED'
      and instance_id = any($1);
  EOQ

  param "compute_instance_ids" {}
}