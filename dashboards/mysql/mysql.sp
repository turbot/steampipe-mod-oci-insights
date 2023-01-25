locals {
  mysql_common_tags = {
    service = "OCI/MySQL"
  }
}

category "mysql_backup" {
  title = "MySQL Backup"
  color = local.database_color
  icon  = "settings_backup_restore"
}

category "mysql_channel" {
  title = "MySQL Channel"
  color = local.database_color
  icon  = "text:channel"
}

category "mysql_configuration" {
  title = "MySQL Configuration"
  color = local.database_color
  icon  = "text:config"
}

category "mysql_db_system" {
  title = "MySQL DB System"
  color = local.database_color
  href  = "/oci_insights.dashboard.mysql_db_system_detail?input.db_system_id={{.properties.'ID' | @uri}}"
  icon  = "database"
}