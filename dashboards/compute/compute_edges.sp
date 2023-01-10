edge "compute_instance_to_blockstorage_block_volume" {
  title = "mounts"

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
  title = "mounts"

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

edge "compute_instance_to_vcn_network_security_group" {
  title = "nsg"

  sql = <<-EOQ
    with vnic_attachment_nsg as (
      select
        jsonb_array_elements_text(nsg_ids) as n_id,
        instance_id,
        vnic_id
      from
        oci_core_vnic_attachment
    )
    select
      coalesce(
        va.vnic_id,
        va.instance_id
      ) as from_id,
      n_id as to_id
    from
      oci_core_network_security_group as n,
      vnic_attachment_nsg as va
    where
      n.id = va.n_id
      and va.instance_id = any($1)
  EOQ

  param "compute_instance_ids" {}
}

edge "compute_instance_to_vcn_subnet" {
  title = "subnet"

  sql = <<-EOQ
    with vnic_attachment_nsg as (
      select
        jsonb_array_elements_text(nsg_ids) as n_id,
        instance_id,
        vnic_id,
        subnet_id
      from
        oci_core_vnic_attachment
    )
    select
      coalesce(
        v.n_id,
        v.vnic_id
      ) as from_id,
      s.id as to_id
    from
      oci_core_instance as i,
      oci_core_subnet as s,
      vnic_attachment_nsg as v
    where
      v.instance_id = i.id
      and v.subnet_id = s.id
      and i.id = any($1);
  EOQ

  param "compute_instance_ids" {}
}

edge "compute_instance_to_vcn_primary_vnic" {
  title = "primary vnic"

  sql = <<-EOQ
    select
      instance_id as from_id,
      vnic_id as to_id
    from
      oci_core_vnic_attachment
    where
      is_primary = true
      and lifecycle_state = 'ATTACHED'
      and instance_id = any($1);
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
      is_primary = false
      and lifecycle_state = 'ATTACHED'
      and instance_id = any($1);
  EOQ

  param "compute_instance_ids" {}
}