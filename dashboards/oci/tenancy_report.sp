dashboard "tenancy_report" {

  title         = "OCI Tenancy Report"
  documentation = file("./dashboards/oci/docs/tenancy_report.md")

  tags = merge(local.oci_common_tags, {
    type     = "Report"
    category = "Tenancy"
  })

  container {

    card {
      query = query.tenancy_count
      width = 3
    }

  }

  table {
    query = query.tenancy_table
  }

}

query "tenancy_count" {
  sql = <<-EOQ
    select
      count(*) as "Tenancies"
    from
      oci_identity_tenancy;
  EOQ
}

query "tenancy_table" {
  sql = <<-EOQ
    select
      name as "Name",
      retention_period_days as "Retention Period Days",
      home_region_key as "Home Region Key"
    from
      oci_identity_tenancy;
  EOQ
}
