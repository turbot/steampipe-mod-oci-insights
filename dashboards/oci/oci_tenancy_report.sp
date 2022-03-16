dashboard "oci_tenancy_report" {

  title         = "OCI Tenancy Report"
  documentation = file("./dashboards/oci/docs/oci_tenancy_report.md")

  tags = merge(local.oci_common_tags, {
    type     = "Report"
    category = "Tenancy"
  })

  container {

    card {
      query = query.oci_tenancy_count
      width = 2
    }

  }

  table {
    query = query.oci_tenancy_table
  }

}

query "oci_tenancy_count" {
  sql = <<-EOQ
    select
      count(*) as "Tenancies"
    from
      oci_identity_tenancy;
  EOQ
}

query "oci_tenancy_table" {
  sql = <<-EOQ
    select
      name as "Name",
      retention_period_days as "Retention Period Days",
      home_region_key as "Home Region Key"
    from
      oci_identity_tenancy;
  EOQ
}
