node "compute_image" {
  category = category.compute_image

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Lifecycle State', lifecycle_state,
        'Launch Mode', launch_mode,
        'Compartment ID', compartment_id,
        'Operating System', operating_system,
        'Region', region
      ) as properties
    from
      oci_core_image
    where
      id = any($1);
  EOQ

  param "compute_image_ids" {}
}

node "compute_instance" {
  category = category.compute_instance

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Lifecycle State', lifecycle_state,
        'Launch Mode', launch_mode,
        'Compartment ID', compartment_id,
        'Capacity Reservation ID', capacity_reservation_id,
        'Region', region
      ) as properties
    from
      oci_core_instance
    where
      id = any($1);
  EOQ

  param "compute_instance_ids" {}
}