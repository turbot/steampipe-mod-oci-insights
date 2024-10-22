node "autoscaling_auto_scaling_configuration" {
  category = category.autoscaling_auto_scaling_configuration

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_autoscaling_auto_scaling_configuration
    where
      id = any($1);
  EOQ

  param "autoscaling_auto_scaling_configuration_ids" {}
}