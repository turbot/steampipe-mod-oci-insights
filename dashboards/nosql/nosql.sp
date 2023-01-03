locals {
  nosql_common_tags = {
    service = "OCI/NoSQL"
  }
}

category "nosql_table" {
  title = "NOSQL Table"
  href  = "/oci_insights.dashboard.nosql_table_detail?input.table_id={{.properties.'ID' | @uri}}"
  color = local.database_color
  icon  = "table"
}