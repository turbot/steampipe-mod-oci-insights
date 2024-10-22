node "mysql_backup" {
  category = category.mysql_backup

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
      oci_mysql_backup
    where
      id = any($1);
  EOQ

  param "mysql_backup_ids" {}
}

node "mysql_channel" {
  category = category.mysql_channel

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
      oci_mysql_channel
    where
      id = any($1);
  EOQ

  param "mysql_channel_ids" {}
}

node "mysql_configuration" {
  category = category.mysql_configuration

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id
      ) as properties
    from
      oci_mysql_configuration
    where
      id = any($1);
  EOQ

  param "mysql_configuration_ids" {}
}

node "mysql_db_system" {
  category = category.mysql_db_system

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
      oci_mysql_db_system
    where
      id = any($1);
  EOQ

  param "mysql_db_system_ids" {}
}
