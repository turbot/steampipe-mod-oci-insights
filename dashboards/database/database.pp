locals {
  database_common_tags = {
    service = "OCI/Database"
  }
}

category "database_autonomous_database" {
  title = "Autonomous Database"
  color = local.database_color
  href  = "/oci_insights.dashboard.database_autonomous_database_detail?input.db_id={{.properties.'ID' | @uri}}"
  icon  = "database"
}
