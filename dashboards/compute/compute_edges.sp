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
    select
      coalesce(
        vnic_id,
        instance_id
      ) as from_id,
      nid as to_id
    from
      oci_core_vnic_attachment,
      jsonb_array_elements_text(nsg_ids) as nid
    where
      instance_id = any($1);
  EOQ

  param "compute_instance_ids" {}
}

edge "compute_instance_to_vcn_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      coalesce(
        nid,
        vnic_id
      ) as from_id,
      subnet_id as to_id
    from
      oci_core_vnic_attachment,
      jsonb_array_elements_text(nsg_ids) as nid
    where
      instance_id = any($1);
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