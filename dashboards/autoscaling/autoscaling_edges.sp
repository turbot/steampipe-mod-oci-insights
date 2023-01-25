edge "autoscaling_auto_scaling_configuration_to_compute_instance" {
  title = "launches"

  sql = <<-EOQ
    with intance_pool_id as (
      select
        tags ->> 'oci:compute:instancepool' as instance_pool_id,
        id
      from
        oci_core_instance
    )
    select
      a.id as from_id,
      i.id as to_id
    from
      oci_autoscaling_auto_scaling_configuration as a,
      intance_pool_id as i
    where
      instance_pool_id = resource ->> 'id'
      and i.id = any($1)
  EOQ

  param "compute_instance_ids" {}
}