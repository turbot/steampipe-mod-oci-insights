node "database_autonomous_database" {
  category = category.filestorage_file_system

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'DB Name', db_name,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_database_autonomous_database
    where
      id = any($1);
  EOQ

  param "database_autonomous_database_ids" {}
}