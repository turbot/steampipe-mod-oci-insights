edge "mysql_db_system_to_mysql_backup" {
  title = "backup"

  sql = <<-EOQ
    select
      db_system_id as from_id,
      id as to_id
    from
      oci_mysql_backup
    where
      db_system_id = any($1);
  EOQ

  param "mysql_db_system_ids" {}
}

edge "mysql_db_system_to_mysql_channel" {
  title = "channel"

  sql = <<-EOQ
    select
      target ->> 'dbSystemId' as from_id,
      id as to_id
    from
      oci_mysql_channel
    where
      target ->> 'dbSystemId' = any($1);
  EOQ

  param "mysql_db_system_ids" {}
}

edge "mysql_db_system_to_mysql_configuration" {
  title = "configuration"

  sql = <<-EOQ
    select
      id as from_id,
      configuration_id as to_id
    from
      oci_mysql_db_system
    where
      id = any($1);
  EOQ

  param "mysql_db_system_ids" {}
}

edge "mysql_db_system_to_vcn_vcn" {
  title = "vcn"

  sql = <<-EOQ
    select
      m.id as from_id,
      s.vcn_id as to_id
    from
      oci_mysql_db_system as m,
      oci_core_subnet as s
    where
      m.subnet_id = s.id
      and m.id = any($1);
  EOQ

  param "mysql_db_system_ids" {}
}