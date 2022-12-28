locals {
  mysql_common_tags = {
    service = "OCI/MySQL"
  }
}

category "mysql_backup" {
  title = "MYSQL Backup"
  color = local.database_color
  icon  = "settings_backup_restore"
}

category "mysql_channel" {
  title = "MYSQL Channel"
  color = local.database_color
  icon  = "text:channel"
}

category "mysql_configuration" {
  title = "MYSQL Configuration"
  color = local.database_color
  icon  = "text:config"
}

category "mysql_db_system" {
  title = "MYSQL DB System"
  href  = "/oci_insights.dashboard.mysql_db_system_detail?input.db_system_id={{.properties.'ID' | @uri}}"
  color = local.database_color
  icon  = "database"
}