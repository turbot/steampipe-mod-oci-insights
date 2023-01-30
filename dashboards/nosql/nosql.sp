locals {
  nosql_common_tags = {
    service = "OCI/NoSQL"
  }
}

category "nosql_table" {
  title = "NoSQL Table"
  color = local.database_color
  href  = "/oci_insights.dashboard.nosql_table_detail?input.table_id={{.properties.'ID' | @uri}}"
  icon  = "table"
}