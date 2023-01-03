node "nosql_table" {
  category = category.nosql_table

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_nosql_table
    where
      id = any($1);
  EOQ

  param "nosql_table_ids" {}
}